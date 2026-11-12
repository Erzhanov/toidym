-- ============================================================================
-- toıdym — sql_add_missing_only.sql
-- Қолданыстағы дерекқорды БҰЗБАЙ, тек жетіспейтін кестелерді, бағандарды,
-- Спринт/Resale логикасын және 1-минуттық CRON жоспарлаушысын қосады.
-- Бар кестелеріңіз (users, profiles, user_roles, venues, boxes, orders,
-- audit, sessions, auth_limits, email_verifications, partner_applications)
-- және ішіндегі деректер ТОЛЫҚ САҚТАЛАДЫ.
-- ============================================================================

create extension if not exists pgcrypto with schema extensions;

create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

create or replace function private.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $fn$
begin
  new.updated_at := timezone('utc', now());
  return new;
end;
$fn$;

-- ============================================================================
-- 1. ҚОЛДАНЫСТАҒЫ КЕСТЕЛЕРГЕ ЖЕТІСПЕЙТІН БАҒАНДАРДЫ ҚОСУ (DATA-SAFE)
-- ============================================================================

-- PROFILES: жетіспейтін рөл, страйк, бан, статистика бағандары
do $mig$
declare
  v_venue_id_type text;
  v_has_user_roles boolean;
  v_has_ur_role boolean;
  v_has_ur_uid boolean;
  v_profile_key text;
begin
  select coalesce(
    (select format_type(a.atttypid, a.atttypmod)
     from pg_attribute a
     where a.attrelid = 'public.venues'::regclass
       and a.attname = 'id' and not a.attisdropped limit 1),
    'uuid'
  ) into v_venue_id_type;

  alter table public.profiles add column if not exists email text not null default '';
  alter table public.profiles add column if not exists phone text not null default '';
  alter table public.profiles add column if not exists name text not null default 'Покупатель';
  alter table public.profiles add column if not exists role text not null default 'USER';
  alter table public.profiles add column if not exists language text not null default 'ru';
  alter table public.profiles add column if not exists is_verified boolean not null default true;
  alter table public.profiles add column if not exists is_first_login boolean not null default false;
  alter table public.profiles add column if not exists dietary_preferences text[] not null default '{}';
  alter table public.profiles add column if not exists strikes_count integer not null default 0;
  alter table public.profiles add column if not exists banned_until timestamptz;
  execute format('alter table public.profiles add column if not exists managed_venue_id %s', v_venue_id_type);
  alter table public.profiles add column if not exists boxes_saved integer not null default 0;
  alter table public.profiles add column if not exists co2_saved_kg numeric(10, 2) not null default 0;
  alter table public.profiles add column if not exists money_saved_kzt integer not null default 0;
  alter table public.profiles add column if not exists fcm_token text;
  alter table public.profiles add column if not exists created_at timestamptz not null default timezone('utc', now());
  alter table public.profiles add column if not exists updated_at timestamptz not null default timezone('utc', now());

  -- Егер user_roles кестесінде рөлдер бар болса, profiles.role бағанына көшіру
  select exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'profiles' and column_name = 'id'
  ) into v_has_user_roles;
  v_profile_key := case when v_has_user_roles then 'id' else 'user_id' end;

  select exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'user_roles' and column_name = 'role'
  ) into v_has_ur_role;
  select exists (
    select 1 from information_schema.columns
    where table_schema = 'public' and table_name = 'user_roles' and column_name = 'user_id'
  ) into v_has_ur_uid;

  if v_has_ur_role and v_has_ur_uid then
    execute format(
      'update public.profiles p set role = upper(ur.role::text)
       from public.user_roles ur
       where p.%I::text = ur.user_id::text
         and upper(ur.role::text) in (''USER'',''PARTNER'',''CASHIER'',''ADMIN'')',
      v_profile_key
    );
  end if;
exception when others then
  raise notice 'profiles alter notice: %', sqlerrm;
end $mig$;

create index if not exists profiles_role_idx on public.profiles (role);

-- VENUES: жұмыс уақыты (15-мин Спринт есептеу үшін), халал және модерация бағандары
do $mig$
declare
  v_user_id_type text;
begin
  select coalesce(
    (select format_type(a.atttypid, a.atttypmod)
     from pg_attribute a
     where a.attrelid = 'public.profiles'::regclass
       and a.attname in ('id', 'user_id') and not a.attisdropped
     order by case when a.attname = 'id' then 0 else 1 end limit 1),
    'uuid'
  ) into v_user_id_type;

  execute format('alter table public.venues add column if not exists owner_id %s', v_user_id_type);
  alter table public.venues add column if not exists category text not null default 'bakery';
  alter table public.venues add column if not exists district text not null default 'esil';
  alter table public.venues add column if not exists lat double precision not null default 51.1282;
  alter table public.venues add column if not exists lng double precision not null default 71.4304;
  alter table public.venues add column if not exists rating numeric(3, 2) not null default 5.00;
  alter table public.venues add column if not exists reviews_count integer not null default 0;
  alter table public.venues add column if not exists is_halal boolean not null default false;
  alter table public.venues add column if not exists halal_cert_status text not null default 'none';
  alter table public.venues add column if not exists halal_cert_number text;
  alter table public.venues add column if not exists open_minute_of_day integer not null default 480;
  alter table public.venues add column if not exists close_minute_of_day integer not null default 1200;
  alter table public.venues add column if not exists status text not null default 'APPROVED';
  alter table public.venues add column if not exists rejection_fields text[] not null default '{}';
  alter table public.venues add column if not exists rejection_comment text;
  alter table public.venues add column if not exists applicant_email text;
  alter table public.venues add column if not exists created_at timestamptz not null default timezone('utc', now());
  alter table public.venues add column if not exists updated_at timestamptz not null default timezone('utc', now());
end $mig$;

-- BOXES: 15-мин Спринт + Auto-Resale (is_resale, pickup_start/pickup_end) бағандары
do $mig$
declare
  v_venue_id_type text;
begin
  select coalesce(
    (select format_type(a.atttypid, a.atttypmod)
     from pg_attribute a
     where a.attrelid = 'public.venues'::regclass
       and a.attname = 'id' and not a.attisdropped limit 1),
    'uuid'
  ) into v_venue_id_type;

  execute format('alter table public.boxes add column if not exists venue_id %s', v_venue_id_type);
  alter table public.boxes add column if not exists title text not null default '';
  alter table public.boxes add column if not exists description text not null default '';
  alter table public.boxes add column if not exists type text not null default 'surprise';
  alter table public.boxes add column if not exists category text not null default 'bakery';
  alter table public.boxes add column if not exists original_price integer not null default 0;
  alter table public.boxes add column if not exists discount_price integer not null default 0;
  alter table public.boxes add column if not exists discount_percent integer not null default 0;
  alter table public.boxes add column if not exists quantity integer not null default 1;
  alter table public.boxes add column if not exists quantity_left integer not null default 1;
  alter table public.boxes add column if not exists pickup_start timestamptz not null default timezone('utc', now());
  alter table public.boxes add column if not exists pickup_end timestamptz not null default timezone('utc', now()) + interval '15 minutes';
  alter table public.boxes add column if not exists is_halal boolean not null default false;
  alter table public.boxes add column if not exists is_vegetarian boolean not null default false;
  alter table public.boxes add column if not exists is_resale boolean not null default false;
  alter table public.boxes add column if not exists allergens text[] not null default '{}';
  alter table public.boxes add column if not exists status text not null default 'ACTIVE';
  alter table public.boxes add column if not exists photos text[] not null default '{}';
  alter table public.boxes add column if not exists repeat_weekdays integer[] not null default '{}';
  alter table public.boxes add column if not exists created_at timestamptz not null default timezone('utc', now());
  alter table public.boxes add column if not exists updated_at timestamptz not null default timezone('utc', now());
end $mig$;

create index if not exists boxes_resale_sprint_idx
  on public.boxes (status, is_resale desc, pickup_end asc);

-- ORDERS: QR/PIN, NO_SHOW, Шағымдар және Қайырымдылық (is_charity_box) бағандары
do $mig$
declare
  v_user_id_type text;
  v_box_id_type text;
  v_venue_id_type text;
begin
  select coalesce(
    (select format_type(a.atttypid, a.atttypmod)
     from pg_attribute a
     where a.attrelid = 'public.profiles'::regclass
       and a.attname in ('id', 'user_id') and not a.attisdropped
     order by case when a.attname = 'id' then 0 else 1 end limit 1),
    'uuid'
  ) into v_user_id_type;

  select coalesce(
    (select format_type(a.atttypid, a.atttypmod)
     from pg_attribute a
     where a.attrelid = 'public.boxes'::regclass
       and a.attname = 'id' and not a.attisdropped limit 1),
    'uuid'
  ) into v_box_id_type;

  select coalesce(
    (select format_type(a.atttypid, a.atttypmod)
     from pg_attribute a
     where a.attrelid = 'public.venues'::regclass
       and a.attname = 'id' and not a.attisdropped limit 1),
    'uuid'
  ) into v_venue_id_type;

  alter table public.orders add column if not exists order_number text not null default '#000000';
  execute format('alter table public.orders add column if not exists user_id %s', v_user_id_type);
  execute format('alter table public.orders add column if not exists box_id %s', v_box_id_type);
  execute format('alter table public.orders add column if not exists venue_id %s', v_venue_id_type);
  alter table public.orders add column if not exists quantity integer not null default 1;
  alter table public.orders add column if not exists total_price integer not null default 0;
  alter table public.orders add column if not exists original_total_price integer not null default 0;
  alter table public.orders add column if not exists status text not null default 'RESERVED';
  alter table public.orders add column if not exists qr_code text;
  alter table public.orders add column if not exists pin_code text not null default '0000';
  alter table public.orders add column if not exists payment_method text not null default 'on_site';
  alter table public.orders add column if not exists picked_up_at timestamptz;
  alter table public.orders add column if not exists cancellation_reason text;
  alter table public.orders add column if not exists complaint_submitted boolean not null default false;
  alter table public.orders add column if not exists complaint_status text not null default 'none';
  alter table public.orders add column if not exists complaint_note text;
  alter table public.orders add column if not exists complaint_resolution_note text;
  alter table public.orders add column if not exists complaint_photo_paths text[] not null default '{}';
  alter table public.orders add column if not exists complaint_submitted_at timestamptz;
  alter table public.orders add column if not exists is_charity_box boolean not null default false;
  alter table public.orders add column if not exists created_at timestamptz not null default timezone('utc', now());
  alter table public.orders add column if not exists updated_at timestamptz not null default timezone('utc', now());
end $mig$;

-- ============================================================================
-- 2. ЖЕТІСПЕЙ ТҰРҒАН 5 ЖАҢА КЕСТЕНІ ҚҰРУ (ID ТИПІН АВТОМАТТЫ СӘЙКЕСТЕНДІРІП)
-- ============================================================================
do $mig$
declare
  v_venue_id_type text;
  v_user_id_type text;
  v_order_id_type text;
  v_profile_pk_col text;
begin
  select coalesce(
    (select format_type(a.atttypid, a.atttypmod)
     from pg_attribute a
     where a.attrelid = 'public.venues'::regclass
       and a.attname = 'id' and not a.attisdropped limit 1),
    'uuid'
  ) into v_venue_id_type;

  select a.attname::text, format_type(a.atttypid, a.atttypmod)
  into v_profile_pk_col, v_user_id_type
  from pg_attribute a
  where a.attrelid = 'public.profiles'::regclass
    and a.attname in ('id', 'user_id') and not a.attisdropped
  order by case when a.attname = 'id' then 0 else 1 end
  limit 1;

  v_profile_pk_col := coalesce(v_profile_pk_col, 'id');
  v_user_id_type := coalesce(v_user_id_type, 'uuid');

  select coalesce(
    (select format_type(a.atttypid, a.atttypmod)
     from pg_attribute a
     where a.attrelid = 'public.orders'::regclass
       and a.attname = 'id' and not a.attisdropped limit 1),
    'uuid'
  ) into v_order_id_type;

  -- A. venue_staff (Мекеме иелері мен Кассирлер)
  execute format($sql$
    create table if not exists public.venue_staff (
      venue_id %1$s not null,
      user_id %2$s not null,
      staff_role text not null check (staff_role in ('PARTNER', 'CASHIER')),
      created_at timestamptz not null default timezone('utc', now()),
      primary key (venue_id, user_id)
    );
    create index if not exists venue_staff_user_id_idx on public.venue_staff (user_id);
  $sql$, v_venue_id_type, v_user_id_type);

  begin
    execute 'alter table public.venue_staff add constraint venue_staff_venue_fk foreign key (venue_id) references public.venues(id) on delete cascade';
  exception when others then null;
  end;

  -- B. box_templates (1-клик қайта жариялау шаблондары)
  execute format($sql$
    create table if not exists public.box_templates (
      id uuid primary key default gen_random_uuid(),
      venue_id %1$s not null,
      name text not null,
      description text not null default '',
      type text not null default 'surprise' check (type in ('surprise', 'set')),
      category text not null default 'bakery' check (category in ('bakery', 'hot_food', 'coffee')),
      original_price integer not null check (original_price > 0),
      discount_price integer not null check (discount_price >= 0),
      default_quantity integer not null default 4 check (default_quantity > 0),
      is_halal boolean not null default false,
      is_vegetarian boolean not null default false,
      allergens text[] not null default '{}',
      photos text[] not null default '{}',
      created_at timestamptz not null default timezone('utc', now()),
      updated_at timestamptz not null default timezone('utc', now())
    );
    create index if not exists box_templates_venue_id_idx on public.box_templates (venue_id);
  $sql$, v_venue_id_type);

  begin
    execute 'alter table public.box_templates add constraint box_templates_venue_fk foreign key (venue_id) references public.venues(id) on delete cascade';
  exception when others then null;
  end;

  -- C. reviews (Сатып алушы пікірлері)
  execute format($sql$
    create table if not exists public.reviews (
      id uuid primary key default gen_random_uuid(),
      order_id %1$s not null unique,
      user_id %2$s not null,
      venue_id %3$s not null,
      rating integer not null check (rating between 1 and 5),
      tags text[] not null default '{}',
      comment text not null default '',
      author_name text not null default 'Покупатель',
      created_at timestamptz not null default timezone('utc', now())
    );
    create index if not exists reviews_venue_id_idx on public.reviews (venue_id, created_at desc);
    create index if not exists reviews_user_id_idx on public.reviews (user_id);
  $sql$, v_order_id_type, v_user_id_type, v_venue_id_type);

  -- D. notifications (Strike және Push хабарламалар кезегі)
  execute format($sql$
    create table if not exists public.notifications (
      id uuid primary key default gen_random_uuid(),
      user_id %1$s not null,
      title_ru text not null,
      title_kk text not null,
      body_ru text not null,
      body_kk text not null,
      is_read boolean not null default false,
      push_sent_at timestamptz,
      created_at timestamptz not null default timezone('utc', now())
    );
    create index if not exists notifications_user_unread_idx on public.notifications (user_id, is_read, created_at desc);
    create index if not exists notifications_pending_push_idx on public.notifications (created_at) where push_sent_at is null;
  $sql$, v_user_id_type);

  -- E. audit_logs (Админ панель әрекеттер журналы)
  execute format($sql$
    create table if not exists public.audit_logs (
      id uuid primary key default gen_random_uuid(),
      actor_id %1$s,
      actor_email text not null,
      action text not null,
      target_type text not null,
      target_id text not null,
      details text not null,
      created_at timestamptz not null default timezone('utc', now())
    );
    create index if not exists audit_logs_created_at_idx on public.audit_logs (created_at desc);
  $sql$, v_user_id_type);
end $mig$;

-- ============================================================================
-- 3. RLS ЖӘНЕ GRANT РҰҚСАТТАРЫ (Жаңа 5 кестеге + API қолжетімділік)
-- ============================================================================
grant usage on schema public to anon, authenticated, service_role;
grant select, insert, update, delete on public.venue_staff, public.box_templates, public.reviews, public.notifications, public.audit_logs to authenticated;
grant select on public.reviews to anon;
grant all privileges on all tables in schema public to service_role;

alter table public.venue_staff enable row level security;
alter table public.box_templates enable row level security;
alter table public.reviews enable row level security;
alter table public.notifications enable row level security;
alter table public.audit_logs enable row level security;

drop policy if exists "venue_staff_select_own_or_admin" on public.venue_staff;
create policy "venue_staff_select_own_or_admin"
  on public.venue_staff for select to authenticated
  using (
    user_id::text = (select auth.uid())::text
    or (select (auth.jwt() -> 'app_metadata' ->> 'role')) = 'ADMIN'
  );

drop policy if exists "box_templates_partner_or_admin" on public.box_templates;
create policy "box_templates_partner_or_admin"
  on public.box_templates for all to authenticated
  using (
    (select (auth.jwt() -> 'app_metadata' ->> 'role')) = 'ADMIN'
    or exists (
      select 1 from public.venue_staff vs
      where vs.venue_id::text = box_templates.venue_id::text
        and vs.user_id::text = (select auth.uid())::text
        and vs.staff_role = 'PARTNER'
    )
  )
  with check (
    (select (auth.jwt() -> 'app_metadata' ->> 'role')) = 'ADMIN'
    or exists (
      select 1 from public.venue_staff vs
      where vs.venue_id::text = box_templates.venue_id::text
        and vs.user_id::text = (select auth.uid())::text
        and vs.staff_role = 'PARTNER'
    )
  );

drop policy if exists "reviews_select_public" on public.reviews;
create policy "reviews_select_public"
  on public.reviews for select to anon, authenticated using (true);

drop policy if exists "reviews_insert_own" on public.reviews;
create policy "reviews_insert_own"
  on public.reviews for insert to authenticated
  with check (user_id::text = (select auth.uid())::text);

drop policy if exists "notifications_own_select" on public.notifications;
create policy "notifications_own_select"
  on public.notifications for select to authenticated
  using (user_id::text = (select auth.uid())::text);

drop policy if exists "notifications_own_update" on public.notifications;
create policy "notifications_own_update"
  on public.notifications for update to authenticated
  using (user_id::text = (select auth.uid())::text)
  with check (user_id::text = (select auth.uid())::text);

drop policy if exists "audit_logs_admin_all" on public.audit_logs;
create policy "audit_logs_admin_all"
  on public.audit_logs for all to authenticated
  using ((select (auth.jwt() -> 'app_metadata' ->> 'role')) = 'ADMIN')
  with check ((select (auth.jwt() -> 'app_metadata' ->> 'role')) = 'ADMIN');

-- ============================================================================
-- 4. 15-МИНУТТЫҚ СПРИНТ + 1-МИНУТТЫҚ AUTO-RESALE CRON ЖӘНЕ RPC ФУНКЦИЯЛАР
-- ============================================================================

create or replace function private.compute_sprint_window(
  p_open_minute integer,
  p_close_minute integer,
  p_ref_utc timestamptz default timezone('utc', now())
)
returns table (pickup_start timestamptz, pickup_end timestamptz)
language plpgsql
immutable
set search_path = ''
as $fn$
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
  v_sprint_end_min := least(p_close_minute, greatest(v_sprint_start_min + 15, p_close_minute - 45));

  v_start_local := v_service_date + make_interval(mins => v_sprint_start_min);
  v_end_local := v_service_date + make_interval(mins => v_sprint_end_min);

  if v_end_local <= v_local_now then
    v_start_local := (v_service_date + 1) + make_interval(mins => v_sprint_start_min);
    v_end_local := (v_service_date + 1) + make_interval(mins => v_sprint_end_min);
  end if;

  pickup_start := v_start_local at time zone 'Asia/Almaty';
  pickup_end := v_end_local at time zone 'Asia/Almaty';
  return next;
end;
$fn$;

-- 1-минуттық Auto-Resale Worker (profiles бағаны id немесе user_id екенін ескеріп құрылады)
do $mig$
declare
  v_profile_pk text;
begin
  select case
    when exists (
      select 1 from information_schema.columns
      where table_schema = 'public' and table_name = 'profiles' and column_name = 'id'
    ) then 'id'
    else 'user_id'
  end into v_profile_pk;

  execute format($fn_wrap$
    create or replace function private.run_resale_cron_worker()
    returns jsonb
    language plpgsql
    security definer
    set search_path = ''
    as $fn$
    declare
      v_now timestamptz := timezone('utc', now());
      v_rec record;
      v_close_local timestamp;
      v_close_utc timestamptz;
      v_processed_orders integer := 0;
      v_notifications_created integer := 0;
      v_box_ids text[] := '{}';
    begin
      for v_rec in
        select
          o.id::text as order_id_txt,
          o.user_id,
          o.box_id::text as box_id_txt,
          o.quantity,
          b.pickup_end,
          coalesce(v.close_minute_of_day, 1200) as close_minute_of_day
        from public.orders o
        join public.boxes b on b.id::text = o.box_id::text
        join public.venues v on v.id::text = o.venue_id::text
        where o.status = 'RESERVED'
          and b.pickup_end <= v_now
        for update of o skip locked
      loop
        update public.orders
        set status = 'NO_SHOW',
            cancellation_reason = 'Автоотмена: время выдачи (15 мин Спринт) истекло'
        where id::text = v_rec.order_id_txt;

        update public.profiles
        set strikes_count = coalesce(strikes_count, 0) + 1,
            banned_until = case
              when coalesce(strikes_count, 0) + 1 >= 3 then v_now + interval '30 days'
              else banned_until
            end
        where %1$I::text = v_rec.user_id::text;

        insert into public.notifications (
          user_id, title_ru, title_kk, body_ru, body_kk
        ) values (
          v_rec.user_id,
          'Заказ отменён — начислен Strike',
          'Тапсырыс жойылды — 1 Strike берілді',
          'Заказ отменён, и вам начислено 1 предупреждение (Strike)',
          'Тапсырыс жойылды және сізге 1 ескерту (Strike) берілді'
        );

        v_processed_orders := v_processed_orders + 1;
        v_notifications_created := v_notifications_created + 1;

        if not (v_rec.box_id_txt = any(v_box_ids)) then
          v_box_ids := array_append(v_box_ids, v_rec.box_id_txt);
        end if;

        v_close_local := ((v_rec.pickup_end at time zone 'Asia/Almaty')::date)
          + make_interval(mins => v_rec.close_minute_of_day);
        v_close_utc := v_close_local at time zone 'Asia/Almaty';

        update public.boxes b
        set quantity_left = least(b.quantity, b.quantity_left + v_rec.quantity),
            status = case when v_close_utc > v_now then 'ACTIVE' else 'EXPIRED' end,
            is_resale = case when v_close_utc > v_now then true else b.is_resale end,
            pickup_start = case
              when v_close_utc > v_now then greatest(b.pickup_end, date_trunc('minute', v_now))
              else b.pickup_start
            end,
            pickup_end = case
              when v_close_utc > v_now then v_close_utc
              else b.pickup_end
            end
        where b.id::text = v_rec.box_id_txt
          and (b.quantity_left < b.quantity or b.status <> 'ACTIVE' or b.is_resale = false);
      end loop;

      return jsonb_build_object(
        'ran_at', v_now,
        'processed_orders', v_processed_orders,
        'resurrected_boxes', coalesce(array_length(v_box_ids, 1), 0),
        'created_notifications', v_notifications_created
      );
    end;
    $fn$;
  $fn_wrap$, v_profile_pk);
end $mig$;

create or replace function private.archive_expired_boxes()
returns integer
language plpgsql
security definer
set search_path = ''
as $fn$
declare
  v_count integer := 0;
begin
  update public.boxes
  set status = 'EXPIRED'
  where status in ('ACTIVE', 'SOLD_OUT')
    and pickup_end <= timezone('utc', now())
    and not exists (
      select 1 from public.orders o
      where o.box_id::text = boxes.id::text
        and o.status = 'RESERVED'
    );

  get diagnostics v_count = row_count;
  return v_count;
end;
$fn$;

create or replace function public.api_run_resale_cron_worker()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $fn$
declare
  v_resale jsonb;
  v_archived integer;
begin
  v_resale := private.run_resale_cron_worker();
  v_archived := private.archive_expired_boxes();
  return v_resale || jsonb_build_object('archived_boxes', v_archived);
end;
$fn$;

revoke all on function public.api_run_resale_cron_worker() from public, anon, authenticated;
grant execute on function public.api_run_resale_cron_worker() to service_role;

-- Қолданушы/Дүкен/Админ RPC функциялары (ID типіне қарамай uuid/text үйлесімді)
do $mig$
declare
  v_profile_pk text;
  v_is_generated boolean;
begin
  select case
    when exists (
      select 1 from information_schema.columns
      where table_schema = 'public' and table_name = 'profiles' and column_name = 'id'
    ) then 'id'
    else 'user_id'
  end into v_profile_pk;

  select exists (
    select 1 from pg_attribute a
    where a.attrelid = 'public.boxes'::regclass
      and a.attname = 'discount_percent'
      and a.attgenerated <> ''
  ) into v_is_generated;

  execute format($fn_wrap$
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
    as $fn$
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

      select * into v_venue from public.venues where id::text = p_venue_id;
      if not found then
        raise exception 'Venue not found';
      end if;

      v_is_allowed := (
        coalesce(auth.jwt() -> 'app_metadata' ->> 'role', '') = 'ADMIN'
        or v_venue.owner_id::text = v_uid::text
        or exists (
          select 1 from public.venue_staff vs
          where vs.venue_id::text = p_venue_id
            and vs.user_id::text = v_uid::text
            and vs.staff_role = 'PARTNER'
        )
      );
      if not v_is_allowed then
        raise exception 'Permission denied: only venue PARTNER or ADMIN can publish boxes';
      end if;

      select * into v_win
      from private.compute_sprint_window(
        coalesce(v_venue.open_minute_of_day, 480),
        coalesce(v_venue.close_minute_of_day, 1200)
      );

      insert into public.boxes (
        venue_id, title, description, type, category,
        original_price, discount_price, quantity, quantity_left,
        pickup_start, pickup_end, is_halal, is_vegetarian,
        is_resale, allergens, status, photos, repeat_weekdays
      ) values (
        v_venue.id, p_title, coalesce(p_description, ''), p_type, p_category,
        p_original_price, p_discount_price, p_quantity, p_quantity,
        v_win.pickup_start, v_win.pickup_end, p_is_halal, p_is_vegetarian,
        false, coalesce(p_allergens, '{}'), 'ACTIVE', coalesce(p_photos, '{}'),
        coalesce(p_repeat_weekdays, '{}')
      )
      returning * into v_box;

      %1$s

      return v_box;
    end;
    $fn$;

    create or replace function public.create_trust_reservation(
      p_box_id text,
      p_quantity integer default 1,
      p_is_charity boolean default false
    )
    returns public.orders
    language plpgsql
    security definer
    set search_path = ''
    as $fn$
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

      select * into v_profile from public.profiles where %2$I::text = v_uid::text for update;
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
      where id::text = v_box.id::text;

      v_pin := lpad(((floor(random() * 9000) + 1000)::integer)::text, 4, '0');
      v_num := '#' || lpad(((floor(random() * 900000) + 100000)::integer)::text, 6, '0');
      v_qr := 'TOIDYM-' || replace(gen_random_uuid()::text, '-', '');

      insert into public.orders (
        order_number, user_id, box_id, venue_id, quantity,
        total_price, original_total_price, status,
        qr_code, pin_code, payment_method, is_charity_box
      ) values (
        v_num,
        v_profile.%2$I,
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
    $fn$;

    create or replace function public.complete_order_pickup(
      p_order_id text default null,
      p_qr_or_pin text default null
    )
    returns public.orders
    language plpgsql
    security definer
    set search_path = ''
    as $fn$
    declare
      v_uid uuid;
      v_order public.orders;
      v_is_staff boolean;
    begin
      v_uid := (select auth.uid());
      if v_uid is null then
        raise exception 'Authentication required';
      end if;

      if nullif(trim(coalesce(p_order_id, '')), '') is not null then
        select * into v_order from public.orders where id::text = trim(p_order_id) for update;
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
        raise exception 'Order is already %%', v_order.status;
      end if;

      v_is_staff := (
        coalesce(auth.jwt() -> 'app_metadata' ->> 'role', '') = 'ADMIN'
        or exists (
          select 1 from public.venue_staff vs
          where vs.venue_id::text = v_order.venue_id::text
            and vs.user_id::text = v_uid::text
        )
        or exists (
          select 1 from public.venues v
          where v.id::text = v_order.venue_id::text
            and v.owner_id::text = v_uid::text
        )
      );
      if not v_is_staff then
        raise exception 'Permission denied';
      end if;

      update public.orders
      set status = 'COMPLETED',
          picked_up_at = timezone('utc', now())
      where id::text = v_order.id::text
      returning * into v_order;

      update public.profiles
      set boxes_saved = coalesce(boxes_saved, 0) + v_order.quantity,
          co2_saved_kg = coalesce(co2_saved_kg, 0) + (v_order.quantity * 1.25),
          money_saved_kzt = coalesce(money_saved_kzt, 0) + greatest(0, v_order.original_total_price - v_order.total_price)
      where %2$I::text = v_order.user_id::text;

      return v_order;
    end;
    $fn$;

    create or replace function public.cancel_order_atomic(
      p_order_id text,
      p_reason text default null
    )
    returns public.orders
    language plpgsql
    security definer
    set search_path = ''
    as $fn$
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

      select * into v_order from public.orders where id::text = p_order_id for update;
      if not found then
        raise exception 'Order not found';
      end if;

      if v_order.status <> 'RESERVED' then
        raise exception 'Only RESERVED orders can be cancelled';
      end if;

      v_is_buyer := (v_order.user_id::text = v_uid::text);
      v_is_venue := (
        coalesce(auth.jwt() -> 'app_metadata' ->> 'role', '') = 'ADMIN'
        or exists (
          select 1 from public.venue_staff vs
          where vs.venue_id::text = v_order.venue_id::text
            and vs.user_id::text = v_uid::text
            and vs.staff_role = 'PARTNER'
        )
        or exists (
          select 1 from public.venues v
          where v.id::text = v_order.venue_id::text
            and v.owner_id::text = v_uid::text
        )
      );

      if not v_is_buyer and not v_is_venue then
        raise exception 'Permission denied';
      end if;

      v_new_status := case when v_is_venue and not v_is_buyer
                           then 'CANCELLED_BY_VENUE'
                           else 'CANCELLED_BY_USER' end;

      select * into v_box from public.boxes where id::text = v_order.box_id::text for update;
      if found and v_box.pickup_end > timezone('utc', now()) then
        update public.boxes
        set quantity_left = least(quantity, quantity_left + v_order.quantity),
            status = 'ACTIVE'
        where id::text = v_box.id::text;
      end if;

      update public.orders
      set status = v_new_status,
          cancellation_reason = coalesce(nullif(trim(p_reason), ''), 'Отменено')
      where id::text = v_order.id::text
      returning * into v_order;

      return v_order;
    end;
    $fn$;

    create or replace function public.submit_order_complaint(
      p_order_id text,
      p_note text,
      p_photo_paths text[] default '{}'
    )
    returns public.orders
    language plpgsql
    security definer
    set search_path = ''
    as $fn$
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
      where id::text = p_order_id
        and user_id::text = v_uid::text
      returning * into v_order;

      if not found then
        raise exception 'Order not found or not owned by user';
      end if;

      return v_order;
    end;
    $fn$;

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
    as $fn$
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

      select * into v_order from public.orders where id::text = p_order_id;
      if not found or v_order.user_id::text <> v_uid::text or v_order.status <> 'COMPLETED' then
        raise exception 'Review allowed only on your COMPLETED orders';
      end if;

      select name into v_author from public.profiles where %2$I::text = v_uid::text;

      insert into public.reviews (
        order_id, user_id, venue_id, rating, tags, comment, author_name
      ) values (
        v_order.id, v_order.user_id, v_order.venue_id, p_rating,
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
    $fn$;
  $fn_wrap$,
  case
    when v_is_generated then ''
    else 'update public.boxes set discount_percent = greatest(0, least(100, round(((p_original_price - p_discount_price)::numeric / greatest(1, p_original_price)) * 100)::integer)) where id::text = v_box.id::text returning * into v_box;'
  end,
  v_profile_pk);
end $mig$;

grant execute on function public.publish_sprint_box(
  text, text, text, text, text, integer, integer, integer,
  boolean, boolean, text[], text[], integer[]
) to authenticated;
grant execute on function public.create_trust_reservation(text, integer, boolean) to authenticated;
grant execute on function public.complete_order_pickup(text, text) to authenticated;
grant execute on function public.cancel_order_atomic(text, text) to authenticated;
grant execute on function public.submit_order_complaint(text, text, text[]) to authenticated;
grant execute on function public.submit_review_atomic(text, integer, text[], text) to authenticated;

-- 1-минуттық pg_cron тіркеу (* * * * *)
do $cron$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    perform cron.unschedule(jobid)
    from cron.job
    where jobname in ('toidym-resale-worker-1min', 'toidym-archive-expired-1min');

    perform cron.schedule(
      'toidym-resale-worker-1min',
      '* * * * *',
      'select private.run_resale_cron_worker();'
    );

    perform cron.schedule(
      'toidym-archive-expired-1min',
      '* * * * *',
      'select private.archive_expired_boxes();'
    );
    raise notice 'pg_cron jobs scheduled successfully (every 1 minute).';
  else
    raise notice 'pg_cron is not enabled yet. Enable pg_cron in Database -> Extensions or run Edge Function resale-worker every 1 minute.';
  end if;
end $cron$;
