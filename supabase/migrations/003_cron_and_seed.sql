-- ============================================================================
-- toıdym — 003_cron_and_seed.sql
-- 1-Minute pg_cron Schedule (Sprint Expiry + Auto-Resale + Box Archiver)
-- + Astana Initial Seed Venues & Boxes (Idempotent)
-- ============================================================================

-- ----------------------------------------------------------------------------
-- 1. PG_CRON 1-MINUTE SCHEDULE (Database-native worker)
-- Enable "pg_cron" in Supabase Dashboard -> Database -> Extensions first!
-- ----------------------------------------------------------------------------
do $$
begin
  if exists (select 1 from pg_extension where extname = 'pg_cron') then
    -- Unschedule previous jobs if re-running migration
    perform cron.unschedule(jobid)
    from cron.job
    where jobname in ('toidym-resale-worker-1min', 'toidym-archive-expired-1min');

    -- Run 1-minute Resale Worker every minute (* * * * *)
    perform cron.schedule(
      'toidym-resale-worker-1min',
      '* * * * *',
      'select private.run_resale_cron_worker();'
    );

    -- Archive stale EXPIRED boxes every minute
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

-- ----------------------------------------------------------------------------
-- 2. OPTIONAL REALTIME PUBLICATION (Live stock/order sync in Flutter)
-- ----------------------------------------------------------------------------
do $$
begin
  if exists (select 1 from pg_publication where pubname = 'supabase_realtime') then
    begin
      alter publication supabase_realtime add table public.boxes;
    exception when duplicate_object then null;
    end;
    begin
      alter publication supabase_realtime add table public.orders;
    exception when duplicate_object then null;
    end;
    begin
      alter publication supabase_realtime add table public.notifications;
    exception when duplicate_object then null;
    end;
  end if;
end $$;

-- ----------------------------------------------------------------------------
-- 3. IDEMPOTENT ASTANA SEED DATA (Venues, Templates, Live Sprint Boxes)
-- Deterministic UUIDs allow safe re-runs with ON CONFLICT DO NOTHING.
-- ----------------------------------------------------------------------------
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

-- Seed Box Templates for quick 1-click daily republication
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

-- Seed Live Sprint Boxes using compute_sprint_window (15-min sprint before close)
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

-- ----------------------------------------------------------------------------
-- HINT AFTER SIGNING UP YOUR FIRST ADMIN USER IN SUPABASE AUTH:
-- Replace 'admin@toidym.kz' with your email and execute in SQL Editor:
--
--   update public.profiles
--   set role = 'ADMIN', is_verified = true
--   where email = 'admin@toidym.kz';
--
-- Trigger sync_profile_app_metadata will automatically grant ADMIN JWT claims!
-- ----------------------------------------------------------------------------
