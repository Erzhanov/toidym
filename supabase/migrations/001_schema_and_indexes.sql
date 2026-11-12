-- ============================================================================
-- toıdym — 001_schema_and_indexes.sql
-- PostgreSQL / Supabase Production Schema (Zero-Waste Food Rescue Platform)
-- Compliant with Supabase Postgres Best Practices & Post-Oct 2026 Security
-- ============================================================================

-- Extensions
create extension if not exists pgcrypto with schema extensions;

-- Dedicated private schema (NOT exposed to PostgREST / Data API)
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

-- ----------------------------------------------------------------------------
-- 1. PROFILES (extends auth.users 1:1)
-- ----------------------------------------------------------------------------
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

-- ----------------------------------------------------------------------------
-- 2. VENUES (Astana partner establishments + PENDING partner leads)
-- ----------------------------------------------------------------------------
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

-- Link profiles.managed_venue_id FK now that venues exists
alter table public.profiles
  drop constraint if exists profiles_managed_venue_fk;
alter table public.profiles
  add constraint profiles_managed_venue_fk
  foreign key (managed_venue_id) references public.venues(id) on delete set null;

create trigger venues_set_updated_at
  before update on public.venues
  for each row execute function private.set_updated_at();

create index if not exists venues_owner_id_idx on public.venues (owner_id);
create index if not exists venues_status_district_idx
  on public.venues (status, district);

-- ----------------------------------------------------------------------------
-- 3. VENUE STAFF (Partner owners & Cashier pickup operators)
-- ----------------------------------------------------------------------------
create table if not exists public.venue_staff (
  venue_id uuid not null references public.venues(id) on delete cascade,
  user_id uuid not null references public.profiles(id) on delete cascade,
  staff_role text not null check (staff_role in ('PARTNER', 'CASHIER')),
  created_at timestamptz not null default timezone('utc', now()),
  primary key (venue_id, user_id)
);

create index if not exists venue_staff_user_id_idx
  on public.venue_staff (user_id);

-- ----------------------------------------------------------------------------
-- 4. BOX TEMPLATES (1-click daily republication templates)
-- ----------------------------------------------------------------------------
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

create trigger box_templates_set_updated_at
  before update on public.box_templates
  for each row execute function private.set_updated_at();

create index if not exists box_templates_venue_id_idx
  on public.box_templates (venue_id);

-- ----------------------------------------------------------------------------
-- 5. BOXES (Live & Archived food rescue boxes + 15-min Sprint & Resale state)
-- ----------------------------------------------------------------------------
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

-- ----------------------------------------------------------------------------
-- 6. ORDERS (Offline Trust Reservations + QR/PIN + Sprint/Resale + Complaints)
-- ----------------------------------------------------------------------------
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

-- ----------------------------------------------------------------------------
-- 7. REVIEWS
-- ----------------------------------------------------------------------------
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

-- ----------------------------------------------------------------------------
-- 8. NOTIFICATIONS (In-app bell + FCM Push Outbox)
-- ----------------------------------------------------------------------------
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

-- ----------------------------------------------------------------------------
-- 9. AUDIT LOGS (Immutable Admin Action Trail)
-- ----------------------------------------------------------------------------
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
