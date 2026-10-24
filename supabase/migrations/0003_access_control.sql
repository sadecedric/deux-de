-- Under & Over 7 — contrôle d'accès : comptes créés par l'admin uniquement,
-- limite d'appareils, durée de validité (anti-partage de l'APK).
-- À exécuter dans Supabase Dashboard > SQL Editor, après 0001 et 0002.

-- =========================================================================
-- 1. EXTENSION DE profiles
-- =========================================================================

alter table public.profiles
  add column if not exists max_devices smallint not null default 1,
  add column if not exists valid_until timestamptz,
  add column if not exists is_active boolean not null default true;

-- =========================================================================
-- 2. APPAREILS ENREGISTRÉS
-- =========================================================================

create table if not exists public.user_devices (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  device_id text not null,
  first_seen_at timestamptz not null default now(),
  last_seen_at timestamptz not null default now(),
  unique (user_id, device_id)
);

alter table public.user_devices enable row level security;

create policy "user_devices_select_own" on public.user_devices
  for select using (auth.uid() = user_id);

-- =========================================================================
-- 3. handle_new_user : accepte max_devices / validity_days depuis les
--    métadonnées passées par l'Edge Function admin-create-user.
-- =========================================================================

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_max_devices smallint := coalesce(
    (new.raw_user_meta_data ->> 'max_devices')::smallint, 1
  );
  v_validity_days int := coalesce(
    (new.raw_user_meta_data ->> 'validity_days')::int, 30
  );
  v_username text := coalesce(
    new.raw_user_meta_data ->> 'username',
    'Joueur-' || substr(new.id::text, 1, 8)
  );
begin
  insert into public.profiles (id, username, max_devices, valid_until)
  values (
    new.id,
    v_username,
    v_max_devices,
    now() + (v_validity_days || ' days')::interval
  );

  insert into public.wallets (user_id, balance)
  values (new.id, 1000000);

  insert into public.wallet_transactions (
    user_id, type, amount, balance_before, balance_after
  )
  values (new.id, 'INITIAL_CREDIT', 1000000, 0, 1000000);

  return new;
end;
$$;

-- =========================================================================
-- 4. register_device : appelée à chaque connexion. Vérifie expiration,
--    statut actif, et applique la limite d'appareils. Tout est décidé
--    côté serveur — le client ne peut ni prolonger sa validité ni
--    contourner la limite d'appareils.
-- =========================================================================

create or replace function public.register_device(p_device_id text)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_profile record;
  v_device_count int;
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  if p_device_id is null or length(trim(p_device_id)) = 0 then
    raise exception 'INVALID_DEVICE_ID';
  end if;

  select * into v_profile from public.profiles where id = v_user_id;
  if not found then
    raise exception 'PROFILE_NOT_FOUND';
  end if;

  if not v_profile.is_active then
    raise exception 'ACCOUNT_DISABLED';
  end if;

  if v_profile.valid_until is not null and v_profile.valid_until < now() then
    raise exception 'ACCOUNT_EXPIRED';
  end if;

  if exists (
    select 1 from public.user_devices
    where user_id = v_user_id and device_id = p_device_id
  ) then
    update public.user_devices
      set last_seen_at = now()
      where user_id = v_user_id and device_id = p_device_id;
  else
    select count(*) into v_device_count
      from public.user_devices
      where user_id = v_user_id;

    if v_device_count >= v_profile.max_devices then
      raise exception 'DEVICE_LIMIT_REACHED';
    end if;

    insert into public.user_devices (user_id, device_id)
      values (v_user_id, p_device_id);
  end if;

  return jsonb_build_object(
    'ok', true,
    'validUntil', v_profile.valid_until,
    'maxDevices', v_profile.max_devices
  );
end;
$$;

revoke all on function public.register_device(text) from public;
grant execute on function public.register_device(text) to authenticated;
