# Chart Helm France Transfert

Ce chart déploie France Transfert 4.0.20 avec ses quatre composants applicatifs : interface, API de téléversement, API de téléchargement et worker.

Redis, ClamAV et un stockage S3 CloudServer peuvent être déployés par le chart ou remplacés par des services externes.

## Prérequis

- Kubernetes avec Helm 3 ;
- un nom DNS pour l'application ;
- un Secret Kubernetes créé avant l'installation ;
- un Ingress Controller ou une implémentation Gateway API si l'exposition HTTP est activée.

## Secret existant

Le chart ne génère aucun Secret. `existingSecret` est obligatoire et doit référencer un Secret du namespace de la release.

Clés attendues :

- `METALOAD_PASSWORD` : mot de passe Redis, obligatoire ;
- `STORAGE_ACCESS_KEY` : identifiant S3, obligatoire ;
- `STORAGE_SECRET_KEY` : clé secrète S3, obligatoire ;
- `PASSWORD_SALT` : sel de chiffrement applicatif, obligatoire ;
- `SPRING_MAIL_USERNAME` : utilisateur SMTP, obligatoire mais peut être vide si l'authentification SMTP est désactivée ;
- `SPRING_MAIL_PASSWORD` : mot de passe SMTP, obligatoire mais peut être vide si l'authentification SMTP est désactivée ;
- `HEALTHCHECK_SMTP_USER` : utilisateur du contrôle SMTP, obligatoire mais peut être vide si ce contrôle est désactivé ;
- `HEALTHCHECK_SMTP_PASSWORD` : mot de passe du contrôle SMTP, obligatoire mais peut être vide si ce contrôle est désactivé ;
- `HEALTHCHECK_API_KEY` : clé du point de contrôle privé, requise si ce point est utilisé.

Exemple de création, sans inscrire les valeurs dans un fichier du chart :

```shell
kubectl create secret generic france-transfert-secrets \
  --from-literal=METALOAD_PASSWORD='…' \
  --from-literal=STORAGE_ACCESS_KEY='…' \
  --from-literal=STORAGE_SECRET_KEY='…' \
  --from-literal=PASSWORD_SALT='…' \
  --from-literal=SPRING_MAIL_USERNAME='' \
  --from-literal=SPRING_MAIL_PASSWORD='' \
  --from-literal=HEALTHCHECK_SMTP_USER='' \
  --from-literal=HEALTHCHECK_SMTP_PASSWORD=''
```

## Installation

Le schéma impose des valeurs non vides pour `host` et `existingSecret`.

```shell
helm upgrade --install france-transfert ./charts/france-transfert \
  --namespace france-transfert \
  --create-namespace \
  --wait --wait-for-jobs --timeout 15m \
  -f ./charts/france-transfert/examples/values-minimal.yaml
```

Les exemples sont fournis dans `examples/values-minimal.yaml` et `examples/values-production.yaml`. Ils n'incluent aucune donnée secrète.

## Stockage S3 et SigV2

France Transfert 4.0.20 force `S3SignerType` dans son client AWS, donc la signature S3 version 2. Un service S3 externe doit impérativement accepter SigV2 ; une compatibilité S3 limitée à SigV4 ne suffit pas.

Quand `s3.embedded.enabled=true`, le chart déploie exclusivement CloudServer, choisi pour sa compatibilité SigV2. L'image vérifiée est épinglée par digest dans `values.yaml` ; son tag reste informatif. ClamAV suit la même politique. CloudServer n'est jamais créé lorsque le stockage embarqué est désactivé.

Pour un stockage externe :

```yaml
s3:
  embedded:
    enabled: false
  external:
    endpoint: https://objects.example.org
```

Les identifiants restent lus depuis `existingSecret`.

## Redis et ClamAV

Chaque service peut être embarqué ou externe :

```yaml
redis:
  embedded:
    enabled: false
  external:
    host: redis.example.org
    port: 6379

clamav:
  embedded:
    enabled: false
  external:
    host: clamav.example.org
    port: 3310
```

Les images, ressources, probes, contextes de sécurité, classes de stockage et tailles de volumes des services embarqués sont configurables dans `values.yaml`.

## OIDC et SMTP

OIDC est contrôlé par `oidc.enabled`, `oidc.issuerUrl`, `oidc.clientId` et `oidc.resourceServerIssuerUrl`.

SMTP est contrôlé par `smtp.enabled`, `smtp.host`, `smtp.port`, `smtp.from`, `smtp.auth`, `smtp.ssl`, `smtp.startTls` et `smtp.healthcheck`. Les identifiants SMTP ne doivent être placés que dans `existingSecret`.

## Exposition HTTP

`routing.type` accepte :

- `ingress` pour un Ingress Kubernetes ;
- `gateway` pour une ressource HTTPRoute Gateway API ;
- `none` pour ne créer aucune route.

En mode Gateway API, `routing.gateway.parentRefs` est obligatoire. ExternalDNS est activable avec `routing.externalDNS.enabled`.

La ressource NGINX Gateway Fabric `ClientSettingsPolicy` est optionnelle :

```yaml
routing:
  type: gateway
  gateway:
    clientSettingsPolicy:
      enabled: true
      apiVersion: gateway.nginx.org/v1alpha1
      maxBodySize: 200m
```

Le point S3 embarqué peut être exposé séparément avec `s3.expose.enabled=true` et `s3.expose.host`. Il n'est pas exposable par le chart lorsque S3 est externe.

## Initialisation

Deux jobs Helm post-install/post-upgrade sont disponibles :

- création des buckets S3 absents avec `head-bucket` puis `create-bucket` ;
- création de la clé Redis `config` avec `SETNX`.

Ces opérations sont idempotentes et ne remplacent pas les données existantes. Elles peuvent être désactivées séparément avec `initialize.s3.enabled` et `initialize.redis.enabled`, notamment lorsque les services externes sont administrés séparément.

Les attentes sont bornées par `initialize.retry`, les délais réseau par
`initialize.timeouts`, et la durée globale de chaque Job par
`initialize.activeDeadlineSeconds`.

## Paramétrage des pods

Les images, ressources, probes, contextes de sécurité et volumes temporaires sont configurables par composant dans `front`, `upload`, `download` et `worker`.

Le volume de travail persistant du worker est `ReadWriteOnce` par défaut :
conservez `worker.replicas=1`. Plusieurs répliques ne sont sûres qu'avec une
classe et un mode d'accès `ReadWriteMany` explicitement provisionnés et testés.

Le ServiceAccount applicatif et celui des jobs d'initialisation peuvent être créés par le chart ou fournis avec `serviceAccount.name` et `initialize.serviceAccount.name`.

## Test

Le test Helm vérifie les connexions HTTP internes vers l'interface et les endpoints de santé des deux API :

```shell
helm test france-transfert -n france-transfert
```

## Licence

Le chart conserve l'attribution et la licence Apache 2.0 du projet France Transfert. Voir `NOTICE` et `LICENSES/Apache-2.0.txt`.
