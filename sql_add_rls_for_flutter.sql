-- ============================================================================
-- toıdym — sql_add_rls_for_flutter.sql
-- Ескі *_service (Lovable веб-сервер) саясаттарын БҰЗБАЙ, Flutter мобильді
-- қосымшасына (anon / authenticated) қажетті RLS саясаттарын, GRANT-тарды
-- және рөлдік қорғаныс триггерлерін қосады.
-- ============================================================================

-- 1. PostgREST-тен жасырын RLS тексеру схемасы (N+1 және рекурсиясыз)
create schema if not exists app_rls;
grant usage on schema app_rls to anon, authenticated;

create or replace function app_rls.is_admin()
returns boolean
language sql
stable
security definer
set search_path = ''
as $$
  select
    coalesce((select auth.jwt() -> 'app_metadata' ->> 'role'), '') = 'ADMIN'
    or exists (
      select 1
      from public.profiles p
      where p.id = (select auth.uid())
        and upper(coalesce(p.role, '')) = 'ADMIN'
    )
    or exists (
      select 1
      from public.user_roles ur
      where ur.user_id = (select auth.uid())
        and upper(coalesce(ur.role::text, '')) = 'ADMIN'
    );
$$;

revoke all on function app_rls.is_admin() from public, anon;
grant execute on function app_rls.is_admin() to authenticated;

-- 2. Қарапайым қолданушылар рөлді/страйкты/мәртебені қолдан бұрмаламауы үшін триггерлер
create or replace function private.protect_profile_columns()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if current_user in ('postgres', 'service_role', 'supabase_admin') then
    return new;
  end if;

  if (select app_rls.is_admin()) then
    return new;
  end if;

  if tg_op = 'INSERT' then
    new.role := 'USER';
    new.strikes_count := 0;
    new.banned_until := null;
    new.managed_venue_id := null;
    new.boxes_saved := 0;
    new.co2_saved_kg := 0;
    new.money_saved_kzt := 0;
    return new;
  end if;

  new.role := old.role;
  new.strikes_count := old.strikes_count;
  new.banned_until := old.banned_until;
  new.managed_venue_id := old.managed_venue_id;
  new.boxes_saved := old.boxes_saved;
  new.co2_saved_kg := old.co2_saved_kg;
  new.money_saved_kzt := old.money_saved_kzt;
  new.is_verified := old.is_verified;
  return new;
end;
$$;

drop trigger if exists protect_profiles_before_write on public.profiles;
create trigger protect_profiles_before_write
  before insert or update on public.profiles
  for each row execute function private.protect_profile_columns();

create or replace function private.protect_venue_columns()
returns trigger
language plpgsql
set search_path = ''
as $$
begin
  if current_user in ('postgres', 'service_role', 'supabase_admin') then
    return new;
  end if;

  if (select app_rls.is_admin()) then
    return new;
  end if;

  new.status := old.status;
  new.owner_id := old.owner_id;
  new.halal_cert_status := old.halal_cert_status;
  new.rating := old.rating;
  new.reviews_count := old.reviews_count;
  new.rejection_fields := old.rejection_fields;
  new.rejection_comment := old.rejection_comment;
  return new;
end;
$$;

drop trigger if exists protect_venues_before_update on public.venues;
create trigger protect_venues_before_update
  before update on public.venues
  for each row execute function private.protect_venue_columns();

-- 3. RLS өнімділігі үшін индекстер
create index if not exists venues_owner_status_idx on public.venues (owner_id, status);
create index if not exists boxes_venue_status_idx on public.boxes (venue_id, status);
create index if not exists orders_user_idx on public.orders (user_id);
create index if not exists orders_venue_idx on public.orders (venue_id);
create index if not exists user_roles_user_id_idx on public.user_roles (user_id);

-- 4. Ең аз қажетті кесте құқықтары (ескі service_role құқықтары сақталады)
grant usage on schema public to anon, authenticated;

grant select, insert on public.venues to anon;
grant select on public.boxes to anon;

grant select, insert, update on public.profiles to authenticated;
grant select, insert, update on public.venues to authenticated;
grant select, insert, update, delete on public.boxes to authenticated;
grant select, insert, update on public.orders to authenticated;

grant usage, select on all sequences in schema public to anon, authenticated;

-- 5. PROFILES: өз профилін жаңарту + ADMIN барлық қолданушыларды көру/басқару
drop policy if exists "toidym_flutter_profiles_insert_own" on public.profiles;
create policy "toidym_flutter_profiles_insert_own"
  on public.profiles for insert
  to authenticated
  with check (id = (select auth.uid()));

drop policy if exists "toidym_flutter_profiles_select_admin" on public.profiles;
create policy "toidym_flutter_profiles_select_admin"
  on public.profiles for select
  to authenticated
  using ((select app_rls.is_admin()));

drop policy if exists "toidym_flutter_profiles_update_own_or_admin" on public.profiles;
create policy "toidym_flutter_profiles_update_own_or_admin"
  on public.profiles for update
  to authenticated
  using (id = (select auth.uid()) or (select app_rls.is_admin()))
  with check (id = (select auth.uid()) or (select app_rls.is_admin()));

-- 6. VENUES: каталогты оқу, серіктес өтінімін жіберу (PENDING), иесі/ADMIN жаңарту
drop policy if exists "toidym_flutter_venues_select_anon" on public.venues;
create policy "toidym_flutter_venues_select_anon"
  on public.venues for select
  to anon
  using (upper(coalesce(status, 'APPROVED')) = 'APPROVED');

drop policy if exists "toidym_flutter_venues_select_auth" on public.venues;
create policy "toidym_flutter_venues_select_auth"
  on public.venues for select
  to authenticated
  using (
    upper(coalesce(status, 'APPROVED')) = 'APPROVED'
    or owner_id::text = (select auth.uid())::text
    or (select app_rls.is_admin())
    or exists (
      select 1 from public.venue_staff vs
      where vs.venue_id::text = venues.id::text
        and vs.user_id::text = (select auth.uid())::text
    )
  );

drop policy if exists "toidym_flutter_venues_insert_lead" on public.venues;
create policy "toidym_flutter_venues_insert_lead"
  on public.venues for insert
  to anon, authenticated
  with check (upper(coalesce(status, 'PENDING')) = 'PENDING');

drop policy if exists "toidym_flutter_venues_update_owner_or_admin" on public.venues;
create policy "toidym_flutter_venues_update_owner_or_admin"
  on public.venues for update
  to authenticated
  using (
    owner_id::text = (select auth.uid())::text
    or (select app_rls.is_admin())
  )
  with check (
    owner_id::text = (select auth.uid())::text
    or (select app_rls.is_admin())
  );

-- 7. BOXES: каталогты оқу, серіктес/ADMIN басқару
drop policy if exists "toidym_flutter_boxes_select_anon" on public.boxes;
create policy "toidym_flutter_boxes_select_anon"
  on public.boxes for select
  to anon
  using (upper(coalesce(status, 'ACTIVE')) in ('ACTIVE', 'SOLD_OUT'));

drop policy if exists "toidym_flutter_boxes_select_auth" on public.boxes;
create policy "toidym_flutter_boxes_select_auth"
  on public.boxes for select
  to authenticated
  using (
    upper(coalesce(status, 'ACTIVE')) in ('ACTIVE', 'SOLD_OUT')
    or (select app_rls.is_admin())
    or exists (
      select 1 from public.venue_staff vs
      where vs.venue_id::text = boxes.venue_id::text
        and vs.user_id::text = (select auth.uid())::text
    )
    or exists (
      select 1 from public.venues v
      where v.id::text = boxes.venue_id::text
        and v.owner_id::text = (select auth.uid())::text
    )
  );

drop policy if exists "toidym_flutter_boxes_manage_partner_or_admin" on public.boxes;
create policy "toidym_flutter_boxes_manage_partner_or_admin"
  on public.boxes for all
  to authenticated
  using (
    (select app_rls.is_admin())
    or exists (
      select 1 from public.venues v
      where v.id::text = boxes.venue_id::text
        and v.owner_id::text = (select auth.uid())::text
    )
    or exists (
      select 1 from public.venue_staff vs
      where vs.venue_id::text = boxes.venue_id::text
        and vs.user_id::text = (select auth.uid())::text
        and vs.staff_role = 'PARTNER'
    )
  )
  with check (
    (select app_rls.is_admin())
    or exists (
      select 1 from public.venues v
      where v.id::text = boxes.venue_id::text
        and v.owner_id::text = (select auth.uid())::text
    )
    or exists (
      select 1 from public.venue_staff vs
      where vs.venue_id::text = boxes.venue_id::text
        and vs.user_id::text = (select auth.uid())::text
        and vs.staff_role = 'PARTNER'
    )
  );

-- 8. ORDERS: сатып алушы өзінікін, дүкен қызметкері дүкендікін, ADMIN бәрін көру + шағым шешу
drop policy if exists "toidym_flutter_orders_select" on public.orders;
create policy "toidym_flutter_orders_select"
  on public.orders for select
  to authenticated
  using (
    user_id::text = (select auth.uid())::text
    or (select app_rls.is_admin())
    or exists (
      select 1 from public.venue_staff vs
      where vs.venue_id::text = orders.venue_id::text
        and vs.user_id::text = (select auth.uid())::text
    )
    or exists (
      select 1 from public.venues v
      where v.id::text = orders.venue_id::text
        and v.owner_id::text = (select auth.uid())::text
    )
  );

drop policy if exists "toidym_flutter_orders_update_admin" on public.orders;
create policy "toidym_flutter_orders_update_admin"
  on public.orders for update
  to authenticated
  using ((select app_rls.is_admin()))
  with check ((select app_rls.is_admin()));

-- 9. Жаңа 3 кестедегі ADMIN саясатын user_roles/profiles арқылы да тану
drop policy if exists "venue_staff_select_own_or_admin" on public.venue_staff;
create policy "venue_staff_select_own_or_admin"
  on public.venue_staff for select to authenticated
  using (
    user_id::text = (select auth.uid())::text
    or (select app_rls.is_admin())
  );

drop policy if exists "box_templates_partner_or_admin" on public.box_templates;
create policy "box_templates_partner_or_admin"
  on public.box_templates for all to authenticated
  using (
    (select app_rls.is_admin())
    or exists (
      select 1 from public.venues v
      where v.id::text = box_templates.venue_id::text
        and v.owner_id::text = (select auth.uid())::text
    )
    or exists (
      select 1 from public.venue_staff vs
      where vs.venue_id::text = box_templates.venue_id::text
        and vs.user_id::text = (select auth.uid())::text
        and vs.staff_role = 'PARTNER'
    )
  )
  with check (
    (select app_rls.is_admin())
    or exists (
      select 1 from public.venues v
      where v.id::text = box_templates.venue_id::text
        and v.owner_id::text = (select auth.uid())::text
    )
    or exists (
      select 1 from public.venue_staff vs
      where vs.venue_id::text = box_templates.venue_id::text
        and vs.user_id::text = (select auth.uid())::text
        and vs.staff_role = 'PARTNER'
    )
  );

drop policy if exists "audit_logs_admin_all" on public.audit_logs;
create policy "audit_logs_admin_all"
  on public.audit_logs for all to authenticated
  using ((select app_rls.is_admin()))
  with check ((select app_rls.is_admin()));
