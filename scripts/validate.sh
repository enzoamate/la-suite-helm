#!/usr/bin/env bash
set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
KUBERNETES_VERSION="${KUBERNETES_VERSION:-1.29.0}"
REQUIRE_KUBECONFORM="${REQUIRE_KUBECONFORM:-false}"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

export HELM_REPOSITORY_CONFIG="$TMP_DIR/repositories.yaml"
export HELM_REPOSITORY_CACHE="$TMP_DIR/repository-cache"

command -v helm >/dev/null 2>&1 || {
  echo "Erreur : Helm 3 est requis." >&2
  exit 1
}

helm repo add suite-docs https://suitenumerique.github.io/docs/ >/dev/null
helm repo add suite-drive https://suitenumerique.github.io/drive/ >/dev/null

if command -v jq >/dev/null 2>&1; then
  while IFS= read -r schema; do
    jq empty "$schema"
  done < <(find "$ROOT_DIR/charts" -name values.schema.json -type f -print)
fi

kubeconform_available=false
if command -v kubeconform >/dev/null 2>&1; then
  kubeconform_available=true
elif [[ "$REQUIRE_KUBECONFORM" == "true" ]]; then
  echo "Erreur : kubeconform est requis dans cet environnement." >&2
  exit 1
else
  echo "Information : kubeconform absent, validation Kubernetes ignorée." >&2
fi

validated=0
for chart in "$ROOT_DIR"/charts/*; do
  [[ -f "$chart/Chart.yaml" ]] || continue
  chart_name="$(basename "$chart")"

  if [[ -f "$chart/Chart.lock" ]]; then
    helm dependency build --skip-refresh "$chart"
  fi

  for values in "$chart"/examples/*.yaml; do
    [[ -f "$values" ]] || continue
    profile_name="$(basename "$values" .yaml)"
    output="$TMP_DIR/${chart_name}-${profile_name}.yaml"

    echo "Validation de ${chart_name}/${profile_name}"
    helm lint --strict "$chart" -f "$values"
    helm template validation "$chart" \
      --namespace validation \
      -f "$values" >"$output"

    if awk '$0 ~ /^kind:[[:space:]]+Secret[[:space:]]*$/ { found=1 } END { exit !found }' "$output"; then
      echo "Erreur : ${chart_name}/${profile_name} rend un Secret Kubernetes." >&2
      exit 1
    fi

    if [[ "$kubeconform_available" == "true" ]]; then
      kubeconform \
        -strict \
        -summary \
        -ignore-missing-schemas \
        -kubernetes-version "$KUBERNETES_VERSION" \
        "$output"
    fi
    validated=$((validated + 1))
  done
done

if [[ "$validated" -eq 0 ]]; then
  echo "Erreur : aucun exemple n’a été trouvé." >&2
  exit 1
fi

echo "$validated profils validés."
