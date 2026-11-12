-- ============================================================================
-- toıdym — 002_rls_and_rpcs.sql
-- Auth Triggers, Least-Privilege Grants, RLS Policies, and Atomic RPCs
-- Implements: 15-min Sprint Window, 1-min Auto-Resale Worker, Offline Trust
-- Reservation, 3-Strikes & Anti-Escalation Guards
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. AUTH SYNC & ANTI-ESCALATION TRIGGERS
-- ----------------------------------------------------------------------------

-- Create profile row automatically whenever auth.users receives a new user.
-- IMPORTANT: Role is read ONLY from raw_app_meta_data (server-controlled),
-- NEVER from client-writable raw_user_meta_data.
create or replace function private.handle_new_auth_user()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_role text;
  v_venue_id uuid;
begin
  v_role := upper(coalesce(new.raw_app_meta_data ->> 'role', 'USER'));
  if v_role not in ('USER', 'PARTNER', 'CASHIER', 'ADMIN') then
    v_role := 'USER';
  end if;

  begin
    v_venue_id := (new.raw_app_meta_data ->> 'managed_venue_id')::uuid;
  exception when others then
    v_venue_id := null;
  end;

  insert into public.profiles (
    id,
    email,
    phone,
    name,
    role,
    language,
    is_verified,
    is_first_login,
    managed_venue_id
  ) values (
    new.id,
    coalesce(new.email, ''),
    coalesce(new.phone, new.raw_user_meta_data ->> 'phone', ''),
    coalesce(nullif(new.raw_user_meta_data ->> 'name', ''), 'Покупатель'),
    v_role,
    case when (new.raw_user_meta_data ->> 'language') = 'kk' then 'kk' else 'ru' end,
    (new.email_confirmed_at is not null),
    coalesce((new.raw_app_meta_data ->> 'is_first_login')::boolean, false),
    v_venue_id
  )
  on conflict (id) do update set
    email = coalesce(nullif(public.profiles.email, ''), excluded.email),
    phone = coalesce(nullif(public.profiles.phone, ''), excluded.phone),
    is_verified = true;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function private.handle_new_auth_user();

-- Keep auth.users.raw_app_meta_data synced whenever role or managed_venue_id changes.
create or replace function private.sync_profile_to_auth_app_metadata()
returns trigger
language plpgsql
security definer
set search_path = ''
as $$
begin
  if (tg_op = 'INSERT')
     or (old.role is distinct from new.role)
     or (old.managed_venue_id is distinct from new.managed_venue_id) then
    update auth.users
    set raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb)
      || jsonb_build_object(
           'role', new.role,
           'managed_venue_id', new.managed_venue_id
         )
    where id = new.id;
  end if;
  return new;
end;
$$;

drop trigger if exists sync_profile_app_metadata on public.profiles;
create trigger sync_profile_app_metadata
  after insert or update of role, managed_venue_id on public.profiles
  for each row execute function private.sync_profile_to_auth_app_metadata();

-- Prevent authenticated non-admin users from mutating privileged columns on profiles.
create or replace function private.protect_profile_columns()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  v_caller_role text;
begin
  -- Table owner / service_role / internal SECURITY DEFINER RPCs bypass client guard
  if current_user in ('postgres', 'service_role', 'supabase_admin') then
    return new;
  end if;

  v_caller_role := coalesce(auth.jwt() -> 'app_metadata' ->> 'role', 'USER');
  if v_caller_role <> 'ADMIN' then
    new.role := old.role;
    new.strikes_count := old.strikes_count;
    new.banned_until := old.banned_until;
    new.managed_venue_id := old.managed_venue_id;
    new.boxes_saved := old.boxes_saved;
    new.co2_saved_kg := old.co2_saved_kg;
    new.money_saved_kzt := old.money_saved_kzt;
    new.is_verified := old.is_verified;
  end if;

  return new;
end;
$$;

drop trigger if exists protect_profiles_before_update on public.profiles;
create trigger protect_profiles_before_update
  before update on public.profiles
  for each row execute function private.protect_profile_columns();

-- Prevent non-admin users from self-approving venues or tampering ratings.
create or replace function private.protect_venue_columns()
returns trigger
language plpgsql
set search_path = ''
as $$
declare
  v_caller_role text;
begin
  if current_user in ('postgres', 'service_role', 'supabase_admin') then
    return new;
  end if;

  v_caller_role := coalesce(auth.jwt() -> 'app_metadata' ->> 'role', 'USER');
  if v_caller_role <> 'ADMIN' then
    new.status := old.status;
    new.owner_id := old.owner_id;
    new.halal_cert_status := old.halal_cert_status;
    new.rating := old.rating;
    new.reviews_count := old.reviews_count;
    new.rejection_fields := old.rejection_fields;
    new.rejection_comment := old.rejection_comment;
  end if;

  return new;
end;
$$;

drop trigger if exists protect_venues_before_update on public.venues;
create trigger protect_venues_before_update
  before update on public.venues
  for each row execute function private.protect_venue_columns();

-- ----------------------------------------------------------------------------
-- 2. EXPLICIT SCHEMA & TABLE GRANTS (Mandatory for Post-Oct 2026 Supabase)
-- ----------------------------------------------------------------------------
revoke all on all tables in schema public from public, anon, authenticated;

grant usage on schema public to anon, authenticated, service_role;

-- Public read-only catalog for anon (approved venues, active boxes, reviews)
grant select on public.venues, public.boxes, public.reviews to anon;
-- Allow unauthenticated partner application lead submission (status forced to PENDING by RLS)
grant insert on public.venues to anon;

-- Authenticated baseline privileges (strictly filtered by RLS policies below)
grant select, update on public.profiles to authenticated;
grant select, insert, update on public.venues to authenticated;
grant select, insert, delete on public.venue_staff to authenticated;
grant select, insert, update, delete on public.box_templates to authenticated;
grant select, insert, update, delete on public.boxes to authenticated;
grant select, insert, update on public.orders to authenticated;
grant select, insert on public.reviews to authenticated;
grant select, update on public.notifications to authenticated;
grant select, insert on public.audit_logs to authenticated;

-- Full service_role access for Edge Functions
grant all privileges on all tables in schema public to service_role;

-- ----------------------------------------------------------------------------
-- 3. ENABLE ROW LEVEL SECURITY & POLICIES
-- ----------------------------------------------------------------------------
alter table public.profiles enable row level security;
alter table public.venues enable row level security;
alter table public.venue_staff enable row level security;
alter table public.box_templates enable row level security;
alter table public.boxes enable row level security;
alter table public.orders enable row level security;
alter table public.reviews enable row level security;
alter table public.notifications enable row level security;
alter table public.audit_logs enable row level security;

-- PROFILES
create policy "profiles_select_own_or_admin"
  on public.profiles for select
  to authenticated
  using (
    id = (select auth.uid())
    or (select (auth.jwt() -> 'app_metadata' ->> 'role')) = 'ADMIN'
  );

create policy "profiles_update_own_or_admin"
  on public.profiles for update
  to authenticated
  using (
    id = (select auth.uid())
    or (select (auth.jwt() -> 'app_metadata' ->> 'role')) = 'ADMIN'
  )
  with check (
    id = (select auth.uid())
    or (select (auth.jwt() -> 'app_metadata' ->> 'role')) = 'ADMIN'
  );

-- VENUES
create policy "venues_select_public_approved"
  on public.venues for select
  to anon
  using (status = 'APPROVED');

create policy "venues_select_authenticated"
  on public.venues for select
  to authenticated
  using (
    status = 'APPROVED'
    or owner_id = (select auth.uid())
    or (select (auth.jwt() -> 'app_metadata' ->> 'role')) = 'ADMIN'
    or exists (
      select 1 from public.venue_staff vs
      where vs.venue_id = venues.id
        and vs.user_id = (select auth.uid())
    )
  );

create policy "venues_insert_pending_lead"
  on public.venues for insert
  to anon, authenticated
  with check (
    status = 'PENDING'
    and (
      owner_id is null
      or owner_id = (select auth.uid())
      or (select (auth.jwt() -> 'app_metadata' ->> 'role')) = 'ADMIN'
    )
  );

create policy "venues_update_owner_or_admin"
  on public.venues for update
  to authenticated
  using (
    owner_id = (select auth.uid())
    or (select (auth.jwt() -> 'app_metadata' ->> 'role')) = 'ADMIN'
  )
  with check (
    owner_id = (select auth.uid())
    or (select (auth.jwt() -> 'app_metadata' ->> 'role')) = 'ADMIN'
  );

-- VENUE STAFF
create policy "venue_staff_select_member_or_admin"
  on public.venue_staff for select
  to authenticated
  using (
    user_id = (select auth.uid())
    or (select (auth.jwt() -> 'app_metadata' ->> 'role')) = 'ADMIN'
    or exists (
      select 1 from public.venues v
      where v.id = venue_staff.venue_id
        and v.owner_id = (select auth.uid())
    )
  );

create policy "venue_staff_manage_owner_or_admin"
  on public.venue_staff for all
  to authenticated
  using (
    (select (auth.jwt() -> 'app_metadata' ->> 'role')) = 'ADMIN'
    or exists (
      select 1 from public.venues v
      where v.id = venue_staff.venue_id
        and v.owner_id = (select auth.uid())
    )
  )
  with check (
    (select (auth.jwt() -> 'app_metadata' ->> 'role')) = 'ADMIN'
    or exists (
      select 1 from public.venues v
      where v.id = venue_staff.venue_id
        and v.owner_id = (select auth.uid())
    )
  );

-- BOX TEMPLATES
create policy "box_templates_venue_partner_or_admin"
  on public.box_templates for all
  to authenticated
  using (
    (select (auth.jwt() -> 'app_metadata' ->> 'role')) = 'ADMIN'
    or exists (
      select 1 from public.venue_staff vs
      where vs.venue_id = box_templates.venue_id
        and vs.user_id = (select auth.uid())
        and vs.staff_role = 'PARTNER'
    )
    or exists (
      select 1 from public.venues v
      where v.id = box_templates.venue_id
        and v.owner_id = (select auth.uid())
    )
  )
  with check (
    (select (auth.jwt() -> 'app_metadata' ->> 'role')) = 'ADMIN'
    or exists (
      select 1 from public.venue_staff vs
      where vs.venue_id = box_templates.venue_id
        and vs.user_id = (select auth.uid())
        and vs.staff_role = 'PARTNER'
    )
    or exists (
      select 1 from public.venues v
      where v.id = box_templates.venue_id
        and v.owner_id = (select auth.uid())
    )
  );

-- BOXES
create policy "boxes_select_anon_live"
  on public.boxes for select
  to anon
  using (
    status in ('ACTIVE', 'SOLD_OUT')
    and exists (
      select 1 from public.venues v
      where v.id = boxes.venue_id
        and v.status = 'APPROVED'
    )
  );

create policy "boxes_select_authenticated"
  on public.boxes for select
  to authenticated
  using (
    (
      status in ('ACTIVE', 'SOLD_OUT')
      and exists (
        select 1 from public.venues v
        where v.id = boxes.venue_id
          and v.status = 'APPROVED'
      )
    )
    or (select (auth.jwt() -> 'app_metadata' ->> 'role')) = 'ADMIN'
    or exists (
      select 1 from public.venue_staff vs
      where vs.venue_id = boxes.venue_id
        and vs.user_id = (select auth.uid())
    )
    or exists (
      select 1 from public.venues v
      where v.id = boxes.venue_id
        and v.owner_id = (select auth.uid())
    )
  );

create policy "boxes_write_partner_or_admin"
  on public.boxes for insert
  to authenticated
  with check (
    (select (auth.jwt() -> 'app_metadata' ->> 'role')) = 'ADMIN'
    or exists (
      select 1 from public.venue_staff vs
      where vs.venue_id = boxes.venue_id
        and vs.user_id = (select auth.uid())
        and vs.staff_role = 'PARTNER'
    )
    or exists (
      select 1 from public.venues v
      where v.id = boxes.venue_id
        and v.owner_id = (select auth.uid())
    )
  );

create policy "boxes_update_partner_or_admin"
  on public.boxes for update
  to authenticated
  using (
    (select (auth.jwt() -> 'app_metadata' ->> 'role')) = 'ADMIN'
    or exists (
      select 1 from public.venue_staff vs
      where vs.venue_id = boxes.venue_id
        and vs.user_id = (select auth.uid())
        and vs.staff_role = 'PARTNER'
    )
    or exists (
      select 1 from public.venues v
      where v.id = boxes.venue_id
        and v.owner_id = (select auth.uid())
    )
  )
  with check (
    (select (auth.jwt() -> 'app_metadata' ->> 'role')) = 'ADMIN'
    or exists (
      select 1 from public.venue_staff vs
      where vs.venue_id = boxes.venue_id
        and vs.user_id = (select auth.uid())
        and vs.staff_role = 'PARTNER'
    )
    or exists (
      select 1 from public.venues v
      where v.id = boxes.venue_id
        and v.owner_id = (select auth.uid())
    )
  );

-- ORDERS
create policy "orders_select_buyer_venue_or_admin"
  on public.orders for select
  to authenticated
  using (
    user_id = (select auth.uid())
    or (select (auth.jwt() -> 'app_metadata' ->> 'role')) = 'ADMIN'
    or exists (
      select 1 from public.venue_staff vs
      where vs.venue_id = orders.venue_id
        and vs.user_id = (select auth.uid())
    )
    or exists (
      select 1 from public.venues v
      where v.id = orders.venue_id
        and v.owner_id = (select auth.uid())
    )
  );

-- Orders are created and transitioned atomically via SECURITY DEFINER RPCs
-- (create_trust_reservation, complete_order_pickup, cancel_order_atomic);
-- Admin can update complaint resolution fields directly.
create policy "orders_update_admin"
  on public.orders for update
  to authenticated
  using ((select (auth.jwt() -> 'app_metadata' ->> 'role')) = 'ADMIN')
  with check ((select (auth.jwt() -> 'app_metadata' ->> 'role')) = 'ADMIN');

-- REVIEWS
create policy "reviews_select_public"
  on public.reviews for select
  to anon, authenticated
  using (true);

create policy "reviews_insert_own_completed_order"
  on public.reviews for insert
  to authenticated
  with check (
    user_id = (select auth.uid())
    and exists (
      select 1 from public.orders o
      where o.id = reviews.order_id
        and o.user_id = (select auth.uid())
        and o.status = 'COMPLETED'
    )
  );

-- NOTIFICATIONS
create policy "notifications_select_own"
  on public.notifications for select
  to authenticated
  using (user_id = (select auth.uid()));

create policy "notifications_update_read_own"
  on public.notifications for update
  to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

-- AUDIT LOGS (Immutable, Admin-only)
create policy "audit_logs_admin_select"
  on public.audit_logs for select
  to authenticated
  using ((select (auth.jwt() -> 'app_metadata' ->> 'role')) = 'ADMIN');

create policy "audit_logs_admin_insert"
  on public.audit_logs for insert
  to authenticated
  with check ((select (auth.jwt() -> 'app_metadata' ->> 'role')) = 'ADMIN');

-- ----------------------------------------------------------------------------
-- 4. BUSINESS LOGIC & ATOMIC RPC FUNCTIONS
-- ----------------------------------------------------------------------------

-- Computes strict 15-minute Sprint Pickup Window in Asia/Almaty (UTC+5):
-- [venue_close - 60 minutes .. venue_close - 45 minutes].
-- If today's sprint window is already in the past, schedules for tomorrow.
create or replace function private.compute_sprint_window(
  p_open_minute integer,
  p_close_minute integer,
  p_ref_utc timestamptz default timezone('utc', now())
)
returns table (pickup_start timestamptz, pickup_end timestamptz)
language plpgsql
immutable
set search_path = ''
as $$
declare
  v_local_now timestamp;
  v_service_date date;
  v_sprint_start_min integer;
  v_sprint_end_min integer;
  v_start_local timestamp;
  v_end_local timestamp;
begin
  v_local_now := p_ref_utc at time zone 'Asia/Almaty';
  v_service_date := v_local_now::date;
  v_sprint_start_min := greatest(p_open_minute, p_close_minute - 60);
  v_sprint_end_min := greatest(v_sprint_start_min + 15, p_close_minute - 45);
  v_sprint_end_min := least(p_close_minute, v_sprint_end_min);

  v_start_local := v_service_date + make_interval(mins => v_sprint_start_min);
  v_end_local := v_service_date + make_interval(mins => v_sprint_end_min);

  -- If the 15-minute sprint window already ended today, advance to tomorrow
  if v_end_local <= v_local_now then
    v_start_local := (v_service_date + 1) + make_interval(mins => v_sprint_start_min);
    v_end_local := (v_service_date + 1) + make_interval(mins => v_sprint_end_min);
  end if;

  pickup_start := v_start_local at time zone 'Asia/Almaty';
  pickup_end := v_end_local at time zone 'Asia/Almaty';
  return next;
end;
$$;

-- Partner publishes a box (automatically enforces 15-minute Sprint Window).
create or replace function public.publish_sprint_box(
  p_venue_id uuid,
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
  v_uid uuid;
  v_is_allowed boolean;
  v_venue public.venues;
  v_win record;
  v_box public.boxes;
begin
  v_uid := (select auth.uid());
  if v_uid is null then
    raise exception 'Authentication required';
  end if;

  select * into v_venue from public.venues where id = p_venue_id;
  if not found then
    raise exception 'Venue not found';
  end if;

  v_is_allowed := (
    coalesce(auth.jwt() -> 'app_metadata' ->> 'role', '') = 'ADMIN'
    or v_venue.owner_id = v_uid
    or exists (
      select 1 from public.venue_staff vs
      where vs.venue_id = p_venue_id
        and vs.user_id = v_uid
        and vs.staff_role = 'PARTNER'
    )
  );
  if not v_is_allowed then
    raise exception 'Permission denied: only venue PARTNER or ADMIN can publish boxes';
  end if;

  if v_venue.status <> 'APPROVED' then
    raise exception 'Venue must be APPROVED to publish boxes';
  end if;

  select * into v_win
  from private.compute_sprint_window(v_venue.open_minute_of_day, v_venue.close_minute_of_day);

  insert into public.boxes (
    venue_id, title, description, type, category,
    original_price, discount_price, quantity, quantity_left,
    pickup_start, pickup_end, is_halal, is_vegetarian,
    is_resale, allergens, status, photos, repeat_weekdays
  ) values (
    p_venue_id, p_title, coalesce(p_description, ''), p_type, p_category,
    p_original_price, p_discount_price, p_quantity, p_quantity,
    v_win.pickup_start, v_win.pickup_end, p_is_halal, p_is_vegetarian,
    false, coalesce(p_allergens, '{}'), 'ACTIVE', coalesce(p_photos, '{}'),
    coalesce(p_repeat_weekdays, '{}')
  )
  returning * into v_box;

  return v_box;
end;
$$;

-- Atomic Offline Trust Reservation (0% commission, race-safe stock lock).
create or replace function public.create_trust_reservation(
  p_box_id uuid,
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

  if v_profile.strikes_count >= 3
     or (v_profile.banned_until is not null and v_profile.banned_until > timezone('utc', now())) then
    raise exception 'ACCOUNT_BANNED: Аккаунт заблокирован из-за 3 нарушений (No-Show)';
  end if;

  select * into v_box from public.boxes where id = p_box_id for update;
  if not found then
    raise exception 'Box not found';
  end if;

  if v_box.status <> 'ACTIVE' or v_box.quantity_left < p_quantity then
    raise exception 'OUT_OF_STOCK: Бокс недоступен или закончился';
  end if;

  if v_box.pickup_end <= timezone('utc', now()) then
    raise exception 'WINDOW_EXPIRED: Время выдачи бокса уже истекло';
  end if;

  v_new_left := v_box.quantity_left - p_quantity;
  update public.boxes
  set quantity_left = v_new_left,
      status = case when v_new_left = 0 then 'SOLD_OUT' else 'ACTIVE' end
  where id = v_box.id;

  v_pin := lpad(((floor(random() * 9000) + 1000)::integer)::text, 4, '0');
  v_num := '#' || lpad(((floor(random() * 900000) + 100000)::integer)::text, 6, '0');
  v_qr := 'TOIDYM-' || replace(gen_random_uuid()::text, '-', '');

  insert into public.orders (
    order_number, user_id, box_id, venue_id, quantity,
    total_price, original_total_price, status,
    qr_code, pin_code, payment_method, is_charity_box
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
    v_pin,
    'on_site',
    p_is_charity
  )
  returning * into v_order;

  return v_order;
end;
$$;

-- Cashier/Partner confirms pickup by QR, PIN, or Order ID.
create or replace function public.complete_order_pickup(
  p_order_id uuid default null,
  p_qr_or_pin text default null
)
returns public.orders
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_uid uuid;
  v_order public.orders;
  v_is_staff boolean;
begin
  v_uid := (select auth.uid());
  if v_uid is null then
    raise exception 'Authentication required';
  end if;

  if p_order_id is not null then
    select * into v_order from public.orders where id = p_order_id for update;
  elsif nullif(trim(coalesce(p_qr_or_pin, '')), '') is not null then
    select o.* into v_order
    from public.orders o
    where (o.qr_code = trim(p_qr_or_pin) or o.pin_code = trim(p_qr_or_pin))
      and o.status = 'RESERVED'
    order by o.created_at desc
    limit 1
    for update;
  else
    raise exception 'Provide p_order_id or p_qr_or_pin';
  end if;

  if not found then
    raise exception 'RESERVED order not found';
  end if;

  if v_order.status <> 'RESERVED' then
    raise exception 'Order is already %', v_order.status;
  end if;

  v_is_staff := (
    coalesce(auth.jwt() -> 'app_metadata' ->> 'role', '') = 'ADMIN'
    or exists (
      select 1 from public.venue_staff vs
      where vs.venue_id = v_order.venue_id
        and vs.user_id = v_uid
    )
    or exists (
      select 1 from public.venues v
      where v.id = v_order.venue_id
        and v.owner_id = v_uid
    )
  );
  if not v_is_staff then
    raise exception 'Permission denied: caller is not authorized for this venue';
  end if;

  update public.orders
  set status = 'COMPLETED',
      picked_up_at = timezone('utc', now())
  where id = v_order.id
  returning * into v_order;

  update public.profiles
  set boxes_saved = boxes_saved + v_order.quantity,
      co2_saved_kg = co2_saved_kg + (v_order.quantity * 1.25),
      money_saved_kzt = money_saved_kzt + greatest(0, v_order.original_total_price - v_order.total_price)
  where id = v_order.user_id;

  return v_order;
end;
$$;

-- Atomic order cancellation (restores quantity to box stock).
create or replace function public.cancel_order_atomic(
  p_order_id uuid,
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

  select * into v_order from public.orders where id = p_order_id for update;
  if not found then
    raise exception 'Order not found';
  end if;

  if v_order.status <> 'RESERVED' then
    raise exception 'Only RESERVED orders can be cancelled';
  end if;

  v_is_buyer := (v_order.user_id = v_uid);
  v_is_venue := (
    coalesce(auth.jwt() -> 'app_metadata' ->> 'role', '') = 'ADMIN'
    or exists (
      select 1 from public.venue_staff vs
      where vs.venue_id = v_order.venue_id
        and vs.user_id = v_uid
        and vs.staff_role = 'PARTNER'
    )
    or exists (
      select 1 from public.venues v
      where v.id = v_order.venue_id
        and v.owner_id = v_uid
    )
  );

  if not v_is_buyer and not v_is_venue then
    raise exception 'Permission denied';
  end if;

  v_new_status := case when v_is_venue and not v_is_buyer
                       then 'CANCELLED_BY_VENUE'
                       else 'CANCELLED_BY_USER' end;

  select * into v_box from public.boxes where id = v_order.box_id for update;
  if found and v_box.pickup_end > timezone('utc', now()) then
    update public.boxes
    set quantity_left = least(quantity, quantity_left + v_order.quantity),
        status = 'ACTIVE'
    where id = v_box.id;
  end if;

  update public.orders
  set status = v_new_status,
      cancellation_reason = coalesce(nullif(trim(p_reason), ''), 'Отменено')
  where id = v_order.id
  returning * into v_order;

  return v_order;
end;
$$;

-- Buyer submits complaint on completed order.
create or replace function public.submit_order_complaint(
  p_order_id uuid,
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
      complaint_note = p_note,
      complaint_photo_paths = coalesce(p_photo_paths, '{}'),
      complaint_submitted_at = timezone('utc', now())
  where id = p_order_id
    and user_id = v_uid
  returning * into v_order;

  if not found then
    raise exception 'Order not found or not owned by user';
  end if;

  return v_order;
end;
$$;

-- Buyer submits review on completed order and atomically updates venue rating.
create or replace function public.submit_review_atomic(
  p_order_id uuid,
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

  select * into v_order from public.orders where id = p_order_id;
  if not found or v_order.user_id <> v_uid or v_order.status <> 'COMPLETED' then
    raise exception 'Review allowed only on your COMPLETED orders';
  end if;

  select name into v_author from public.profiles where id = v_uid;

  insert into public.reviews (
    order_id, user_id, venue_id, rating, tags, comment, author_name
  ) values (
    p_order_id, v_uid, v_order.venue_id, p_rating,
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
    where r.venue_id = v_order.venue_id
  ) sub
  where v.id = v_order.venue_id;

  return v_review;
end;
$$;

-- ----------------------------------------------------------------------------
-- 5. 1-MINUTE AUTO-RESALE CRON WORKER & ARCHIVER (Spec #8)
-- ----------------------------------------------------------------------------
-- Executes every 1 minute via pg_cron or Edge Function resale-worker:
-- 1) Finds RESERVED orders whose pickup_end has passed (SKIP LOCKED safe)
-- 2) Marks orders NO_SHOW + adds +1 strike (bans at >=3 for 30 days)
-- 3) Inserts bilingual strike notification (triggers FCM push outbox)
-- 4) Restores box quantity (+N), sets status = 'ACTIVE', is_resale = true,
--    and extends pickup_window from sprint_end until venue closing time (e.g. 19:15..20:00)
create or replace function private.run_resale_cron_worker()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_now timestamptz := timezone('utc', now());
  v_rec record;
  v_restored_qty integer;
  v_close_local timestamp;
  v_close_utc timestamptz;
  v_processed_orders integer := 0;
  v_resurrected_boxes integer := 0;
  v_notifications_created integer := 0;
  v_box_ids uuid[] := '{}';
begin
  -- Step A: Lock expired RESERVED orders cleanly with SKIP LOCKED
  for v_rec in
    select
      o.id as order_id,
      o.user_id,
      o.box_id,
      o.quantity,
      b.pickup_end,
      v.close_minute_of_day
    from public.orders o
    join public.boxes b on b.id = o.box_id
    join public.venues v on v.id = o.venue_id
    where o.status = 'RESERVED'
      and b.pickup_end <= v_now
    for update of o skip locked
  loop
    -- 1. Order -> NO_SHOW
    update public.orders
    set status = 'NO_SHOW',
        cancellation_reason = 'Автоотмена: время выдачи (15 мин Спринт) истекло'
    where id = v_rec.order_id;

    -- 2. Buyer +1 Strike (30-day ban when strikes >= 3)
    update public.profiles
    set strikes_count = strikes_count + 1,
        banned_until = case
          when strikes_count + 1 >= 3 then v_now + interval '30 days'
          else banned_until
        end
    where id = v_rec.user_id;

    -- 3. Push/In-app notification outbox row (EXACT copy from spec #8)
    insert into public.notifications (
      user_id,
      title_ru,
      title_kk,
      body_ru,
      body_kk
    ) values (
      v_rec.user_id,
      'Заказ отменён — начислен Strike',
      'Тапсырыс жойылды — 1 Strike берілді',
      'Заказ отменён, и вам начислено 1 предупреждение (Strike)',
      'Тапсырыс жойылды және сізге 1 ескерту (Strike) берілді'
    );

    v_processed_orders := v_processed_orders + 1;
    v_notifications_created := v_notifications_created + 1;

    -- 4. Track affected box & restore quantity (+N)
    if not (v_rec.box_id = any(v_box_ids)) then
      v_box_ids := array_append(v_box_ids, v_rec.box_id);
    end if;

    -- Calculate venue closing timestamp for that service day in Asia/Almaty
    v_close_local := ((v_rec.pickup_end at time zone 'Asia/Almaty')::date)
      + make_interval(mins => v_rec.close_minute_of_day);
    v_close_utc := v_close_local at time zone 'Asia/Almaty';

    update public.boxes b
    set quantity_left = least(b.quantity, b.quantity_left + v_rec.quantity),
        status = case
          when v_close_utc > v_now then 'ACTIVE'
          else 'EXPIRED'
        end,
        is_resale = case
          when v_close_utc > v_now then true
          else b.is_resale
        end,
        pickup_start = case
          when v_close_utc > v_now then greatest(b.pickup_end, date_trunc('minute', v_now))
          else b.pickup_start
        end,
        pickup_end = case
          when v_close_utc > v_now then v_close_utc
          else b.pickup_end
        end
    where b.id = v_rec.box_id
      and (
        b.quantity_left < b.quantity
        or b.status <> 'ACTIVE'
        or b.is_resale = false
      );
  end loop;

  v_resurrected_boxes := coalesce(array_length(v_box_ids, 1), 0);

  return jsonb_build_object(
    'ran_at', v_now,
    'processed_orders', v_processed_orders,
    'resurrected_boxes', v_resurrected_boxes,
    'created_notifications', v_notifications_created
  );
end;
$$;

-- Archive stale boxes whose final pickup_end (closing time) already passed.
create or replace function private.archive_expired_boxes()
returns integer
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_count integer := 0;
begin
  update public.boxes
  set status = 'EXPIRED'
  where status in ('ACTIVE', 'SOLD_OUT')
    and pickup_end <= timezone('utc', now())
    and not exists (
      select 1 from public.orders o
      where o.box_id = boxes.id
        and o.status = 'RESERVED'
    );

  get diagnostics v_count = row_count;
  return v_count;
end;
$$;

-- Wrapper callable ONLY by Edge Functions using SUPABASE_SERVICE_ROLE_KEY
create or replace function public.api_run_resale_cron_worker()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_resale jsonb;
  v_archived integer;
begin
  v_resale := private.run_resale_cron_worker();
  v_archived := private.archive_expired_boxes();
  return v_resale || jsonb_build_object('archived_boxes', v_archived);
end;
$$;

-- Tight execute privileges on functions
grant execute on function public.publish_sprint_box(
  uuid, text, text, text, text, integer, integer, integer,
  boolean, boolean, text[], text[], integer[]
) to authenticated;
grant execute on function public.create_trust_reservation(uuid, integer, boolean) to authenticated;
grant execute on function public.complete_order_pickup(uuid, text) to authenticated;
grant execute on function public.cancel_order_atomic(uuid, text) to authenticated;
grant execute on function public.submit_order_complaint(uuid, text, text[]) to authenticated;
grant execute on function public.submit_review_atomic(uuid, integer, text[], text) to authenticated;

revoke all on function public.api_run_resale_cron_worker() from public, anon, authenticated;
grant execute on function public.api_run_resale_cron_worker() to service_role;
