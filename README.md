# Charts Helm de La Suite

Ce dépôt distribue trois charts Helm autonomes pour déployer des services de
La Suite sur Kubernetes. Les charts ne créent aucun Secret applicatif et leur
rendu ne nécessite pas d’accès réseau.

## Catalogue

| Chart | Application | Version du chart | Version applicative | Documentation |
| --- | --- | ---: | ---: | --- |
| `france-transfert` | France Transfert | 0.1.0 | 4.0.20 | [README](charts/france-transfert/README.md) |
| `meet` | Meet/Visio | 0.1.0 | 1.36.3 | [README](charts/meet/README.md) |
| `messages` | La Suite Messages | 0.1.0 | 0.10.0 | [README](charts/messages/README.md) |

## Prérequis

- Helm 3 ;
- Kubernetes 1.24 ou plus récent ;
- un Secret Kubernetes préparé pour chaque application ;
- un contrôleur Ingress ou une implémentation Gateway API si une route est
  créée ;
- les CRD des fonctions optionnelles activées, notamment CloudNativePG,
  cert-manager ou ExternalDNS.

Consultez [l’architecture](docs/architecture.md), la
[gestion des secrets](docs/secrets.md) et le
[guide d’exploitation](docs/operations.md) avant un déploiement.

## Installation locale

Choisissez un exemple, créez d’abord le Secret décrit dans le README du chart,
puis installez la release :

```shell
helm upgrade --install meet ./charts/meet \
  --namespace meet \
  --create-namespace \
  --wait --wait-for-jobs --timeout 15m \
  -f ./charts/meet/examples/values-minimal.yaml
```

Les exemples sont destinés au rendu et à l’adaptation. Ils ne contiennent
aucune valeur secrète utilisable.

## Installation depuis GHCR

Les releases sont publiées sous forme d’artefacts OCI dans
`oci://ghcr.io/enzoamate/charts` :

```shell
helm show chart oci://ghcr.io/enzoamate/charts/meet --version 0.1.0
helm upgrade --install meet oci://ghcr.io/enzoamate/charts/meet \
  --version 0.1.0 \
  --namespace meet \
  --create-namespace \
  --wait --wait-for-jobs --timeout 15m \
  -f values-meet.yaml
```

Remplacez `meet` par `messages` ou `france-transfert`. Pour un paquet privé,
exécutez au préalable `helm registry login ghcr.io`.

## Matrice des dépendances

| Chart | Composant | Mode embarqué | Mode externe |
| --- | --- | --- | --- |
| `meet` | PostgreSQL | instance simple | service PostgreSQL |
| `meet` | Redis | instance simple avec AOF | URL Redis/Celery |
| `meet` | LiveKit | instance simple et ports média directs | plateforme LiveKit |
| `messages` | PostgreSQL | cluster CloudNativePG | service PostgreSQL |
| `messages` | Redis | instance simple | service Redis |
| `messages` | OpenSearch | instance simple | service OpenSearch |
| `messages` | stockage S3 | serveur compatible S3 | service S3 |
| `france-transfert` | Redis | instance simple | service Redis |
| `france-transfert` | S3 | CloudServer compatible SigV2 | service compatible SigV2 |
| `france-transfert` | ClamAV | instance simple | service ClamAV |

Les modes embarqués privilégient une installation autonome. Sauf mention
contraire, ils ne fournissent ni haute disponibilité, ni sauvegarde, ni plan
de reprise.

## Avertissements de production

- Utilisez des services externes redondés ou des opérateurs correctement
  exploités pour les données persistantes.
- Chiffrez les communications, appliquez des NetworkPolicies adaptées et
  limitez l’accès aux ports exposés.
- Gérez les secrets hors Git et organisez leur rotation.
- Définissez les ressources, la topologie, les PodDisruptionBudgets et les
  politiques de sauvegarde selon vos objectifs de disponibilité.
- Testez les restaurations et les mises à niveau sur un environnement isolé.
- Vérifiez les licences, signatures et vulnérabilités des images avant usage.

## Validation

```shell
./scripts/check-placeholders.sh
./scripts/validate.sh
./scripts/check-images.sh
```

`validate.sh` exécute le lint strict et le rendu de chaque exemple. Si
`kubeconform` est installé, il valide également les ressources Kubernetes.
`check-placeholders.sh` requiert `ripgrep`. La CI installe une version épinglée
de `kubeconform` et rend la validation Kubernetes obligatoire.
`check-images.sh` utilise `skopeo` pour vérifier les images OCI critiques.

## Publication

Un tag Git `vX.Y.Z` déclenche le packaging des trois charts, leur publication
dans GHCR et la création d’une GitHub Release contenant les paquets `.tgz`.
Le numéro du tag doit être identique au champ `version` des trois
`Chart.yaml`.

Les contributions suivent [CONTRIBUTING.md](CONTRIBUTING.md). Les signalements
de sécurité suivent [SECURITY.md](SECURITY.md).
