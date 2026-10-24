-- Le compte administrateur ne doit pas expirer : il doit toujours pouvoir
-- accéder au panneau d'administration afin de gérer les comptes utilisateurs.
-- À appliquer après 0008_cedric_admin.sql.

update public.profiles as profile
set
  is_active = true,
  valid_until = null,
  updated_at = now()
from auth.users as account
where profile.id = account.id
  and lower(account.email) = 'cedric@underover7.local'
  and account.raw_app_meta_data ->> 'role' = 'admin';
