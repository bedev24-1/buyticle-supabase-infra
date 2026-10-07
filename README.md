# buyticle-supabase-infra

Supabase auto-hébergé (PostgREST, Storage, Studio) déployé avec Coolify.

## Sécurité

- **Aucun secret dans ce dépôt.** Ils sont définis dans Coolify (Environment Variables) :
  `POSTGRES_PASSWORD`, `SUPABASE_ADMIN_PASSWORD`, `AUTHENTICATOR_PASSWORD`,
  `JWT_SECRET`, `ANON_KEY`, `SERVICE_ROLE_KEY`.
  Pour en générer de nouveaux : `bash generer-secrets.sh` (sur le serveur).
- **Aucun port publié sur internet.** Docker contourne UFW : un port publié dans
  `docker-compose.yml` serait ouvert au monde entier. `rest` et `storage` passent par
  les domaines Coolify (HTTPS).
- **Studio n'est pas exposé.** Il n'écoute que sur `127.0.0.1:3011`. Pour l'ouvrir depuis
  ton PC : `ssh -L 3011:127.0.0.1:3011 root@IP_DU_VPS`, puis http://localhost:3011
- **L'API anonyme n'a plus les droits super-utilisateur.** PostgREST se connecte avec le
  rôle limité `authenticator` et utilise le rôle `anon` (avant : `postgres`, ce qui
  permettait d'exécuter des commandes sur le serveur).

## Étape suivante conseillée

Activer la sécurité ligne par ligne (RLS) sur les tables du schéma `public` et
définir des règles d'accès, puis retirer les `GRANT ALL` donnés à `anon` dans `init.sh`.
