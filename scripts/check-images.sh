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
  "docker://lasuite/impress-backend:v6.0.4|sha256:3a2bdf2fa7b7b4462fbeaefc339e9121047227e46d8f85adf6bbc8701ecbb394"
  "docker://lasuite/impress-frontend:v6.0.4|sha256:611c6fe647de5975b9c85fa3500188ad49c74c208e32a6470e221f90d1506a31"
  "docker://lasuite/impress-y-provider:v6.0.4|sha256:a82bae1b787351356f094f836cc733a49e692aa60c47d1861562601d00dc8d59"
  "docker://lasuite/impress-yhub:v6.0.4|sha256:c8f7f4486922804c5a3a8f09c5c9312cddfd1af4053c87cad0dd739e454245fb"
  "docker://lasuite/drive-backend:v0.25.0|sha256:666dd2978b8650e6c753c1a4b2da4252146df525c279435a0bb4fa261bc92c0b"
  "docker://lasuite/drive-frontend:v0.25.0|sha256:3c6143930c9a3295121b8fa4d3af87001100b40004d3a2ffcad23a643cd9adc2"
  "docker://gristlabs/grist:1.7.21|sha256:577918affbc446f77382b6049c06226488a086a3ea52c2661154b1252d5ff873"
  "docker://ghcr.io/tchapgouv/tchap-web-v4:tchap-4.21.10|sha256:9d6b165ee3ffff4e79dfe541c3d5963bb1a1d5288022877f585a3d4b196996bc"
  "docker://ghcr.io/tchapgouv/synapse:tchap-v1.161.0-0.0.1|sha256:e1dce9ad93a07b5e55a2e0c1e99ee89b9e3e6b31f1a91c70727a330c21fa475a"
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
