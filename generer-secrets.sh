#!/usr/bin/env bash
# Génère de NOUVEAUX secrets pour Supabase, à coller dans les variables
# d'environnement de l'application "buyticle-supabase-infra" dans Coolify.
# Rien n'est écrit sur le disque : les valeurs s'affichent seulement à l'écran.
set -euo pipefail

b64url() { openssl base64 -A | tr '+/' '-_' | tr -d '='; }
jwt() { # $1 = rôle, $2 = secret
  local now exp h p s
  now=$(date +%s); exp=$((now + 10*365*24*3600))
  h=$(printf '{"alg":"HS256","typ":"JWT"}' | b64url)
  p=$(printf '{"role":"%s","iss":"supabase","iat":%s,"exp":%s}' "$1" "$now" "$exp" | b64url)
  s=$(printf '%s.%s' "$h" "$p" | openssl dgst -sha256 -hmac "$2" -binary | b64url)
  printf '%s.%s.%s' "$h" "$p" "$s"
}

JWT_SECRET=$(openssl rand -hex 32)
echo "===== A coller dans Coolify > buyticle-supabase-infra > Environment Variables ====="
echo "POSTGRES_PASSWORD=$(openssl rand -hex 24)"
echo "SUPABASE_ADMIN_PASSWORD=$(openssl rand -hex 24)"
echo "AUTHENTICATOR_PASSWORD=$(openssl rand -hex 24)"
echo "JWT_SECRET=$JWT_SECRET"
echo "ANON_KEY=$(jwt anon "$JWT_SECRET")"
echo "SERVICE_ROLE_KEY=$(jwt service_role "$JWT_SECRET")"
echo "==================================================================================="
echo "Garde aussi une copie dans ton Coffre 2FA (notes) : ces valeurs ne seront plus affichées."
echo "ANON_KEY et SERVICE_ROLE_KEY remplacent aussi les anciennes clés dans tes autres applications."
