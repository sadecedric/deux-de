-- L'administrateur doit pouvoir se reconnecter après une réinstallation de
-- l'application ou un changement de téléphone. Cette migration supprime les
-- anciennes empreintes d'appareils de cedric et applique la limite maximale.
-- À appliquer après 0009_admin_unlimited_access.sql.

update public.profiles as profile
set
  max_devices = 100,
  updated_at = now()
from auth.users as account
where profile.id = account.id
  and lower(account.email) = 'cedric@underover7.local'
  and account.raw_app_meta_data ->> 'role' = 'admin';

delete from public.user_devices as device
using auth.users as account
where device.user_id = account.id
  and lower(account.email) = 'cedric@underover7.local'
  and account.raw_app_meta_data ->> 'role' = 'admin';
