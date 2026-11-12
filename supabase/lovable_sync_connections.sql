-- ============================================================================
-- toıdym — Lovable Cloud Connection Sync (Admin <-> Venue <-> Buyer)
-- Run once in Lovable Cloud -> Database -> SQL editor.
-- Idempotent: safe to re-run without overwriting existing user data.
-- ============================================================================

create extension if not exists pgcrypto with schema extensions;
create schema if not exists app_rls;

-- 1. Helper: verify current caller is ADMIN (reads profiles, never raw_user_meta_data)
create or replace function app_rls.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select (
    upper(coalesce(auth.jwt() -> 'app_metadata' ->> 'role', '')) = 'ADMIN'
    or exists (
      select 1
      from public.profiles p
      where p.id = (select auth.uid())
        and upper(coalesce(p.role, '')) = 'ADMIN'
        and coalesce(p.is_blocked, false) = false
    )
  );
$$;

-- 1b. Shared helper: can current caller manage a given venue (ADMIN, owner, staff, or PARTNER)?
create or replace function app_rls.can_manage_venue(p_venue_id text)
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select (
    app_rls.is_admin()
    or exists (
      select 1
      from public.venues v
      where v.id::text = p_venue_id
        and (
          v.owner_id = (select auth.uid())
          or exists (
            select 1 from public.venue_staff vs
            where vs.venue_id::text = p_venue_id
              and vs.user_id = (select auth.uid())
              and upper(coalesce(vs.staff_role, '')) in ('PARTNER', 'ADMIN', 'MANAGER')
          )
          or exists (
            select 1 from public.profiles p
            where p.id = (select auth.uid())
              and (
                upper(coalesce(p.role, '')) = 'ADMIN'
                or (
                  upper(coalesce(p.role, '')) = 'PARTNER'
                  and (
                    coalesce(p.managed_venue_id::text, '') in ('', 'venue_1', p_venue_id)
                    or not exists (
                      select 1 from public.venues pv
                      where pv.id::text = p.managed_venue_id::text
                    )
                    or (
                      coalesce(to_jsonb(v) ->> 'applicant_email', '') <> ''
                      and lower(to_jsonb(v) ->> 'applicant_email') = lower(coalesce(p.email, ''))
                    )
                    or (
                      coalesce(to_jsonb(v) ->> 'owner', '') <> ''
                      and lower(to_jsonb(v) ->> 'owner') = lower(coalesce(p.email, ''))
                    )
                    or v.owner_id is null
                  )
                )
              )
          )
        )
    )
  );
$$;

-- 2. Add optional contact/photo columns on venues & defaults for legacy NOT NULL columns
alter table public.venues
  add column if not exists phone text not null default '',
  add column if not exists photo text not null default '';

alter table public.orders
  alter column id set default gen_random_uuid()::text,
  alter column buyer set default '',
  alter column buyer drop not null,
  alter column request_id set default ('REQ-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 16))),
  alter column request_id drop not null,
  alter column snapshot set default '{}'::jsonb,
  alter column snapshot drop not null,
  alter column code set default ('ORD-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8))),
  alter column code drop not null,
  alter column qr set default ('TOIDYM-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 16))),
  alter column qr drop not null,
  alter column created set default 0,
  alter column created drop not null,
  alter column ends set default 0,
  alter column ends drop not null;

alter table public.venues
  alter column id set default gen_random_uuid()::text,
  alter column owner set default '',
  alter column owner drop not null,
  alter column company set default '',
  alter column company drop not null,
  alter column review_note set default '',
  alter column review_note drop not null;

alter table public.boxes
  alter column id set default gen_random_uuid()::text,
  alter column details set default '{}'::jsonb,
  alter column details drop not null,
  alter column stock set default 0,
  alter column stock drop not null,
  alter column published set default true,
  alter column published drop not null,
  alter column paused set default false,
  alter column paused drop not null,
  alter column starts set default 0,
  alter column starts drop not null,
  alter column ends set default 0,
  alter column ends drop not null;

-- 2b. Unify status CHECK constraints (allow both Lovable lowercase and Flutter uppercase)
alter table public.orders drop constraint if exists orders_status_check;
alter table public.orders
  add constraint orders_status_check check (
    lower(status) in (
      'reserved', 'completed', 'cancelled_by_user', 'cancelled_by_venue',
      'no_show', 'paid', 'ready', 'collected', 'picked_up', 'cancelled', 'expired'
    )
  );

alter table public.venues drop constraint if exists venues_status_check;
alter table public.venues
  add constraint venues_status_check check (
    lower(status) in ('pending', 'approved', 'rejected', 'banned')
  );

alter table public.boxes drop constraint if exists boxes_status_check;
alter table public.boxes
  add constraint boxes_status_check check (
    lower(status) in ('active', 'sold_out', 'disabled', 'expired', 'archived')
  );

-- 3. RLS & Grants for partner_applications (Buyer/Guest -> Admin lead queue)
alter table public.partner_applications enable row level security;

grant usage on schema public to anon, authenticated;
grant select, insert on public.partner_applications to anon, authenticated;
grant update on public.partner_applications to authenticated;

drop policy if exists "toidym_pa_insert_any" on public.partner_applications;
create policy "toidym_pa_insert_any"
  on public.partner_applications
  for insert
  to anon, authenticated
  with check (lower(coalesce(status, 'pending')) = 'pending');

drop policy if exists "toidym_pa_admin_select" on public.partner_applications;
create policy "toidym_pa_admin_select"
  on public.partner_applications
  for select
  to authenticated
  using (app_rls.is_admin());

drop policy if exists "toidym_pa_admin_update" on public.partner_applications;
create policy "toidym_pa_admin_update"
  on public.partner_applications
  for update
  to authenticated
  using (app_rls.is_admin())
  with check (app_rls.is_admin());

-- 4. RPC: Admin creates PARTNER/CASHIER or Partner adds CASHIER to own venue
create or replace function public.create_partner_staff_admin(
  p_role text,
  p_venue_id text,
  p_name text,
  p_phone text,
  p_email text
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_caller_id uuid := (select auth.uid());
  v_caller_role text;
  v_caller_venue text;
  v_target_role text := upper(coalesce(nullif(trim(p_role), ''), 'CASHIER'));
  v_email text := lower(trim(coalesce(p_email, '')));
  v_name text := coalesce(nullif(trim(p_name), ''), 'Сотрудник');
  v_phone text := trim(coalesce(p_phone, ''));
  v_venue_id text := trim(coalesce(p_venue_id, ''));
  v_temp_password text;
  v_user_id uuid;
  v_is_first_login boolean := true;
begin
  if v_caller_id is null then
    raise exception 'Unauthorized' using errcode = '42501';
  end if;

  select upper(coalesce(role, 'USER')), managed_venue_id::text
    into v_caller_role, v_caller_venue
  from public.profiles
  where id = v_caller_id;

  if v_target_role not in ('PARTNER', 'CASHIER') then
    raise exception 'Invalid target role: %', v_target_role;
  end if;

  if v_target_role = 'PARTNER' and v_caller_role <> 'ADMIN' then
    raise exception 'Only ADMIN can create PARTNER' using errcode = '42501';
  end if;

  if v_target_role = 'CASHIER' and v_caller_role <> 'ADMIN' then
    if not (
      v_caller_role = 'PARTNER'
      and (
        v_caller_venue = v_venue_id
        or exists (
          select 1 from public.venues v
          where v.id = v_venue_id and v.owner_id = v_caller_id
        )
      )
    ) then
      raise exception 'Forbidden for venue %', v_venue_id using errcode = '42501';
    end if;
  end if;

  if v_email = '' or v_venue_id = '' then
    raise exception 'email and venue_id are required';
  end if;

  v_temp_password := 'Toidym#' || upper(substr(md5(gen_random_uuid()::text), 1, 6)) || '9';

  select id into v_user_id
  from auth.users
  where lower(email) = v_email
  limit 1;

  if v_user_id is null then
    v_user_id := gen_random_uuid();
    insert into auth.users (
      instance_id,
      id,
      aud,
      role,
      email,
      encrypted_password,
      email_confirmed_at,
      raw_app_meta_data,
      raw_user_meta_data,
      created_at,
      updated_at,
      confirmation_token,
      recovery_token,
      email_change_token_new,
      email_change
    ) values (
      '00000000-0000-0000-0000-000000000000',
      v_user_id,
      'authenticated',
      'authenticated',
      v_email,
      extensions.crypt(v_temp_password, extensions.gen_salt('bf')),
      timezone('utc', now()),
      jsonb_build_object(
        'provider', 'email',
        'providers', jsonb_build_array('email'),
        'role', v_target_role,
        'managed_venue_id', v_venue_id,
        'is_first_login', true
      ),
      jsonb_build_object(
        'name', v_name,
        'phone', v_phone
      ),
      timezone('utc', now()),
      timezone('utc', now()),
      '',
      '',
      '',
      ''
    );

    insert into auth.identities (
      id,
      user_id,
      provider_id,
      identity_data,
      provider,
      last_sign_in_at,
      created_at,
      updated_at
    ) values (
      gen_random_uuid(),
      v_user_id,
      v_user_id::text,
      jsonb_build_object('sub', v_user_id::text, 'email', v_email),
      'email',
      timezone('utc', now()),
      timezone('utc', now()),
      timezone('utc', now())
    )
    on conflict do nothing;
  else
    update auth.users
    set encrypted_password = extensions.crypt(v_temp_password, extensions.gen_salt('bf')),
        email_confirmed_at = coalesce(email_confirmed_at, timezone('utc', now())),
        raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb) || jsonb_build_object(
          'role', v_target_role,
          'managed_venue_id', v_venue_id,
          'is_first_login', true
        ),
        updated_at = timezone('utc', now())
    where id = v_user_id;
  end if;

  insert into public.profiles (
    id, email, name, phone, role, language, is_verified, is_first_login, must_change_password, managed_venue_id
  ) values (
    v_user_id, v_email, v_name, v_phone, v_target_role, 'ru', true, v_is_first_login, v_is_first_login, v_venue_id
  )
  on conflict (id) do update set
    email = excluded.email,
    name = excluded.name,
    phone = coalesce(nullif(excluded.phone, ''), public.profiles.phone),
    role = excluded.role,
    is_verified = true,
    is_first_login = true,
    must_change_password = true,
    managed_venue_id = excluded.managed_venue_id;

  insert into public.venue_staff (venue_id, user_id, staff_role)
  values (v_venue_id, v_user_id, v_target_role)
  on conflict (venue_id, user_id) do update set staff_role = excluded.staff_role;

  if v_target_role = 'PARTNER' then
    update public.venues
    set owner_id = v_user_id,
        owner = v_email,
        updated_at = timezone('utc', now())
    where id = v_venue_id;
  end if;

  insert into public.audit_logs (actor_id, actor_email, action, target_type, target_id, details)
  values (
    v_caller_id,
    coalesce((select email from public.profiles where id = v_caller_id), 'admin@toidym.kz'),
    'CREATE_' || v_target_role,
    'user',
    v_user_id::text,
    format('Создан %s (%s) для заведения %s', v_target_role, v_email, v_venue_id)
  );

  return jsonb_build_object(
    'ok', true,
    'user_id', v_user_id::text,
    'email', v_email,
    'role', v_target_role,
    'venue_id', v_venue_id,
    'temp_password', v_temp_password
  );
end;
$$;

grant execute on function public.create_partner_staff_admin(text, text, text, text, text) to authenticated;

-- 5. RPC: Admin approves partner_application OR pending venue & provisions PARTNER login
create or replace function public.approve_partner_lead_admin(
  p_venue_or_app_id text,
  p_partner_email text default null
)
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_caller_id uuid := (select auth.uid());
  v_app record;
  v_venue record;
  v_venue_id text;
  v_email text;
  v_category text := 'bakery';
  v_staff_result jsonb;
begin
  if not app_rls.is_admin() then
    raise exception 'Forbidden: ADMIN role required' using errcode = '42501';
  end if;

  select * into v_app
  from public.partner_applications
  where id = p_venue_or_app_id
  limit 1;

  if found then
    v_venue_id := 'venue-' || replace(p_venue_or_app_id, 'pa_', '');
    v_email := lower(coalesce(nullif(trim(p_partner_email), ''), v_app.contact_name, 'partner.' || v_venue_id || '@toidym.kz'));
    if coalesce(v_app.notes, '') like '%category=%' then
      v_category := split_part(split_part(v_app.notes, 'category=', 2), ' ', 1);
    end if;

    insert into public.venues (
      id, owner, name, company, address, district, lat, lng,
      status, review_note, is_blocked, category, rating, reviews_count,
      is_halal, halal_cert_status, open_minute_of_day, close_minute_of_day,
      rejection_fields, applicant_email, phone
    ) values (
      v_venue_id,
      v_email,
      coalesce(v_app.venue_name, 'Партнёр'),
      coalesce(v_app.company, v_app.venue_name, 'Партнёр'),
      coalesce(v_app.address, ''),
      coalesce(v_app.district, 0),
      51.1282,
      71.4304,
      'approved',
      'Одобрено из заявки ' || v_app.id,
      false,
      coalesce(nullif(v_category, ''), 'bakery'),
      5.0,
      0,
      false,
      'none',
      480,
      1200,
      '{}'::text[],
      v_email,
      coalesce(v_app.phone, '')
    )
    on conflict (id) do update set
      status = 'approved',
      is_blocked = false,
      applicant_email = excluded.applicant_email,
      phone = coalesce(nullif(excluded.phone, ''), public.venues.phone),
      updated_at = timezone('utc', now());

    update public.partner_applications
    set status = 'approved'
    where id = v_app.id;
  else
    v_venue_id := p_venue_or_app_id;
    select * into v_venue from public.venues where id = v_venue_id limit 1;
    if not found then
      raise exception 'Venue or application % not found', p_venue_or_app_id;
    end if;
    v_email := lower(coalesce(nullif(trim(p_partner_email), ''), nullif(v_venue.applicant_email, ''), 'partner.' || v_venue_id || '@toidym.kz'));

    update public.venues
    set status = 'approved',
        is_blocked = false,
        applicant_email = v_email,
        updated_at = timezone('utc', now())
    where id = v_venue_id;
  end if;

  select * into v_venue from public.venues where id = v_venue_id;

  v_staff_result := public.create_partner_staff_admin(
    'PARTNER',
    v_venue_id,
    'Партнёр ' || coalesce(v_venue.name, ''),
    coalesce(v_venue.phone, ''),
    v_email
  );

  return jsonb_build_object(
    'ok', true,
    'venue', to_jsonb(v_venue),
    'partner_email', v_email,
    'temp_password', v_staff_result ->> 'temp_password',
    'user_id', v_staff_result ->> 'user_id'
  );
end;
$$;

grant execute on function public.approve_partner_lead_admin(text, text) to authenticated;

-- 6. Seed starter live boxes linked to the existing demo venues (if not already present)
insert into public.boxes (
  id, venue_id, details, stock, published, paused, starts, ends,
  title, description, type, category, original_price, discount_price,
  discount_percent, quantity, quantity_left, pickup_start, pickup_end,
  is_halal, is_vegetarian, is_resale, allergens, status, photos, repeat_weekdays
)
select
  s.id,
  s.venue_id,
  jsonb_build_object('title', s.title, 'description', s.description),
  s.quantity_left,
  true,
  false,
  (extract(epoch from s.pickup_start) * 1000)::bigint,
  (extract(epoch from s.pickup_end) * 1000)::bigint,
  s.title,
  s.description,
  s.type,
  s.category,
  s.original_price,
  s.discount_price,
  s.discount_percent,
  s.quantity,
  s.quantity_left,
  s.pickup_start,
  s.pickup_end,
  s.is_halal,
  s.is_vegetarian,
  false,
  s.allergens,
  'ACTIVE',
  s.photos,
  '{1,2,3,4,5}'::integer[]
from (
  values
    (
      'demo-box-bakery-1',
      'demo-bakery',
      'Сюрприз-бокс «Таңғы нан»',
      'Свежие бауырсаки, круассаны и слойки вечерней выпечки.',
      'surprise',
      'bakery',
      3000,
      1190,
      60,
      8,
      5,
      timezone('utc', now()) + interval '1 hour',
      timezone('utc', now()) + interval '4 hours',
      true,
      true,
      array['gluten', 'dairy']::text[],
      array[]::text[]
    ),
    (
      'demo-box-coffee-1',
      'demo-coffeeboom',
      'Кофе + десерт бокс',
      'Сэндвич и свежая выпечка к закрытию кофейни.',
      'set',
      'coffee',
      2800,
      1290,
      54,
      6,
      4,
      timezone('utc', now()) + interval '1 hour',
      timezone('utc', now()) + interval '4 hours',
      false,
      true,
      array['gluten', 'dairy']::text[],
      array[]::text[]
    ),
    (
      'demo-box-deli-1',
      'demo-qazaqdeli',
      'Ыстық тағамдар жинағы',
      'Плов, самса и салат дня в одном боксе.',
      'surprise',
      'hot_food',
      3600,
      1490,
      59,
      6,
      4,
      timezone('utc', now()) + interval '1 hour',
      timezone('utc', now()) + interval '4 hours',
      true,
      false,
      array['gluten']::text[],
      array[]::text[]
    )
) as s (
  id, venue_id, title, description, type, category, original_price, discount_price,
  discount_percent, quantity, quantity_left, pickup_start, pickup_end,
  is_halal, is_vegetarian, allergens, photos
)
where exists (select 1 from public.venues v where v.id = s.venue_id)
on conflict (id) do nothing;

-- 7. RPC + RLS: Partner / Admin Sprint Box Publishing (matches lowercase 'approved' venues & Lovable schema)
create or replace function public.publish_sprint_box(
  p_venue_id text,
  p_title text,
  p_description text,
  p_type text,
  p_category text,
  p_original_price integer,
  p_discount_price integer,
  p_quantity integer,
  p_is_halal boolean default false,
  p_is_vegetarian boolean default false,
  p_allergens text[] default '{}',
  p_photos text[] default '{}',
  p_repeat_weekdays integer[] default '{}'
)
returns public.boxes
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid := (select auth.uid());
  v_venue public.venues;
  v_is_allowed boolean;
  v_local_now timestamp;
  v_service_date date;
  v_open_min integer;
  v_close_min integer;
  v_sprint_start_min integer;
  v_sprint_end_min integer;
  v_start_local timestamp;
  v_end_local timestamp;
  v_pickup_start timestamptz;
  v_pickup_end timestamptz;
  v_discount_percent integer;
  v_box public.boxes;
begin
  if v_uid is null then
    raise exception 'Authentication required';
  end if;

  select * into v_venue from public.venues where id = p_venue_id limit 1;
  if not found then
    raise exception 'Venue not found';
  end if;

  v_is_allowed := app_rls.can_manage_venue(p_venue_id);
  if not v_is_allowed then
    raise exception 'Permission denied: only venue PARTNER or ADMIN can publish boxes' using errcode = '42501';
  end if;

  if upper(coalesce(v_venue.status, '')) <> 'APPROVED' or coalesce(v_venue.is_blocked, false) then
    raise exception 'Venue must be APPROVED to publish boxes';
  end if;

  v_open_min := coalesce(v_venue.open_minute_of_day, 480);
  v_close_min := coalesce(v_venue.close_minute_of_day, 1200);
  v_local_now := timezone('Asia/Almaty', now());
  v_service_date := v_local_now::date;
  v_sprint_start_min := greatest(v_open_min, v_close_min - 60);
  v_sprint_end_min := least(v_close_min, greatest(v_sprint_start_min + 15, v_close_min - 45));

  v_start_local := v_service_date + make_interval(mins => v_sprint_start_min);
  v_end_local := v_service_date + make_interval(mins => v_sprint_end_min);
  if v_end_local <= v_local_now then
    v_start_local := (v_service_date + 1) + make_interval(mins => v_sprint_start_min);
    v_end_local := (v_service_date + 1) + make_interval(mins => v_sprint_end_min);
  end if;

  v_pickup_start := v_start_local at time zone 'Asia/Almaty';
  v_pickup_end := v_end_local at time zone 'Asia/Almaty';

  v_discount_percent := case
    when coalesce(p_original_price, 0) > 0 then
      greatest(0, least(99, round(((p_original_price - p_discount_price)::numeric / p_original_price::numeric) * 100)::integer))
    else 0
  end;

  insert into public.boxes (
    venue_id, title, description, type, category,
    original_price, discount_price, discount_percent,
    quantity, quantity_left, stock,
    pickup_start, pickup_end, starts, ends,
    details, published, paused,
    is_halal, is_vegetarian, is_resale,
    allergens, status, photos, repeat_weekdays
  ) values (
    p_venue_id,
    coalesce(nullif(trim(p_title), ''), 'Сюрприз-бокс'),
    coalesce(p_description, ''),
    coalesce(nullif(trim(p_type), ''), 'surprise'),
    coalesce(nullif(trim(p_category), ''), 'bakery'),
    p_original_price,
    p_discount_price,
    v_discount_percent,
    greatest(1, coalesce(p_quantity, 1)),
    greatest(1, coalesce(p_quantity, 1)),
    greatest(1, coalesce(p_quantity, 1)),
    v_pickup_start,
    v_pickup_end,
    (extract(epoch from v_pickup_start) * 1000)::bigint,
    (extract(epoch from v_pickup_end) * 1000)::bigint,
    jsonb_build_object('title', p_title, 'description', coalesce(p_description, '')),
    true,
    false,
    coalesce(p_is_halal, false),
    coalesce(p_is_vegetarian, false),
    false,
    coalesce(p_allergens, '{}'),
    'ACTIVE',
    coalesce(p_photos, '{}'),
    coalesce(p_repeat_weekdays, '{}')
  )
  returning * into v_box;

  return v_box;
end;
$$;

grant execute on function public.publish_sprint_box(
  text, text, text, text, text, integer, integer, integer, boolean, boolean, text[], text[], integer[]
) to authenticated;

-- Allow owning PARTNER / ADMIN to insert & update boxes and box_templates directly via PostgREST too
drop policy if exists "toidym_boxes_partner_insert" on public.boxes;
create policy "toidym_boxes_partner_insert"
  on public.boxes
  for insert
  to authenticated
  with check (app_rls.can_manage_venue(boxes.venue_id::text));

drop policy if exists "toidym_boxes_partner_update" on public.boxes;
create policy "toidym_boxes_partner_update"
  on public.boxes
  for update
  to authenticated
  using (app_rls.can_manage_venue(boxes.venue_id::text))
  with check (app_rls.can_manage_venue(boxes.venue_id::text));

alter table public.box_templates enable row level security;
drop policy if exists "toidym_box_templates_partner_all" on public.box_templates;
create policy "toidym_box_templates_partner_all"
  on public.box_templates
  for all
  to authenticated
  using (
    app_rls.can_manage_venue(box_templates.venue_id::text)
    or exists (
      select 1 from public.profiles p
      where p.id = (select auth.uid())
        and upper(coalesce(p.role, '')) = 'CASHIER'
        and coalesce(p.managed_venue_id::text, '') = box_templates.venue_id::text
    )
  )
  with check (app_rls.can_manage_venue(box_templates.venue_id::text));

-- Sync missing managed_venue_id on partner profiles that already own an approved venue
update public.profiles p
   set managed_venue_id = v.id,
       role = case when upper(coalesce(p.role, '')) = 'USER' then 'PARTNER' else p.role end
  from public.venues v
 where v.owner_id = p.id
   and (p.managed_venue_id is null or trim(p.managed_venue_id::text) = '' or p.managed_venue_id::text = 'venue_1');

-- ============================================================================
-- 8) HALAL CERTIFICATE PHOTO UPLOAD & ADMIN MODERATION
-- ============================================================================
alter table public.venues add column if not exists halal_cert_photo text;

-- Link orphan venues where applicant_email / owner matches an existing profile email
update public.venues v
   set owner_id = p.id
  from public.profiles p
 where v.owner_id is null
   and (
     (coalesce(v.applicant_email, '') <> '' and lower(v.applicant_email) = lower(p.email))
     or (coalesce(v.owner, '') <> '' and lower(v.owner) = lower(p.email))
   );

update public.profiles p
   set managed_venue_id = v.id,
       role = case when upper(coalesce(p.role, '')) = 'USER' then 'PARTNER' else p.role end
  from public.venues v
 where v.owner_id = p.id
   and (p.managed_venue_id is null or trim(p.managed_venue_id::text) = '' or p.managed_venue_id::text = 'venue_1');

-- Allow Venue Partner & Admin to update their own venue settings via RLS too
grant update on public.venues to authenticated;
drop policy if exists "toidym_venues_partner_admin_update" on public.venues;
create policy "toidym_venues_partner_admin_update"
  on public.venues
  for update
  to authenticated
  using (app_rls.can_manage_venue(venues.id::text))
  with check (app_rls.can_manage_venue(venues.id::text));

create or replace function public.submit_halal_cert(
  p_venue_id text,
  p_photo text
)
returns public.venues
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_is_allowed boolean;
  v_clean_photo text;
  v_venue public.venues;
begin
  v_uid := (select auth.uid());
  if v_uid is null then
    raise exception 'Authentication required';
  end if;

  v_clean_photo := nullif(trim(coalesce(p_photo, '')), '');
  if v_clean_photo is null then
    raise exception 'Halal certificate photo is required';
  end if;

  select * into v_venue
  from public.venues
  where id::text = p_venue_id;

  if not found then
    raise exception 'Venue not found';
  end if;

  v_is_allowed := app_rls.can_manage_venue(p_venue_id);
  if not v_is_allowed then
    raise exception 'Permission denied: only venue PARTNER or ADMIN can submit Halal certificate' using errcode = '42501';
  end if;

  update public.venues
     set halal_cert_photo = v_clean_photo,
         halal_cert_status = 'pending',
         owner_id = coalesce(
           owner_id,
           case when app_rls.is_admin() then null else v_uid end
         ),
         updated_at = timezone('utc', now())
   where id::text = p_venue_id
  returning * into v_venue;

  return v_venue;
end;
$$;

create or replace function public.moderate_halal_cert_admin(
  p_venue_id text,
  p_status text
)
returns public.venues
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_status text;
  v_venue public.venues;
begin
  if not app_rls.is_admin() then
    raise exception 'Permission denied: ADMIN role required' using errcode = '42501';
  end if;

  v_status := lower(trim(coalesce(p_status, '')));
  if v_status not in ('verified', 'rejected', 'pending', 'none') then
    raise exception 'Invalid halal status: %', p_status;
  end if;

  update public.venues
     set halal_cert_status = v_status,
         is_halal = (v_status = 'verified'),
         updated_at = timezone('utc', now())
   where id::text = p_venue_id
  returning * into v_venue;

  if not found then
    raise exception 'Venue not found';
  end if;

  return v_venue;
end;
$$;

revoke all on function public.submit_halal_cert(text, text) from public, anon;
grant execute on function public.submit_halal_cert(text, text) to authenticated, service_role;

revoke all on function public.moderate_halal_cert_admin(text, text) from public, anon;
grant execute on function public.moderate_halal_cert_admin(text, text) to authenticated, service_role;

-- ============================================================================
-- 9) ORDERS BOOKING & PICKUP ALIGNMENT (fixes orders_qr_key duplicate default)
-- ============================================================================
update public.orders
   set qr = 'TOIDYM-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 16))
 where coalesce(trim(qr), '') = '' or length(qr) > 32;

update public.orders
   set code = 'ORD-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8))
 where coalesce(trim(code), '') = '' or length(code) > 32;

update public.orders
   set request_id = 'REQ-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 16))
 where coalesce(trim(request_id), '') = '' or length(request_id) > 32;

drop function if exists public.create_trust_reservation(uuid, integer, boolean);
drop function if exists public.create_trust_reservation(text, integer, boolean);

create or replace function public.create_trust_reservation(
  p_box_id text,
  p_quantity integer default 1,
  p_is_charity boolean default false
)
returns public.orders
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_profile public.profiles;
  v_box public.boxes;
  v_new_left integer;
  v_pin text;
  v_num text;
  v_qr text;
  v_code text;
  v_request_id text;
  v_order public.orders;
begin
  v_uid := (select auth.uid());
  if v_uid is null then
    raise exception 'Authentication required';
  end if;

  if p_quantity < 1 or p_quantity > 5 then
    raise exception 'Quantity must be between 1 and 5';
  end if;

  select * into v_profile from public.profiles where id = v_uid for update;
  if not found then
    raise exception 'User profile not found';
  end if;

  if coalesce(v_profile.strikes_count, 0) >= 3
     or (v_profile.banned_until is not null and v_profile.banned_until > timezone('utc', now())) then
    raise exception 'ACCOUNT_BANNED: Аккаунт заблокирован из-за 3 нарушений (No-Show)';
  end if;

  select * into v_box from public.boxes where id::text = p_box_id for update;
  if not found then
    raise exception 'Box not found';
  end if;

  if upper(coalesce(v_box.status, '')) <> 'ACTIVE' or coalesce(v_box.quantity_left, 0) < p_quantity then
    raise exception 'OUT_OF_STOCK: Бокс недоступен или закончился';
  end if;

  if v_box.pickup_end is not null and v_box.pickup_end <= timezone('utc', now()) then
    raise exception 'WINDOW_EXPIRED: Время выдачи бокса уже истекло';
  end if;

  v_new_left := v_box.quantity_left - p_quantity;
  update public.boxes
     set quantity_left = v_new_left,
         stock = v_new_left,
         status = case when v_new_left = 0 then 'SOLD_OUT' else 'ACTIVE' end
   where id::text = p_box_id;

  v_pin := lpad(((floor(random() * 9000) + 1000)::integer)::text, 4, '0');
  v_num := '#' || lpad(((floor(random() * 900000) + 100000)::integer)::text, 6, '0');
  v_qr := 'TOIDYM-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 16));
  v_code := 'ORD-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 8));
  v_request_id := 'REQ-' || upper(substr(replace(gen_random_uuid()::text, '-', ''), 1, 16));

  insert into public.orders (
    order_number, user_id, box_id, venue_id, quantity,
    total_price, original_total_price, status,
    qr_code, qr, pin_code, code, payment_method, is_charity_box,
    buyer, request_id, created, ends
  ) values (
    v_num,
    v_uid,
    v_box.id,
    v_box.venue_id,
    p_quantity,
    case when p_is_charity then 0 else v_box.discount_price * p_quantity end,
    v_box.original_price * p_quantity,
    'RESERVED',
    v_qr,
    v_qr,
    v_pin,
    v_code,
    'on_site',
    coalesce(p_is_charity, false),
    left(coalesce(nullif(v_profile.email, ''), v_uid::text), 32),
    v_request_id,
    (extract(epoch from timezone('utc', now())) * 1000)::bigint,
    (extract(epoch from coalesce(v_box.pickup_end, timezone('utc', now()) + interval '1 hour')) * 1000)::bigint
  )
  returning * into v_order;

  return v_order;
end;
$$;

drop function if exists public.complete_order_pickup(uuid, text);
drop function if exists public.complete_order_pickup(text, text);

create or replace function public.complete_order_pickup(
  p_order_id text default null,
  p_qr_or_pin text default null
)
returns public.orders
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_token text;
  v_order public.orders;
  v_is_staff boolean;
  v_saved_kzt integer;
begin
  v_uid := (select auth.uid());
  if v_uid is null then
    raise exception 'Authentication required';
  end if;

  v_token := trim(coalesce(p_qr_or_pin, ''));

  if p_order_id is not null and trim(p_order_id) <> '' then
    select * into v_order
    from public.orders
    where id::text = trim(p_order_id)
      and upper(coalesce(status, '')) in ('RESERVED', 'PAID', 'READY')
    for update;
  elsif v_token <> '' then
    select * into v_order
    from public.orders
    where (
      qr_code = v_token
      or qr = v_token
      or pin_code = v_token
      or code = v_token
    )
      and upper(coalesce(status, '')) in ('RESERVED', 'PAID', 'READY')
    order by created_at desc
    limit 1
    for update;
  else
    raise exception 'Order ID, QR, or PIN is required';
  end if;

  if not found then
    raise exception 'Reserved order not found';
  end if;

  v_is_staff := (
    app_rls.can_manage_venue(v_order.venue_id::text)
    or exists (
      select 1 from public.profiles p
      where p.id = v_uid
        and upper(coalesce(p.role, '')) = 'CASHIER'
        and coalesce(p.managed_venue_id::text, '') in ('', 'venue_1', v_order.venue_id::text)
    )
  );
  if not v_is_staff then
    raise exception 'Only venue staff or ADMIN can complete pickup' using errcode = '42501';
  end if;

  update public.orders
     set status = 'COMPLETED',
         picked_up_at = timezone('utc', now())
   where id = v_order.id
  returning * into v_order;

  v_saved_kzt := greatest(0, coalesce(v_order.original_total_price, 0) - coalesce(v_order.total_price, 0));
  update public.profiles
     set boxes_saved = coalesce(boxes_saved, 0) + coalesce(v_order.quantity, 1),
         co2_saved_kg = coalesce(co2_saved_kg, 0) + (coalesce(v_order.quantity, 1) * 2.5),
         money_saved_kzt = coalesce(money_saved_kzt, 0) + v_saved_kzt
   where id = v_order.user_id;

  return v_order;
end;
$$;

revoke all on function public.create_trust_reservation(text, integer, boolean) from public, anon;
grant execute on function public.create_trust_reservation(text, integer, boolean) to authenticated, service_role;

revoke all on function public.complete_order_pickup(text, text) from public, anon;
grant execute on function public.complete_order_pickup(text, text) to authenticated, service_role;

drop function if exists public.cancel_order_atomic(uuid, text);
drop function if exists public.cancel_order_atomic(text, text);

create or replace function public.cancel_order_atomic(
  p_order_id text,
  p_reason text default null
)
returns public.orders
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_order public.orders;
  v_box public.boxes;
  v_is_buyer boolean;
  v_is_venue boolean;
  v_new_status text;
begin
  v_uid := (select auth.uid());
  if v_uid is null then
    raise exception 'Authentication required';
  end if;

  select * into v_order from public.orders where id::text = trim(p_order_id) for update;
  if not found then
    raise exception 'Order not found';
  end if;

  if upper(coalesce(v_order.status, '')) not in ('RESERVED', 'PAID', 'READY') then
    raise exception 'Only active RESERVED orders can be cancelled';
  end if;

  v_is_buyer := (v_order.user_id = v_uid);
  v_is_venue := app_rls.can_manage_venue(v_order.venue_id::text);

  if not v_is_buyer and not v_is_venue then
    raise exception 'Permission denied to cancel order' using errcode = '42501';
  end if;

  select * into v_box from public.boxes where id::text = v_order.box_id::text for update;
  if v_is_buyer and not v_is_venue and v_box.pickup_start is not null then
    if v_box.pickup_start - interval '1 hour' <= timezone('utc', now()) then
      raise exception 'CANCELLATION_WINDOW_CLOSED: Бесплатная отмена возможна не позднее чем за 1 час до выдачи';
    end if;
  end if;

  v_new_status := case
    when v_is_venue and not v_is_buyer then 'CANCELLED_BY_VENUE'
    else 'CANCELLED_BY_USER'
  end;

  update public.orders
     set status = v_new_status,
         cancellation_reason = coalesce(nullif(trim(p_reason), ''), 'Отменено')
   where id = v_order.id
  returning * into v_order;

  if found and v_box.id is not null then
    update public.boxes
       set quantity_left = coalesce(quantity_left, 0) + coalesce(v_order.quantity, 1),
           stock = coalesce(stock, 0) + coalesce(v_order.quantity, 1),
           status = case
             when upper(coalesce(status, '')) = 'SOLD_OUT' then 'ACTIVE'
             else status
           end
     where id = v_box.id;
  end if;

  return v_order;
end;
$$;

drop function if exists public.submit_order_complaint(uuid, text, text[]);
drop function if exists public.submit_order_complaint(text, text, text[]);

create or replace function public.submit_order_complaint(
  p_order_id text,
  p_note text,
  p_photo_paths text[] default '{}'
)
returns public.orders
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_order public.orders;
begin
  v_uid := (select auth.uid());
  if v_uid is null then
    raise exception 'Authentication required';
  end if;

  update public.orders
     set complaint_submitted = true,
         complaint_status = 'open',
         complaint_note = trim(coalesce(p_note, '')),
         complaint_photo_paths = coalesce(p_photo_paths, '{}'),
         complaint_submitted_at = timezone('utc', now())
   where id::text = trim(p_order_id)
     and user_id = v_uid
  returning * into v_order;

  if not found then
    raise exception 'Order not found or not owned by user';
  end if;

  return v_order;
end;
$$;

drop function if exists public.submit_review_atomic(uuid, integer, text[], text);
drop function if exists public.submit_review_atomic(text, integer, text[], text);

create or replace function public.submit_review_atomic(
  p_order_id text,
  p_rating integer,
  p_tags text[] default '{}',
  p_comment text default ''
)
returns public.reviews
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_order public.orders;
  v_author text;
  v_review public.reviews;
begin
  v_uid := (select auth.uid());
  if v_uid is null then
    raise exception 'Authentication required';
  end if;

  select * into v_order from public.orders where id::text = trim(p_order_id);
  if not found or v_order.user_id <> v_uid or upper(coalesce(v_order.status, '')) not in ('COMPLETED', 'PICKED_UP') then
    raise exception 'Review allowed only on your COMPLETED orders';
  end if;

  select name into v_author from public.profiles where id = v_uid;

  insert into public.reviews (
    order_id, user_id, venue_id, rating, tags, comment, author_name
  ) values (
    v_order.id, v_uid, v_order.venue_id, p_rating,
    coalesce(p_tags, '{}'), coalesce(p_comment, ''), coalesce(v_author, 'Покупатель')
  )
  returning * into v_review;

  update public.venues v
     set rating = sub.avg_rating,
         reviews_count = sub.total_count
    from (
      select
        round(avg(r.rating)::numeric, 2) as avg_rating,
        count(*)::integer as total_count
      from public.reviews r
      where r.venue_id::text = v_order.venue_id::text
    ) sub
   where v.id::text = v_order.venue_id::text;

  return v_review;
end;
$$;

revoke all on function public.cancel_order_atomic(text, text) from public, anon;
grant execute on function public.cancel_order_atomic(text, text) to authenticated, service_role;

revoke all on function public.submit_order_complaint(text, text, text[]) from public, anon;
grant execute on function public.submit_order_complaint(text, text, text[]) to authenticated, service_role;

revoke all on function public.submit_review_atomic(text, integer, text[], text) from public, anon;
grant execute on function public.submit_review_atomic(text, integer, text[], text) to authenticated, service_role;

notify pgrst, 'reload schema';

-- ============================================================================
-- 10) PERFORMANCE OPTIMIZATION & DATABASE INDEXES
-- ============================================================================
create index if not exists idx_boxes_venue_status on public.boxes (venue_id, status);
create index if not exists idx_boxes_resale_pickup on public.boxes (is_resale desc, pickup_end asc);
create index if not exists idx_boxes_status_pickup on public.boxes (status, pickup_end);
create index if not exists idx_orders_user_status on public.orders (user_id, status);
create index if not exists idx_orders_venue_status on public.orders (venue_id, status);
create index if not exists idx_orders_qr on public.orders (qr);
create index if not exists idx_orders_qr_code on public.orders (qr_code);
create index if not exists idx_orders_pin_code on public.orders (pin_code);
create index if not exists idx_orders_code on public.orders (code);
create index if not exists idx_venues_owner_id on public.venues (owner_id);
create index if not exists idx_venues_status on public.venues (status);
create index if not exists idx_venues_district on public.venues (district);
create index if not exists idx_profiles_role on public.profiles (role);
create index if not exists idx_profiles_managed_venue on public.profiles (managed_venue_id);
create index if not exists idx_reviews_venue_id on public.reviews (venue_id);
create index if not exists idx_reviews_order_id on public.reviews (order_id);
create index if not exists idx_box_templates_venue_id on public.box_templates (venue_id);
create index if not exists idx_venue_staff_venue_user on public.venue_staff (venue_id, user_id);

-- ============================================================================
-- OPTIONAL: Grant ADMIN role to your account email (replace and run if needed):
-- update public.profiles
--    set role = 'ADMIN', is_verified = true
--  where lower(email) = lower('your-admin@example.com');
-- ============================================================================
