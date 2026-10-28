#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$ROOT_DIR"

command -v rg >/dev/null 2>&1 || {
  echo "Erreur : ripgrep (rg) est requis." >&2
  exit 1
}

failed=false

check_pattern() {
  local description="$1"
  local pattern="$2"
  local status=0
  rg --hidden \
    --glob '!.git/**' \
    --glob '!scripts/check-placeholders.sh' \
    --glob '!LICENSES/**' \
    -- "$pattern" . || status=$?

  if [[ "$status" -eq 0 ]]; then
    echo "Erreur : $description" >&2
    failed=true
  elif [[ "$status" -ne 1 ]]; then
    echo "Erreur : le contrôle de contenu n’a pas pu s’exécuter." >&2
    exit "$status"
  fi
}

check_pattern \
  "domaine d’exemple non autorisé (utiliser example.com ou example.org)" \
  '([[:alnum:]-]+\.)+example\.(net|edu|gov|io|dev)|([[:alnum:]-]+\.)+internal\b'

check_pattern \
  "adresse IPv4 privée détectée (utiliser une plage documentaire)" \
  '\b(10\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}|192\.168\.[0-9]{1,3}\.[0-9]{1,3}|172\.(1[6-9]|2[0-9]|3[01])\.[0-9]{1,3}\.[0-9]{1,3})(/[0-9]{1,2})?\b'

check_pattern \
  "marqueur de secret ou de kubeconfig détecté" \
  '-----BEGIN (RSA |EC |OPENSSH )?PRIVATE KEY-----|client-certificate-data:|client-key-data:'

check_pattern \
  "valeur factice ambiguë détectée" \
  '(?i)\b(changeme|change-me|replace-me|replace_this|your-password|your-secret|your-token)\b'

if [[ "$failed" == "true" ]]; then
  exit 1
fi

echo "Contrôle des contenus documentaires réussi."
