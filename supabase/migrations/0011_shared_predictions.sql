-- À exécuter après 0010, dans le même projet Supabase que l'application.
-- Une prédiction par compte, commune au site et à l'application Android.
begin;

create table public.user_predictions (
  user_id uuid primary key references auth.users(id) on delete cascade,
  dice_1 smallint not null check (dice_1 between 1 and 6),
  dice_2 smallint not null check (dice_2 between 1 and 6),
  revision bigint not null default 0 check (revision >= 0),
  generated_at timestamptz not null default now()
);

alter table public.user_predictions enable row level security;
revoke all on public.user_predictions from anon, authenticated;
grant select on public.user_predictions to authenticated;

create policy predictions_read_own_active on public.user_predictions
  for select to authenticated using (
    user_id = (select auth.uid())
    and exists (
      select 1 from public.profiles p
      where p.id = (select auth.uid()) and p.is_active
        and (p.valid_until is null or p.valid_until > now())
    )
  );

create function public.prediction_state(
  p_device_id text,
  p_regenerate boolean default false
)
returns jsonb
language plpgsql
security definer
set search_path = public, pg_temp
as $$
declare
  v_user_id uuid := auth.uid();
  v_prediction public.user_predictions%rowtype;
begin
  -- Applique les mêmes comptes, expirations, blocages et limites d'appareils.
  perform public.register_device(p_device_id);

  insert into public.user_predictions(user_id, dice_1, dice_2)
  values (v_user_id, 1 + floor(random() * 6)::int, 1 + floor(random() * 6)::int)
  on conflict (user_id) do nothing;

  -- Sérialise les demandes simultanées du site et de l'application.
  select * into v_prediction from public.user_predictions
    where user_id = v_user_id for update;

  if p_regenerate then
    update public.user_predictions
    set dice_1 = 1 + floor(random() * 6)::int,
        dice_2 = 1 + floor(random() * 6)::int,
        revision = revision + 1,
        generated_at = clock_timestamp()
    where user_id = v_user_id
    returning * into v_prediction;
  end if;

  return to_jsonb(v_prediction);
end;
$$;

revoke all on function public.prediction_state(text, boolean) from public, anon;
grant execute on function public.prediction_state(text, boolean) to authenticated;

-- Nécessaire à la réception des changements sur les autres appareils.
do $$
begin
  if not exists (
    select 1 from pg_publication_tables
    where pubname = 'supabase_realtime' and schemaname = 'public'
      and tablename = 'user_predictions'
  ) then
    alter publication supabase_realtime add table public.user_predictions;
  end if;
end;
$$;

commit;
