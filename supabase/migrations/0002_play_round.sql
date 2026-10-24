-- Under & Over 7 — logique de jeu atomique (Phase 13)
-- À exécuter dans Supabase Dashboard > SQL Editor, après 0001_init.sql.
--
-- Toute la partie (tirage, calcul du résultat, mise à jour du solde,
-- écriture de l'historique) se déroule dans une seule transaction
-- PostgreSQL : impossible d'avoir un solde débité sans partie enregistrée,
-- ou une partie enregistrée sans mise à jour du solde.
--
-- SECURITY DEFINER : la fonction s'exécute avec les droits du propriétaire
-- (contourne RLS) mais uniquement pour ce traitement précis et validé ;
-- le solde des dés/résultat/payout reste hors de portée du client.

create or replace function public.play_round(p_choice text, p_stake numeric)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_config record;
  v_wallet record;
  v_dice1 int;
  v_dice2 int;
  v_total int;
  v_result text;
  v_odds numeric;
  v_payout numeric;
  v_status text;
  v_game_id uuid;
  v_balance_before numeric;
  v_balance_after numeric;
begin
  if v_user_id is null then
    raise exception 'AUTH_REQUIRED';
  end if;

  if p_choice not in ('UNDER', 'EQUAL', 'OVER') then
    raise exception 'INVALID_CHOICE';
  end if;

  if p_stake is null or p_stake <= 0 then
    raise exception 'INVALID_STAKE';
  end if;

  select * into v_config from public.game_config where id = 1;
  if not found then
    raise exception 'CONFIG_MISSING';
  end if;

  if p_stake < v_config.min_stake or p_stake > v_config.max_stake then
    raise exception 'STAKE_OUT_OF_RANGE';
  end if;

  -- verrouille la ligne du portefeuille pour empêcher deux parties
  -- concurrentes de dépenser le même solde (race condition).
  select * into v_wallet
    from public.wallets
    where user_id = v_user_id
    for update;

  if not found then
    raise exception 'WALLET_NOT_FOUND';
  end if;

  if v_wallet.balance < p_stake then
    raise exception 'INSUFFICIENT_BALANCE';
  end if;

  v_dice1 := floor(random() * 6 + 1)::int;
  v_dice2 := floor(random() * 6 + 1)::int;
  v_total := v_dice1 + v_dice2;
  v_result := case
    when v_total > 7 then 'OVER'
    when v_total < 7 then 'UNDER'
    else 'EQUAL'
  end;

  v_odds := case p_choice
    when 'UNDER' then v_config.under_odds
    when 'EQUAL' then v_config.equal_odds
    else v_config.over_odds
  end;

  if v_result = p_choice then
    v_payout := round(p_stake * v_odds, 2);
    v_status := 'WON';
  else
    v_payout := 0;
    v_status := 'LOST';
  end if;

  v_balance_before := v_wallet.balance;
  v_balance_after := v_balance_before - p_stake + v_payout;

  update public.wallets
    set balance = v_balance_after, updated_at = now()
    where user_id = v_user_id;

  insert into public.games (user_id, dice_1, dice_2, total, result)
    values (v_user_id, v_dice1, v_dice2, v_total, v_result)
    returning id into v_game_id;

  insert into public.bets (
    game_id, user_id, choice, stake, odds, payout, status
  ) values (
    v_game_id, v_user_id, p_choice, p_stake, v_odds, v_payout, v_status
  );

  insert into public.wallet_transactions (
    user_id, type, amount, balance_before, balance_after, reference_id
  ) values (
    v_user_id, 'BET', -p_stake, v_balance_before,
    v_balance_before - p_stake, v_game_id
  );

  if v_payout > 0 then
    insert into public.wallet_transactions (
      user_id, type, amount, balance_before, balance_after, reference_id
    ) values (
      v_user_id, 'WIN', v_payout, v_balance_before - p_stake,
      v_balance_after, v_game_id
    );
  end if;

  return jsonb_build_object(
    'roundId', v_game_id,
    'dice1', v_dice1,
    'dice2', v_dice2,
    'total', v_total,
    'result', v_result,
    'choice', p_choice,
    'odds', v_odds,
    'stake', p_stake,
    'payout', v_payout,
    'status', v_status,
    'balance', v_balance_after
  );
end;
$$;

revoke all on function public.play_round(text, numeric) from public;
grant execute on function public.play_round(text, numeric) to authenticated;
