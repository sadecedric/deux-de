# Administration dans l’application

Depuis le jeu, ouvrir le profil puis **Se connecter**. Un compte dont
`app_metadata.role` vaut `admin` dispose des onglets **Jeu** et **Admin**.
Le changement d’onglet conserve le jeu et son compte à rebours.

Fonctions disponibles : statistiques, recherche, liste des comptes, solde et
dernière connexion, création et modification, génération/réinitialisation du
mot de passe, durée d’accès, limite d’appareils, libération des appareils,
blocage et déblocage. Les crédits restent virtuels.

## Activation sur Supabase

1. Le compte `cedric` doit exister (email `cedric@underover7.local`), être actif
   et disposer d’une validité non expirée. S’il n’existe pas, le créer depuis
   le panneau web existant. Aucun mot de passe par défaut n’est ajouté.
2. Appliquer les migrations jusqu’à `0008_cedric_admin.sql` dans le projet
   Supabase. La migration 0008 attribue le rôle à ce compte existant et
   restreint les modifications des profils par les utilisateurs ordinaires.
3. Déployer la fonction mise à jour :

   ```sh
   supabase functions deploy admin-create-user --project-ref dffpbwuruipbvoujjltb
   ```

4. Installer/lancer la version mise à jour de l’application puis se connecter
   avec `cedric`. Si une session était déjà ouverte, se déconnecter puis se
   reconnecter pour récupérer le rôle.

Le serveur relit l’utilisateur depuis Supabase Auth à chaque appel et vérifie
son rôle, son statut et sa validité. Une simple modification du nom d’utilisateur
ou de `user_metadata` n’accorde aucun droit. Le secret du panneau web et la clé
service_role ne sont jamais ajoutés à l’application.

La libération des appareils supprime leurs enregistrements ; une session déjà
ouverte peut se réenregistrer lors du contrôle périodique. Utiliser le blocage
du compte pour refuser l’accès. La validité saisie dans l’éditeur repart de la
date d’enregistrement, comme dans le panneau web existant.
