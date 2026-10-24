-- Under & Over 7 — schéma initial (Phase 11-12)
-- À exécuter dans Supabase Dashboard > SQL Editor.
-- Argent entièrement virtuel : aucune donnée de paiement réel n'est stockée.

-- =========================================================================
-- 1. TABLES
-- =========================================================================

create table if not exists public.profiles (
  id uuid primary key references auth.users (id) on delete cascade,
  username text,
  avatar_url text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.wallets (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null unique references auth.users (id) on delete cascade,
  balance numeric(14, 2) not null default 0,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create table if not exists public.games (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  dice_1 smallint not null check (dice_1 between 1 and 6),
  dice_2 smallint not null check (dice_2 between 1 and 6),
  total smallint not null check (total between 2 and 12),
  result text not null check (result in ('UNDER', 'EQUAL', 'OVER')),
  created_at timestamptz not null default now()
);

create table if not exists public.bets (
  id uuid primary key default gen_random_uuid(),
  game_id uuid not null references public.games (id) on delete cascade,
  user_id uuid not null references auth.users (id) on delete cascade,
  choice text not null check (choice in ('UNDER', 'EQUAL', 'OVER')),
  stake numeric(14, 2) not null check (stake > 0),
  odds numeric(6, 2) not null check (odds > 0),
  payout numeric(14, 2) not null default 0,
  status text not null check (status in ('WON', 'LOST')),
  created_at timestamptz not null default now()
);

create table if not exists public.wallet_transactions (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references auth.users (id) on delete cascade,
  type text not null check (
    type in ('INITIAL_CREDIT', 'VIRTUAL_DEPOSIT', 'BET', 'WIN', 'REFUND')
  ),
  amount numeric(14, 2) not null,
  balance_before numeric(14, 2) not null,
  balance_after numeric(14, 2) not null,
  reference_id uuid,
  created_at timestamptz not null default now()
);

create table if not exists public.game_config (
  id smallint primary key default 1 check (id = 1),
  under_odds numeric(6, 2) not null default 2.3,
  equal_odds numeric(6, 2) not null default 5.8,
  over_odds numeric(6, 2) not null default 2.3,
  min_stake numeric(14, 2) not null default 100,
  max_stake numeric(14, 2) not null default 50000,
  updated_at timestamptz not null default now()
);

insert into public.game_config (id)
values (1)
on conflict (id) do nothing;

create index if not exists games_user_id_idx on public.games (user_id);
create index if not exists bets_user_id_idx on public.bets (user_id);
create index if not exists bets_game_id_idx on public.bets (game_id);
create index if not exists wallet_transactions_user_id_idx
  on public.wallet_transactions (user_id);

-- =========================================================================
-- 2. ROW LEVEL SECURITY
-- =========================================================================

alter table public.profiles enable row level security;
alter table public.wallets enable row level security;
alter table public.games enable row level security;
alter table public.bets enable row level security;
alter table public.wallet_transactions enable row level security;
alter table public.game_config enable row level security;

-- profils : chacun voit/édite uniquement le sien (nom, avatar — rien de sensible)
create policy "profiles_select_own" on public.profiles
  for select using (auth.uid() = id);

create policy "profiles_update_own" on public.profiles
  for update using (auth.uid() = id) with check (auth.uid() = id);

-- portefeuille : lecture seule côté client. Le solde n'est jamais modifiable
-- directement (INSERT/UPDATE/DELETE réservés au service_role / fonctions
-- serveur — voir Edge Function `play-game` en Phase 13).
create policy "wallets_select_own" on public.wallets
  for select using (auth.uid() = user_id);

-- parties et mises : lecture seule, écrites uniquement par le serveur.
create policy "games_select_own" on public.games
  for select using (auth.uid() = user_id);

create policy "bets_select_own" on public.bets
  for select using (auth.uid() = user_id);

-- historique des transactions : lecture seule.
create policy "wallet_transactions_select_own" on public.wallet_transactions
  for select using (auth.uid() = user_id);

-- configuration du jeu : lisible par tout utilisateur authentifié,
-- modifiable uniquement par le service_role (admin, Phase 15-16).
create policy "game_config_select_authenticated" on public.game_config
  for select using (auth.role() = 'authenticated');

-- =========================================================================
-- 3. PROVISIONING AUTOMATIQUE (profil + portefeuille à l'inscription)
-- =========================================================================

create or replace function public.handle_new_user()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
begin
  insert into public.profiles (id, username)
  values (new.id, 'Joueur-' || substr(new.id::text, 1, 8));

  insert into public.wallets (user_id, balance)
  values (new.id, 1000000);

  insert into public.wallet_transactions (
    user_id, type, amount, balance_before, balance_after
  )
  values (new.id, 'INITIAL_CREDIT', 1000000, 0, 1000000);

  return new;
end;
$$;

drop trigger if exists on_auth_user_created on auth.users;

create trigger on_auth_user_created
  after insert on auth.users
  for each row execute function public.handle_new_user();
