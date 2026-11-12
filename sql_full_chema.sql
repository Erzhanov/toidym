-- ============================================================================
-- toıdym — sql_full_chema.sql
-- Толық бір реттік PostgreSQL / Supabase SQL скрипті (SQL Editor-ға бірден қоюға дайын)
-- Құрамы:
--   PART 1: Кестелер, CHECK шектеулері, FK және индекстер
--   PART 2: Auth триггерлері, қауіпсіздік (GRANT + RLS саясаттары)
--   PART 3: Атомарлы RPC функциялар (15-мин Спринт, Offline Trust Бронь, QR/PIN)
--   PART 4: 1 минуттық Auto-Resale CRON жоспарлаушы + Астана Seed деректері
-- ============================================================================

-- Extensions
create extension if not exists pgcrypto with schema extensions;

-- Dedicated private schema (PostgREST Data API-ға жабық ішкі схема)
create schema if not exists private;
revoke all on schema private from public, anon, authenticated;

-- ----------------------------------------------------------------------------
-- Shared trigger helper: updated_at timestamp
-- ----------------------------------------------------------------------------
create or replace function private.set_updated_at()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  new.updated_at := timezone('utc', now());
  return new;
end;
$$;

-- ============================================================================
-- PART 1: КЕСТЕЛЕР МЕН ИНДЕКСТЕР
-- ============================================================================

-- 1. PROFILES (extends auth.users 1:1)
create table if not exists public.profiles (
  id uuid primary key references auth.users(id) on delete cascade,
  email text not null default '',
  phone text not null default '',
  name text not null default 'Покупатель',
  role text not null default 'USER'
    check (role in ('USER', 'PARTNER', 'CASHIER', 'ADMIN')),
  language text not null default 'ru'
    check (language in ('kk', 'ru')),
  is_verified boolean not null default true,
  is_first_login boolean not null default false,
  dietary_preferences text[] not null default '{}',
  strikes_count integer not null default 0 check (strikes_count >= 0),
  banned_until timestamptz,
  managed_venue_id uuid,
  boxes_saved integer not null default 0 check (boxes_saved >= 0),
  co2_saved_kg numeric(10, 2) not null default 0 check (co2_saved_kg >= 0),
  money_saved_kzt integer not null default 0 check (money_saved_kzt >= 0),
  fcm_token text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

-- Егер Supabase жобасында ескі/шаблонды public.profiles кестесі бұрыннан бар болса,
-- жетіспейтін бағандарды (соның ішінде role) қауіпсіз түрде қосамыз:
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
alter table public.profiles add column if not exists managed_venue_id uuid;
alter table public.profiles add column if not exists boxes_saved integer not null default 0;
alter table public.profiles add column if not exists co2_saved_kg numeric(10, 2) not null default 0;
alter table public.profiles add column if not exists money_saved_kzt integer not null default 0;
alter table public.profiles add column if not exists fcm_token text;
alter table public.profiles add column if not exists created_at timestamptz not null default timezone('utc', now());
alter table public.profiles add column if not exists updated_at timestamptz not null default timezone('utc', now());

update public.profiles p
set email = coalesce(nullif(p.email, ''), u.email, ''),
    name = coalesce(nullif(p.name, ''), nullif(u.raw_user_meta_data ->> 'name', ''), 'Покупатель')
from auth.users u
where p.id = u.id
  and (p.email is null or p.email = '');

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.profiles'::regclass
      and conname = 'profiles_role_check'
  ) then
    alter table public.profiles
      add constraint profiles_role_check
      check (role in ('USER', 'PARTNER', 'CASHIER', 'ADMIN'));
  end if;
exception when duplicate_object then null;
end $$;

drop trigger if exists profiles_set_updated_at on public.profiles;
create trigger profiles_set_updated_at
  before update on public.profiles
  for each row execute function private.set_updated_at();

create unique index if not exists profiles_email_unique_idx
  on public.profiles (email)
  where email <> '';
create index if not exists profiles_role_idx
  on public.profiles (role);
create index if not exists profiles_managed_venue_idx
  on public.profiles (managed_venue_id)
  where managed_venue_id is not null;

-- 2. VENUES (Астана мекемелері + PENDING серіктес өтінімдері)
create table if not exists public.venues (
  id uuid primary key default gen_random_uuid(),
  owner_id uuid references public.profiles(id) on delete set null,
  name text not null,
  category text not null
    check (category in ('bakery', 'hot_food', 'coffee', 'grocery')),
  district text not null
    check (district in ('esil', 'almaty', 'saryarka', 'baiqonyr')),
  address text not null,
  lat double precision not null default 51.1282,
  lng double precision not null default 71.4304,
  rating numeric(3, 2) not null default 5.00 check (rating >= 0 and rating <= 5),
  reviews_count integer not null default 0 check (reviews_count >= 0),
  is_halal boolean not null default false,
  halal_cert_status text not null default 'none'
    check (halal_cert_status in ('none', 'pending', 'verified', 'rejected')),
  halal_cert_number text,
  open_minute_of_day integer not null default 480
    check (open_minute_of_day >= 0 and open_minute_of_day < 1440),
  close_minute_of_day integer not null default 1200
    check (close_minute_of_day > 0 and close_minute_of_day <= 1440),
  phone text not null,
  photo text not null default 'https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=800&q=80',
  status text not null default 'PENDING'
    check (status in ('PENDING', 'APPROVED', 'REJECTED', 'BANNED')),
  rejection_fields text[] not null default '{}',
  rejection_comment text,
  applicant_email text,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint venues_hours_valid check (close_minute_of_day > open_minute_of_day)
);

alter table public.venues add column if not exists owner_id uuid;
alter table public.venues add column if not exists status text not null default 'PENDING';
alter table public.venues add column if not exists district text not null default 'esil';
alter table public.venues add column if not exists halal_cert_status text not null default 'none';
alter table public.venues add column if not exists rejection_fields text[] not null default '{}';
alter table public.venues add column if not exists rejection_comment text;
alter table public.venues add column if not exists applicant_email text;
alter table public.venues add column if not exists open_minute_of_day integer not null default 480;
alter table public.venues add column if not exists close_minute_of_day integer not null default 1200;

alter table public.profiles
  drop constraint if exists profiles_managed_venue_fk;
alter table public.profiles
  add constraint profiles_managed_venue_fk
  foreign key (managed_venue_id) references public.venues(id) on delete set null;

drop trigger if exists venues_set_updated_at on public.venues;
create trigger venues_set_updated_at
  before update on public.venues
  for each row execute function private.set_updated_at();

create index if not exists venues_owner_id_idx on public.venues (owner_id);
create index if not exists venues_status_district_idx
  on public.venues (status, district);

-- 3. VENUE STAFF (Серіктес иелері мен Кассирлер)
create table if not exists public.venue_staff (
  venue_id uuid not null references public.venues(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  staff_role text not null check (staff_role in ('PARTNER', 'CASHIER')),
  created_at timestamptz not null default timezone('utc', now()),
  primary key (venue_id, user_id)
);

create index if not exists venue_staff_user_id_idx
  on public.venue_staff (user_id);

-- 4. BOX TEMPLATES (1 рет басу арқылы күнделікті қайта жариялау шаблондары)
create table if not exists public.box_templates (
  id uuid primary key default gen_random_uuid(),
  venue_id uuid not null references public.venues(id) on delete cascade,
  name text not null,
  description text not null default '',
  type text not null default 'surprise' check (type in ('surprise', 'set')),
  category text not null default 'bakery'
    check (category in ('bakery', 'hot_food', 'coffee')),
  original_price integer not null check (original_price > 0),
  discount_price integer not null check (discount_price >= 0),
  default_quantity integer not null default 4 check (default_quantity > 0),
  is_halal boolean not null default false,
  is_vegetarian boolean not null default false,
  allergens text[] not null default '{}',
  photos text[] not null default '{}',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint box_templates_price_valid check (discount_price <= original_price)
);

drop trigger if exists box_templates_set_updated_at on public.box_templates;
create trigger box_templates_set_updated_at
  before update on public.box_templates
  for each row execute function private.set_updated_at();

create index if not exists box_templates_venue_id_idx
  on public.box_templates (venue_id);

-- 5. BOXES (Бокстар + 15-мин Спринт + Resale күйі)
create table if not exists public.boxes (
  id uuid primary key default gen_random_uuid(),
  venue_id uuid not null references public.venues(id) on delete cascade,
  title text not null,
  description text not null default '',
  type text not null default 'surprise' check (type in ('surprise', 'set')),
  category text not null default 'bakery'
    check (category in ('bakery', 'hot_food', 'coffee')),
  original_price integer not null check (original_price > 0),
  discount_price integer not null check (discount_price >= 0),
  discount_percent integer generated always as (
    case
      when original_price > 0
      then greatest(0, least(100, round(((original_price - discount_price)::numeric / original_price) * 100)::integer))
      else 0
    end
  ) stored,
  quantity integer not null check (quantity > 0),
  quantity_left integer not null check (quantity_left >= 0 and quantity_left <= quantity),
  pickup_start timestamptz not null,
  pickup_end timestamptz not null,
  is_halal boolean not null default false,
  is_vegetarian boolean not null default false,
  is_resale boolean not null default false,
  allergens text[] not null default '{}',
  status text not null default 'ACTIVE'
    check (status in ('ACTIVE', 'SOLD_OUT', 'DISABLED', 'EXPIRED')),
  photos text[] not null default '{}',
  repeat_weekdays integer[] not null default '{}',
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now()),
  constraint boxes_window_valid check (pickup_end > pickup_start),
  constraint boxes_price_valid check (discount_price <= original_price)
);

alter table public.boxes add column if not exists venue_id uuid;
alter table public.boxes add column if not exists status text not null default 'ACTIVE';
alter table public.boxes add column if not exists is_resale boolean not null default false;
alter table public.boxes add column if not exists pickup_start timestamptz not null default timezone('utc', now());
alter table public.boxes add column if not exists pickup_end timestamptz not null default timezone('utc', now()) + interval '15 minutes';
alter table public.boxes add column if not exists quantity_left integer not null default 0;

drop trigger if exists boxes_set_updated_at on public.boxes;
create trigger boxes_set_updated_at
  before update on public.boxes
  for each row execute function private.set_updated_at();

create index if not exists boxes_venue_id_idx on public.boxes (venue_id);
create index if not exists boxes_catalog_active_idx
  on public.boxes (status, is_resale desc, pickup_end asc)
  where status in ('ACTIVE', 'SOLD_OUT');
create index if not exists boxes_expiry_scan_idx
  on public.boxes (pickup_end)
  where status in ('ACTIVE', 'SOLD_OUT');

-- 6. ORDERS (Сенімді офлайн бронь + QR/PIN + Sprint/Resale + Шағымдар)
create table if not exists public.orders (
  id uuid primary key default gen_random_uuid(),
  order_number text not null unique,
  user_id uuid not null references public.profiles(id) on delete cascade,
  box_id uuid not null references public.boxes(id) on delete cascade,
  venue_id uuid not null references public.venues(id) on delete cascade,
  quantity integer not null check (quantity > 0 and quantity <= 5),
  total_price integer not null check (total_price >= 0),
  original_total_price integer not null check (original_total_price >= 0),
  status text not null default 'RESERVED'
    check (status in ('RESERVED', 'COMPLETED', 'CANCELLED_BY_USER', 'CANCELLED_BY_VENUE', 'NO_SHOW')),
  qr_code text not null unique,
  pin_code text not null,
  payment_method text not null default 'on_site' check (payment_method in ('on_site')),
  picked_up_at timestamptz,
  cancellation_reason text,
  complaint_submitted boolean not null default false,
  complaint_status text not null default 'none'
    check (complaint_status in ('none', 'open', 'in_review', 'resolved')),
  complaint_note text,
  complaint_resolution_note text,
  complaint_photo_paths text[] not null default '{}',
  complaint_submitted_at timestamptz,
  is_charity_box boolean not null default false,
  created_at timestamptz not null default timezone('utc', now()),
  updated_at timestamptz not null default timezone('utc', now())
);

alter table public.orders add column if not exists user_id uuid;
alter table public.orders add column if not exists box_id uuid;
alter table public.orders add column if not exists venue_id uuid;
alter table public.orders add column if not exists status text not null default 'RESERVED';

drop trigger if exists orders_set_updated_at on public.orders;
create trigger orders_set_updated_at
  before update on public.orders
  for each row execute function private.set_updated_at();

create index if not exists orders_user_status_idx
  on public.orders (user_id, status, created_at desc);
create index if not exists orders_venue_status_idx
  on public.orders (venue_id, status, created_at desc);
create index if not exists orders_box_id_idx on public.orders (box_id);
create index if not exists orders_reserved_active_idx
  on public.orders (box_id, created_at)
  where status = 'RESERVED';

-- 7. REVIEWS
create table if not exists public.reviews (
  id uuid primary key default gen_random_uuid(),
  order_id uuid not null unique references public.orders(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  venue_id uuid not null references public.venues(id) on delete cascade,
  rating integer not null check (rating between 1 and 5),
  tags text[] not null default '{}',
  comment text not null default '',
  author_name text not null default 'Покупатель',
  created_at timestamptz not null default timezone('utc', now())
);

create index if not exists reviews_venue_id_idx
  on public.reviews (venue_id, created_at desc);
create index if not exists reviews_user_id_idx
  on public.reviews (user_id);

-- 8. NOTIFICATIONS (Қосымша ішіндегі + FCM Push кезегі)
create table if not exists public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.profiles(id) on delete cascade,
  title_ru text not null,
  title_kk text not null,
  body_ru text not null,
  body_kk text not null,
  is_read boolean not null default false,
  push_sent_at timestamptz,
  created_at timestamptz not null default timezone('utc', now())
);

create index if not exists notifications_user_unread_idx
  on public.notifications (user_id, is_read, created_at desc);
create index if not exists notifications_pending_push_idx
  on public.notifications (created_at)
  where push_sent_at is null;

-- 9. AUDIT LOGS (Админ әрекеттерінің журналы)
create table if not exists public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  actor_id uuid references public.profiles(id) on delete set null,
  actor_email text not null,
  action text not null,
  target_type text not null,
  target_id text not null,
  details text not null,
  created_at timestamptz not null default timezone('utc', now())
);

create index if not exists audit_logs_created_at_idx
  on public.audit_logs (created_at desc);
create index if not exists audit_logs_actor_id_idx
  on public.audit_logs (actor_id);

-- ============================================================================
-- PART 2: AUTH ТРИГГЕРЛЕРІ, РҰҚСАТТАР (GRANT) ЖӘНЕ RLS САЯСАТТАРЫ
-- ============================================================================

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
    id, email, phone, name, role, language,
    is_verified, is_first_login, managed_venue_id
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
  on conflict (id) do nothing;

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;
create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function private.handle_new_auth_user();

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

create or replace function private.protect_profile_columns()
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

-- Нақты GRANT рұқсаттары (Post-Oct 2026 Supabase талабы бойынша міндетті)
revoke all on all tables in schema public from public, anon, authenticated;
grant usage on schema public to anon, authenticated, service_role;

grant select on public.venues, public.boxes, public.reviews to anon;
grant insert on public.venues to anon;

grant select, update on public.profiles to authenticated;
grant select, insert, update on public.venues to authenticated;
grant select, insert, delete on public.venue_staff to authenticated;
grant select, insert, update, delete on public.box_templates to authenticated;
grant select, insert, update, delete on public.boxes to authenticated;
grant select, insert, update on public.orders to authenticated;
grant select, insert on public.reviews to authenticated;
grant select, update on public.notifications to authenticated;
grant select, insert on public.audit_logs to authenticated;

grant all privileges on all tables in schema public to service_role;

-- RLS қосу
alter table public.profiles enable row level security;
alter table public.venues enable row level security;
alter table public.venue_staff enable row level security;
alter table public.box_templates enable row level security;
alter table public.boxes enable row level security;
alter table public.orders enable row level security;
alter table public.reviews enable row level security;
alter table public.notifications enable row level security;
alter table public.audit_logs enable row level security;

-- PROFILES POLICIES
drop policy if exists "profiles_select_own_or_admin" on public.profiles;
create policy "profiles_select_own_or_admin"
  on public.profiles for select
  to authenticated
  using (
    id = (select auth.uid())
    or (select (auth.jwt() -> 'app_metadata' ->> 'role')) = 'ADMIN'
  );

drop policy if exists "profiles_update_own_or_admin" on public.profiles;
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

-- VENUES POLICIES
drop policy if exists "venues_select_public_approved" on public.venues;
create policy "venues_select_public_approved"
  on public.venues for select
  to anon
  using (status = 'APPROVED');

drop policy if exists "venues_select_authenticated" on public.venues;
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

drop policy if exists "venues_insert_pending_lead" on public.venues;
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

drop policy if exists "venues_update_owner_or_admin" on public.venues;
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

-- VENUE STAFF POLICIES
drop policy if exists "venue_staff_select_member_or_admin" on public.venue_staff;
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

drop policy if exists "venue_staff_manage_owner_or_admin" on public.venue_staff;
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

-- BOX TEMPLATES POLICIES
drop policy if exists "box_templates_venue_partner_or_admin" on public.box_templates;
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

-- BOXES POLICIES
drop policy if exists "boxes_select_anon_live" on public.boxes;
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

drop policy if exists "boxes_select_authenticated" on public.boxes;
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

drop policy if exists "boxes_write_partner_or_admin" on public.boxes;
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

drop policy if exists "boxes_update_partner_or_admin" on public.boxes;
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

-- ORDERS POLICIES
drop policy if exists "orders_select_buyer_venue_or_admin" on public.orders;
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

drop policy if exists "orders_update_admin" on public.orders;
create policy "orders_update_admin"
  on public.orders for update
  to authenticated
  using ((select (auth.jwt() -> 'app_metadata' ->> 'role')) = 'ADMIN')
  with check ((select (auth.jwt() -> 'app_metadata' ->> 'role')) = 'ADMIN');

-- REVIEWS POLICIES
drop policy if exists "reviews_select_public" on public.reviews;
create policy "reviews_select_public"
  on public.reviews for select
  to anon, authenticated
  using (true);

drop policy if exists "reviews_insert_own_completed_order" on public.reviews;
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

-- NOTIFICATIONS POLICIES
drop policy if exists "notifications_select_own" on public.notifications;
create policy "notifications_select_own"
  on public.notifications for select
  to authenticated
  using (user_id = (select auth.uid()));

drop policy if exists "notifications_update_read_own" on public.notifications;
create policy "notifications_update_read_own"
  on public.notifications for update
  to authenticated
  using (user_id = (select auth.uid()))
  with check (user_id = (select auth.uid()));

-- AUDIT LOGS POLICIES
drop policy if exists "audit_logs_admin_select" on public.audit_logs;
create policy "audit_logs_admin_select"
  on public.audit_logs for select
  to authenticated
  using ((select (auth.jwt() -> 'app_metadata' ->> 'role')) = 'ADMIN');

drop policy if exists "audit_logs_admin_insert" on public.audit_logs;
create policy "audit_logs_admin_insert"
  on public.audit_logs for insert
  to authenticated
  with check ((select (auth.jwt() -> 'app_metadata' ->> 'role')) = 'ADMIN');

-- ============================================================================
-- PART 3: АТОМАРЛЫ БИЗНЕС-ЛОГИКА (RPC ФУНКЦИЯЛАР)
-- ============================================================================

-- 15 минуттық Спринт терезесі [жабылу - 60 мин .. жабылу - 45 мин] (Asia/Almaty)
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

  if v_end_local <= v_local_now then
    v_start_local := (v_service_date + 1) + make_interval(mins => v_sprint_start_min);
    v_end_local := (v_service_date + 1) + make_interval(mins => v_sprint_end_min);
  end if;

  pickup_start := v_start_local at time zone 'Asia/Almaty';
  pickup_end := v_end_local at time zone 'Asia/Almaty';
  return next;
end;
$$;

-- Серіктес бокс жариялайды (15 минуттық Спринт уақыты автоматты орнатылады)
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

-- Атомарлы сенімді бронь (0% комиссия, қос броньдаудан қорғалған)
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

-- Кассир / Серіктес тапсырысты QR немесе 4 таңбалы PIN арқылы береді
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

-- Тапсырысты болдырмау (бокс қалдығын қайтарады)
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

-- Шағым жіберу
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

-- Пікір қалдыру және мекеме рейтингін қайта есептеу
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

-- ============================================================================
-- PART 4: 1 МИНУТТЫҚ AUTO-RESALE CRON WORKER + АРХИВАТОР + SEED
-- ============================================================================

create or replace function private.run_resale_cron_worker()
returns jsonb
language plpgsql
security definer
set search_path = ''
as $$
declare
  v_now timestamptz := timezone('utc', now());
  v_rec record;
  v_close_local timestamp;
  v_close_utc timestamptz;
  v_processed_orders integer := 0;
  v_resurrected_boxes integer := 0;
  v_notifications_created integer := 0;
  v_box_ids uuid[] := '{}';
begin
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
    update public.orders
    set status = 'NO_SHOW',
        cancellation_reason = 'Автоотмена: время выдачи (15 мин Спринт) истекло'
    where id = v_rec.order_id;

    update public.profiles
    set strikes_count = strikes_count + 1,
        banned_until = case
          when strikes_count + 1 >= 3 then v_now + interval '30 days'
          else banned_until
        end
    where id = v_rec.user_id;

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

    if not (v_rec.box_id = any(v_box_ids)) then
      v_box_ids := array_append(v_box_ids, v_rec.box_id);
    end if;

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

-- 1-минуттық pg_cron тіркеу (Dashboard -> Database -> Extensions -> pg_cron қосылған болса)
do $$
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
    raise notice 'pg_cron extension is not enabled yet. Enable pg_cron in Supabase Dashboard -> Database -> Extensions, or invoke Edge Function "resale-worker" every 1 minute.';
  end if;
end $$;

-- Realtime жариялау
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    begin
      alter publication supabase_realtime add table public.boxes;
    exception when others then null;
    end;
    begin
      alter publication supabase_realtime add table public.orders;
    exception when others then null;
    end;
    begin
      alter publication supabase_realtime add table public.notifications;
    exception when others then null;
    end;
  end if;
end $$;

-- Астана қаласының бастапқы мекемелері мен бокстары (идемпотентті)
insert into public.venues (
  id, name, category, district, address, lat, lng, rating, reviews_count,
  is_halal, halal_cert_status, halal_cert_number,
  open_minute_of_day, close_minute_of_day, phone, status, applicant_email
) values
  (
    '10000000-0000-4000-8000-000000000001',
    'BreadHouse Astana', 'bakery', 'esil',
    'пр. Мангилик Ел, 52', 51.1045, 71.4152, 4.90, 48,
    true, 'verified', 'QMDB-2026-0142',
    480, 1200, '+7 701 555 0101', 'APPROVED', 'partner1@toidym.kz'
  ),
  (
    '10000000-0000-4000-8000-000000000002',
    'Qaganat Асхана', 'hot_food', 'saryarka',
    'пр. Сарыарка, 17', 51.1683, 71.4105, 4.80, 62,
    true, 'verified', 'QMDB-2026-0088',
    540, 1260, '+7 701 555 0102', 'APPROVED', 'qaganat@toidym.kz'
  ),
  (
    '10000000-0000-4000-8000-000000000003',
    'Tary Ethno Coffee', 'coffee', 'esil',
    'ул. Достык, 16', 51.1258, 71.4309, 4.95, 39,
    true, 'pending', 'QMDB-2026-0301',
    480, 1320, '+7 701 555 0103', 'APPROVED', 'tary@toidym.kz'
  ),
  (
    '10000000-0000-4000-8000-000000000004',
    'Astana Pastry Hub', 'bakery', 'almaty',
    'ул. Момышулы, 24', 51.1421, 71.4685, 4.70, 18,
    false, 'none', null,
    510, 1200, '+7 701 555 0104', 'PENDING', 'lead@pastryhub.kz'
  )
on conflict (id) do nothing;

insert into public.box_templates (
  id, venue_id, name, description, type, category,
  original_price, discount_price, default_quantity, is_halal, is_vegetarian, allergens
) values
  (
    '20000000-0000-4000-8000-000000000001',
    '10000000-0000-4000-8000-000000000001',
    'Вечерний круассан-бокс',
    'Свежая слоёная выпечка, багет и синабоны в конце дня',
    'surprise', 'bakery', 3500, 1400, 5, true, true,
    array['Глютен', 'Молоко', 'Яйца']
  ),
  (
    '20000000-0000-4000-8000-000000000002',
    '10000000-0000-4000-8000-000000000002',
    'Домашний ужин Qaganat',
    'Плов или манты + салат и лепёшка в термоупаковке',
    'surprise', 'hot_food', 4000, 1600, 6, true, false,
    array['Глютен']
  )
on conflict (id) do nothing;

insert into public.boxes (
  id, venue_id, title, description, type, category,
  original_price, discount_price, quantity, quantity_left,
  pickup_start, pickup_end, is_halal, is_vegetarian, is_resale,
  allergens, status, photos
)
select
  '30000000-0000-4000-8000-000000000001',
  v.id,
  'Вечерний круассан-бокс (Спринт 15 мин)',
  'Свежие круассаны, слойки и ремесленный хлеб — успей забрать за 15 минут!',
  'surprise', 'bakery',
  3500, 1400, 5, 4,
  w.pickup_start, w.pickup_end,
  true, true, false,
  array['Глютен', 'Молоко'],
  'ACTIVE',
  array['https://images.unsplash.com/photo-1509440159596-0249088772ff?auto=format&fit=crop&w=800&q=80']
from public.venues v
cross join private.compute_sprint_window(v.open_minute_of_day, v.close_minute_of_day) w
where v.id = '10000000-0000-4000-8000-000000000001'
on conflict (id) do nothing;

insert into public.boxes (
  id, venue_id, title, description, type, category,
  original_price, discount_price, quantity, quantity_left,
  pickup_start, pickup_end, is_halal, is_vegetarian, is_resale,
  allergens, status, photos
)
select
  '30000000-0000-4000-8000-000000000002',
  v.id,
  'Жануда! Горячий ужин (Last Minute Resale)',
  'Возвратный бокс после неявки первого покупателя — заберите до закрытия!',
  'surprise', 'hot_food',
  4200, 1500, 4, 1,
  timezone('utc', now()),
  greatest(timezone('utc', now()) + interval '40 minutes', w.pickup_end + interval '45 minutes'),
  true, false, true,
  array['Глютен'],
  'ACTIVE',
  array['https://images.unsplash.com/photo-1546069901-ba9599a7e63c?auto=format&fit=crop&w=800&q=80']
from public.venues v
cross join private.compute_sprint_window(v.open_minute_of_day, v.close_minute_of_day) w
where v.id = '10000000-0000-4000-8000-000000000002'
on conflict (id) do nothing;
