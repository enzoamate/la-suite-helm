# Chart Helm La Suite Messages

Ce chart déploie La Suite Messages 0.10.0 : backend Django, worker Celery, frontend, migration et, facultativement, MTA de réception. Il ne crée aucun Secret et ne contient aucune donnée d'exploitation réelle.

## Prérequis

- Kubernetes et Helm 3 ;
- un nom DNS pour l'interface web ;
- un Secret applicatif existant dans le namespace de la release ;
- un contrôleur Ingress ou une implémentation Gateway API selon `routing.type` ;
- CloudNativePG uniquement si `postgresql.mode=cnpg` ;
- les CRD correspondantes uniquement si cert-manager, ExternalDNS, MetalLB, Antrea ou la politique NGINX sont activés.

En mode externe, le chart ne dépend d'aucun opérateur Kubernetes.

## DNS et messagerie

Le nom `host` sert au webmail. `technicalDomain` est le domaine utilisé par la messagerie. Avec le MTA entrant, `mta.hostname` doit avoir un enregistrement A (et AAAA si nécessaire) vers l'adresse du LoadBalancer. Le domaine technique doit publier un MX vers ce nom.

Le port TCP 25 doit être joignable depuis Internet pour recevoir les messages. Le port 587 est normalement utilisé pour le relais SMTP sortant et doit être autorisé entre le backend et le relais. Configurez le rDNS/PTR de l'adresse d'envoi auprès du fournisseur d'adresse ; un enregistrement DNS direct ne remplace pas le rDNS.

`dns.enabled` peut créer un `DNSEndpoint` ExternalDNS. Les enregistrements MX, SPF et DKIM sont indépendamment activables. Le chart ne fournit aucune clé DKIM ni adresse IP par défaut.

## Secrets

`existingSecret` est obligatoire. Le chart n'en génère aucun. Le Secret applicatif doit fournir, selon les fonctions activées :

- `DJANGO_SECRET_KEY` et `SALT_KEY` ;
- `DB_PASSWORD` pour PostgreSQL ;
- `OIDC_RP_CLIENT_SECRET` avec OIDC ;
- `MTA_OUT_RELAY_PASSWORD` avec le relais SMTP ;
- `MDA_API_SECRET` avec le MTA entrant ;
- les quatre clés référencées par `secretKeys.s3ImportsAccessKey`,
  `secretKeys.s3ImportsSecretKey`, `secretKeys.s3BlobsAccessKey` et
  `secretKeys.s3BlobsSecretKey` pour les deux stockages applicatifs ;
- `GARAGE_RPC_SECRET` et `GARAGE_ADMIN_TOKEN` lorsque Garage est embarqué.

Tous ces noms sont ajustables dans `secretKeys`. Les mêmes identifiants
peuvent être référencés pour imports et blobs, mais les quatre variables
`STORAGE_MESSAGE_{IMPORTS,BLOBS}_{ACCESS,SECRET}_KEY` sont toujours injectées
explicitement dans le backend, le worker et la migration.

`GARAGE_RPC_SECRET` doit être une valeur hexadécimale aléatoire de 64
caractères partagée uniquement par les nœuds Garage. Utilisez aussi un jeton
aléatoire distinct et robuste pour `GARAGE_ADMIN_TOKEN`.

En mode CNPG, `postgresql.cnpg.bootstrapSecretName` référence un Secret distinct ou partagé contenant les clés `username` et `password` attendues par CloudNativePG. Le nom d'utilisateur doit correspondre à `postgresql.user`.

Exemple de création volontairement sans valeurs :

```shell
kubectl create secret generic messages-secrets \
  --from-literal=DJANGO_SECRET_KEY='…' \
  --from-literal=SALT_KEY='…' \
  --from-literal=DB_PASSWORD='…' \
  --from-literal=OIDC_RP_CLIENT_SECRET='…' \
  --from-literal=MTA_OUT_RELAY_PASSWORD='…' \
  --from-literal=MDA_API_SECRET='…' \
  --from-literal=AWS_ACCESS_KEY_ID='…' \
  --from-literal=AWS_SECRET_ACCESS_KEY='…' \
  --from-literal=GARAGE_RPC_SECRET='…' \
  --from-literal=GARAGE_ADMIN_TOKEN='…'
```

## Dépendances

PostgreSQL accepte `cnpg` ou `external`. Redis, OpenSearch et S3 acceptent `embedded` ou `external`. En mode externe, `values.schema.json` impose les hôtes, URL, base et utilisateur nécessaires.

Le S3 embarqué est Garage 2.4.1 à instance unique, exposé en interne sur le
port 3900 avec un PVC et des probes. Le Job `garage-init` configure
idempotemment le layout, importe les identifiants existants et crée les
buckets `s3.imports.bucket` et `s3.blobs.bucket`. Il utilise un compte de
service limité à la lecture des pods Garage et à `pods/exec`.

Pour un service S3 externe, créez les buckets à l'avance. Les endpoints
d'imports et de blobs sont configurables séparément ; celui des imports doit
être publiquement utilisable si le navigateur reçoit des URL présignées.

## OIDC et relais SMTP

Avec `oidc.enabled=true`, renseignez les cinq endpoints OpenID Connect et le client ID. Le secret client reste exclusivement dans `existingSecret`. Les URI de redirection autorisées chez le fournisseur doivent inclure le domaine `host`.

Avec `smtp.enabled=true`, renseignez l'hôte, le port, l'utilisateur et le niveau TLS du relais. Le mot de passe reste dans `existingSecret`.

## Routage HTTP

`routing.type` vaut `ingress`, `gateway` ou `none`. Gateway API exige au moins un `parentRef`. La ressource NGINX Gateway Fabric `ClientSettingsPolicy` est optionnelle via `routing.gateway.nginxPolicy.enabled`.

## Réception SMTP et réseau

`mta.enabled=true` crée le MTA et un Service configurable, de type `LoadBalancer` par défaut. `mta.service.loadBalancerIP` est facultatif. Un certificat TLS existant peut être monté, ou créé par cert-manager avec `certificate.enabled=true`.

Les ressources `IPAddressPool` et `L2Advertisement` MetalLB sont désactivées par défaut. Elles ne sont rendues que par `network.metallb.enabled`; aucune interface physique n'est présélectionnée. L'Egress Antrea est lui aussi désactivé par défaut et exige un pool externe et une adresse explicites.

## Installation

```shell
helm upgrade --install messages ./charts/messages \
  --namespace messages \
  --create-namespace \
  --wait --wait-for-jobs --timeout 15m \
  -f ./charts/messages/examples/values-minimal.yaml
```

`examples/values-minimal.yaml` illustre les services embarqués sans MTA. `examples/values-production.yaml` illustre des dépendances externes avec Ingress. Ces exemples ne contiennent aucun secret, aucune clé et aucune adresse d'exploitation.

Les migrations sont des Jobs bornés : hook pré-upgrade lors d'une mise à
jour, ou Job ordinaire au premier déploiement. À l'installation, les
initContainers du backend et du worker bloquent le trafic tant que le schéma
n'est pas à jour. Utilisez obligatoirement `--wait --wait-for-jobs --timeout`
afin qu'un échec bloque la livraison.

Toutes les images acceptent `digest`. En production, renseignez un digest
`sha256:` vérifié ; le tag reste alors uniquement informatif.

## Sauvegardes

Sauvegardez PostgreSQL, les deux buckets S3 et les volumes persistants avant toute mise à jour. En CNPG, configurez les sauvegardes objet et testez la restauration avec les mécanismes de l'opérateur. En mode externe, utilisez les sauvegardes natives du fournisseur. Redis et OpenSearch sont reconstructibles seulement si les traitements et index peuvent être rejoués ; documentez ce choix et testez un plan de reprise.

## Test

Le test Helm vérifie la connexion interne au frontend et au heartbeat du backend :

```shell
helm test messages -n messages
```

## Licence

Le chart est distribué sous licence MIT. La Suite Messages est un projet amont sous licence MIT. Voir `NOTICE` et `LICENSES/MIT.txt`. Les images référencées restent soumises à leurs licences respectives.
