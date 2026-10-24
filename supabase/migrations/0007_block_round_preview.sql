-- Un compte bloqué ou expiré ne doit plus voir le résultat du prochain tour.
-- À exécuter dans Supabase > SQL Editor, après 0006.
--
-- 0006 bloquait la création de nouveaux tirages et les parties, mais
-- get_or_create_next_round() renvoyait encore un tirage déjà généré avant le
-- blocage. On ajoute ici la vérification d'accès au début de la fonction
-- (corps identique à 0004, seule la vérification est ajoutée).

create or replace function public.get_or_create_next_round()
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_user_id uuid := auth.uid();
  v_profile record;
  v_round record;
  v_dice1 int;
  v_dice2 int;
  v_total int;
  v_result text;
  v_previous_result text;
begin
  if v_user_id is null then raise exception 'AUTH_REQUIRED'; end if;

  select is_active, valid_until into v_profile
    from public.profiles
    where id = v_user_id;
  if not found then raise exception 'PROFILE_NOT_FOUND'; end if;
  if not v_profile.is_active then raise exception 'ACCOUNT_DISABLED'; end if;
  if v_profile.valid_until is not null and v_profile.valid_until < now() then
    raise exception 'ACCOUNT_EXPIRED';
  end if;

  select * into v_round from public.pending_rounds where user_id = v_user_id;
  if not found then
    select result into v_previous_result
      from public.games
      where user_id = v_user_id
      order by created_at desc
      limit 1;

    -- Une catégorie ne peut pas apparaître deux tours de suite.
    loop
      v_dice1 := floor(random() * 6 + 1)::int;
      v_dice2 := floor(random() * 6 + 1)::int;
      v_total := v_dice1 + v_dice2;
      v_result := case when v_total > 7 then 'OVER' when v_total < 7 then 'UNDER' else 'EQUAL' end;
      exit when v_previous_result is null or v_result <> v_previous_result;
    end loop;

    insert into public.pending_rounds (user_id, dice_1, dice_2, total, result)
    values (v_user_id, v_dice1, v_dice2, v_total, v_result)
    on conflict (user_id) do nothing;

    select * into v_round from public.pending_rounds where user_id = v_user_id;
  end if;

  return jsonb_build_object(
    'dice1', v_round.dice_1,
    'dice2', v_round.dice_2,
    'total', v_round.total,
    'result', v_round.result
  );
end;
$$;

revoke all on function public.get_or_create_next_round() from public;
grant execute on function public.get_or_create_next_round() to authenticated;
