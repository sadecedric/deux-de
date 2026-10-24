# Prédicteur web lié à l'application

La version navigateur ouvre uniquement la connexion et le prédicteur. Elle utilise
le même projet Supabase, les mêmes comptes créés par l'administrateur, leurs
dates d'expiration et leurs blocages. Android conserve l'application complète.

## 1. Préparer Supabase

Dans le SQL Editor du projet déjà utilisé par l'application, exécuter une fois :

`supabase/migrations/0011_shared_predictions.sql`

Les migrations 0001 à 0010 doivent déjà être appliquées. Cette migration ajoute
la table `user_predictions`, sa protection par compte, la fonction
`prediction_state` et son abonnement à Supabase Realtime.

Aucune clé `service_role` n'est nécessaire sur le site ou dans Vercel. La clé
publique existante est utilisée ; les droits sont contrôlés côté Supabase.

Le navigateur est un appareil distinct de l'application Android. Pour utiliser
les deux simultanément avec le même compte, régler sa limite à au moins deux
appareils depuis l'administration. Le navigateur conserve son identifiant entre
les visites ; changer de navigateur, effacer ses données ou changer de domaine
peut créer un nouvel appareil. Utiliser le domaine de production Vercel pour
éviter de multiplier les appareils avec les URL de prévisualisation.

## 2. Déployer sur Vercel

Importer le dépôt dans Vercel et conserver sa racine comme Root Directory.
Choisir le preset **Other** si Vercel en demande un. Le fichier `vercel.json`
configure déjà :

- commande de build : `bash tool/build_vercel.sh` ;
- dossier publié : `build/web`.

Le script installe Flutter 3.47.1 si nécessaire, récupère les dépendances et
compile le prédicteur. Une variable optionnelle `FLUTTER_VERSION` permet de
changer de SDK lors d'une future mise à jour. Aucun serveur Node.js n'est requis.

Sans dépôt Git, il est aussi possible de déployer depuis la racine du projet
avec la CLI Vercel (Node.js requis sur votre ordinateur) :

```powershell
npx vercel
```

Se connecter à son compte Vercel lorsque la CLI le demande. Après vérification
de la prévisualisation, publier la production avec `npx vercel --prod`.
Le fichier `.vercelignore` évite d'envoyer les anciennes compilations et les
répertoires natifs inutiles au build web.

Pour compiler localement sous PowerShell :

```powershell
flutter build web --release --dart-define=PREDICTOR_ONLY=true
```

Pour tester dans Chrome avant publication :

```powershell
flutter run -d chrome --dart-define=PREDICTOR_ONLY=true
```

Le site se connecte à Supabase par HTTPS et WebSocket. Le nom de domaine Vercel
n'est pas codé dans l'application. La connexion par identifiant et mot de passe
ne nécessite pas d'OAuth ni de lien de redirection.

## 3. Mettre l'application à jour

Après la migration, reconstruire et distribuer l'application contenant ces
changements :

```powershell
flutter build apk --release
```

Les anciennes APK continuent à générer leurs prédictions localement : elles ne
peuvent pas recevoir les prédictions du site. Il faut donc installer la nouvelle
version sur les appareils à synchroniser.

## Fonctionnement commun

1. Se connecter avec le même identifiant sur le site et dans l'application.
2. Appuyer sur **Prédire** sur l'un des deux : le serveur enregistre une nouvelle
   prédiction et incrémente son numéro, même si le résultat est identique.
3. L'autre appareil reçoit le même résultat par Realtime. En quittant puis en
   rouvrant le prédicteur, le numéro est conservé.
4. Avant un lancer, l'application relit la dernière prédiction sur le serveur.
   Si la lecture échoue, aucune mise n'est débitée. Il n'y a pas de génération
   locale de secours pour les comptes connectés.

La source est propre à chaque compte : deux utilisateurs différents n'ont pas
nécessairement la même recommandation. Le résultat d'un lancer correspond à la
prédiction lue au moment où ce lancer commence ; une prédiction demandée ensuite
sur un autre appareil prépare le lancer suivant. Les soldes virtuels et
l'historique existants restent stockés par appareil ; cette livraison synchronise
les comptes d'accès et les prédictions.

## Vérification après installation et publication

- Ouvrir le site sur iPhone ou ordinateur, puis se connecter avec un compte autorisé.
- Ouvrir l'APK mise à jour avec ce même compte.
- Demander une prédiction sur le site et comparer le numéro et le symbole dans
  le prédicteur de l'APK, puis faire l'essai dans l'autre sens.
- Vérifier que le prochain lancer utilise ce résultat.
- Vérifier qu'un compte bloqué ou expiré ne peut plus demander de prédiction.
- Couper le réseau : une demande doit afficher une erreur et un lancer ne doit
  pas débiter de mise. Rétablir le réseau et réessayer.

La migration doit être appliquée et ces vérifications avec deux sessions réelles
doivent être faites sur votre projet avant de distribuer cette version.

Références : [configuration Vercel](https://vercel.com/docs/project-configuration/vercel-json),
[flux Supabase Flutter](https://supabase.com/docs/reference/dart/stream).
