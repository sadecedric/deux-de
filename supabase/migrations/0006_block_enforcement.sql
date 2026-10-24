-- Blocage effectif des comptes désactivés ou expirés.
-- À exécuter dans Supabase > SQL Editor, après 0005.
--
-- Avant cette migration, is_active / valid_until n'étaient vérifiés qu'à la
-- connexion (register_device) : un joueur bloqué qui avait déjà l'app ouverte
-- pouvait continuer à jouer. Ces triggers refusent toute nouvelle partie
-- (tirage annoncé ou mise) pour un compte bloqué ou expiré, quelle que soit
-- la fonction appelée. L'exception annule toute la transaction : le solde
-- n'est jamais débité.

create or replace function public.enforce_active_account()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_profile record;
begin
  select is_active, valid_until into v_profile
    from public.profiles
    where id = new.user_id;

  if not found then
    raise exception 'PROFILE_NOT_FOUND';
  end if;

  if not v_profile.is_active then
    raise exception 'ACCOUNT_DISABLED';
  end if;

  if v_profile.valid_until is not null and v_profile.valid_until < now() then
    raise exception 'ACCOUNT_EXPIRED';
  end if;

  return new;
end;
$$;

drop trigger if exists games_enforce_active_account on public.games;
create trigger games_enforce_active_account
  before insert on public.games
  for each row execute function public.enforce_active_account();

drop trigger if exists pending_rounds_enforce_active_account on public.pending_rounds;
create trigger pending_rounds_enforce_active_account
  before insert on public.pending_rounds
  for each row execute function public.enforce_active_account();
