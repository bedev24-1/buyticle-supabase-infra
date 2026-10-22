#!/bin/bash
# Exécuté UNE seule fois, à la création du volume de la base.
# Les mots de passe viennent des variables d'environnement du conteneur db.
set -euo pipefail
: "${SUPABASE_ADMIN_PASSWORD:?SUPABASE_ADMIN_PASSWORD manquant}"
: "${AUTHENTICATOR_PASSWORD:?AUTHENTICATOR_PASSWORD manquant}"

psql -v ON_ERROR_STOP=1 --username "$POSTGRES_USER" --dbname "$POSTGRES_DB" \
     -v admin_pw="$SUPABASE_ADMIN_PASSWORD" -v auth_pw="$AUTHENTICATOR_PASSWORD" <<'EOSQL'
-- Rôle utilisé par le service storage
SELECT 'CREATE ROLE supabase_admin LOGIN SUPERUSER BYPASSRLS'
WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'supabase_admin') \gexec
ALTER ROLE supabase_admin WITH PASSWORD :'admin_pw';

-- Rôles d'API : PAS de super-utilisateur, PAS de contournement RLS pour anon/authenticated
SELECT 'CREATE ROLE anon NOLOGIN' WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'anon') \gexec
SELECT 'CREATE ROLE authenticated NOLOGIN' WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'authenticated') \gexec
SELECT 'CREATE ROLE service_role NOLOGIN BYPASSRLS' WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'service_role') \gexec

-- PostgREST se connecte avec ce rôle limité, puis prend anon / authenticated / service_role
SELECT 'CREATE ROLE authenticator LOGIN NOINHERIT' WHERE NOT EXISTS (SELECT FROM pg_roles WHERE rolname = 'authenticator') \gexec
ALTER ROLE authenticator WITH PASSWORD :'auth_pw';
GRANT anon, authenticated, service_role TO authenticator;

-- Schéma public : SEUL service_role (clé serveur) y a accès.
-- anon / authenticated n'ont AUCUN droit : la clé anon est publique (elle est dans
-- le code des sites), lui donner accès aux tables exposerait toutes les données.
-- Pour ouvrir une table au public, le faire table par table avec RLS + règle.
GRANT USAGE ON SCHEMA public TO anon, authenticated, service_role;
GRANT ALL ON ALL TABLES IN SCHEMA public TO service_role;
GRANT ALL ON ALL SEQUENCES IN SCHEMA public TO service_role;
GRANT EXECUTE ON ALL FUNCTIONS IN SCHEMA public TO service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON TABLES TO service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT ALL ON SEQUENCES TO service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public GRANT EXECUTE ON FUNCTIONS TO service_role;
ALTER DEFAULT PRIVILEGES IN SCHEMA public REVOKE EXECUTE ON FUNCTIONS FROM PUBLIC;

GRANT ALL ON DATABASE postgres TO supabase_admin;
EOSQL
