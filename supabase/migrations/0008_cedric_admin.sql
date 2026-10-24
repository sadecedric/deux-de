-- Le rôle est conservé dans app_metadata, modifiable uniquement côté serveur.
-- Le compte cedric doit déjà avoir été créé via le panneau d'administration.
do $$
begin
  if not exists (select 1 from auth.users where lower(email) = 'cedric@underover7.local') then
    raise exception 'Créez le compte cedric avant d’appliquer cette migration.';
  end if;
  update auth.users
  set raw_app_meta_data = coalesce(raw_app_meta_data, '{}'::jsonb) || '{"role":"admin"}'::jsonb
  where lower(email) = 'cedric@underover7.local';
end;
$$;

-- Les utilisateurs ne peuvent pas prolonger leur accès ou se débloquer.
revoke update on public.profiles from authenticated, anon;
grant update (username, avatar_url) on public.profiles to authenticated;
