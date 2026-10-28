#!/usr/bin/env bash
set -Eeuo pipefail

command -v skopeo >/dev/null 2>&1 || {
  echo "Erreur : skopeo est requis pour vérifier les images OCI." >&2
  exit 1
}

images=(
  "docker://dxflrs/garage:v2.4.1|sha256:9c96caa2612d3411acc5b0e6701fb238dbfba33e533a6d7d3d811a4b12d0d020"
  "docker://zenko/cloudserver@sha256:b53e57829cf7df357323e60a19c9f98d2218f1b7ccb1d7cea5761a5a227a9ee3|sha256:b53e57829cf7df357323e60a19c9f98d2218f1b7ccb1d7cea5761a5a227a9ee3"
  "docker://clamav/clamav@sha256:a01a78acf14e356f9d95c0eeb640ac9fa48a98a59933dea877f5a4d01573a0eb|sha256:a01a78acf14e356f9d95c0eeb640ac9fa48a98a59933dea877f5a4d01573a0eb"
)

for entry in "${images[@]}"; do
  image="${entry%%|*}"
  expected_digest="${entry##*|}"
  echo "Vérification de ${image#docker://}"
  actual_digest="$(skopeo inspect --override-os linux --format '{{.Digest}}' "$image")"
  if [[ "$actual_digest" != "$expected_digest" ]]; then
    echo "Erreur : digest inattendu pour ${image#docker://}: ${actual_digest}" >&2
    exit 1
  fi
done

echo "${#images[@]} images OCI critiques vérifiées."
