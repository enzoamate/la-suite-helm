# Chart Helm Meet/Visio

Ce chart déploie Meet 1.36.3 avec son frontend, son backend Django, les
migrations et le worker Celery essentiel. Il est autonome : il ne référence
aucun sous-chart et son rendu ne nécessite aucun accès réseau.

## Provenance et licence

Le chart adapte le chart officiel `numerique-gouv/meet` 0.0.29 de la release
`v1.36.3`. La provenance détaillée est indiquée dans `NOTICE`; la licence MIT
amont est conservée dans `LICENSE` et `LICENSES/MIT.txt`. Les images restent
soumises à leurs licences respectives.

## Prérequis

- Kubernetes 1.24 ou plus récent et Helm 3 ;
- un contrôleur Ingress, ou une implémentation Gateway API, sauf avec
  `routing.type=none` ;
- les noms DNS de l'application et, pour LiveKit embarqué, de la
  signalisation ;
- un Secret créé avant l'installation.

Les propriétés `domain` et `existingSecret` sont obligatoires dans
`values.schema.json`. `livekit.host` est en plus obligatoire lorsque LiveKit
est embarqué.

## Secrets

Le chart ne crée aucun objet `Secret` et aucune valeur sensible n'est fournie.
`existingSecret` doit contenir les clés suivantes :

- `DJANGO_SECRET_KEY`, `DB_PASSWORD`, `LIVEKIT_API_KEY` et
  `LIVEKIT_API_SECRET` dans tous les modes ;
- `OIDC_RP_CLIENT_SECRET` lorsque `oidc.enabled=true` ;
- `DJANGO_EMAIL_HOST_PASSWORD` lorsque `smtp.enabled=true` ;
- `AWS_S3_ACCESS_KEY_ID` et `AWS_S3_SECRET_ACCESS_KEY` lorsque
  `media.enabled=true` ;
- `SUMMARY_SERVICE_API_TOKEN` et `SUMMARY_SERVICE_WEBHOOK_API_TOKEN` lorsque
  `advanced.summary.enabled=true`.

Les noms de ces clés sont modifiables sous `secretKeys`. `DB_PASSWORD` est
également utilisé par PostgreSQL embarqué.

Exemple sans aucune valeur réelle :

```shell
kubectl create secret generic meet-secrets \
  --from-literal=DJANGO_SECRET_KEY='…' \
  --from-literal=DB_PASSWORD='…' \
  --from-literal=LIVEKIT_API_KEY='…' \
  --from-literal=LIVEKIT_API_SECRET='…'
```

## PostgreSQL et Redis

`postgresql.mode` accepte `embedded` ou `external`. Le mode embarqué déploie
une instance PostgreSQL simple, avec PVC optionnel et `storageClass`
configurable. Il convient aux essais et aux petites installations ; en
production, préférez un service géré, un opérateur avec sauvegardes, ou un
PostgreSQL externe redondé.

`redis.mode` accepte aussi `embedded` ou `external`. Le Redis embarqué est une
instance unique avec AOF et PVC optionnel. En mode externe, configurez
`redis.external.url` et, si nécessaire, une URL distincte pour Celery.

Le chart ne fournit pas de sauvegarde. Sauvegardez PostgreSQL et le stockage
média, et testez régulièrement la restauration.

## LiveKit

Avec `livekit.mode=external`, renseignez `livekit.external.endpoint` avec
l'URL HTTPS publique du service. La clé et le secret restent dans
`existingSecret`.

Avec `livekit.mode=embedded`, le chart déploie une instance LiveKit simple,
sans dépendance Helm distante. Ce mode utilise un port UDP multiplexé et un
port TCP de secours, configurables sous `livekit.embedded.service` :

- TCP 7880 par défaut pour HTTP et WebSocket, publié par Ingress ou
  `HTTPRoute` ;
- TCP 7881 par défaut pour le transport média de secours ;
- UDP 7882 par défaut pour le transport média principal.

Le Service LiveKit est de type `LoadBalancer` par défaut. Il peut être changé
en `NodePort` ou `ClusterIP`, avec annotations, politique de trafic et adresse
de LoadBalancer configurables. Les ports média TCP et UDP ne traversent ni
Ingress ni `HTTPRoute` : publiez-les directement et autorisez-les dans les
pare-feu. Le DNS `livekit.host` doit résoudre vers la terminaison HTTPS pour
la signalisation ; l'adresse annoncée pour les médias doit être joignable.
`rtc.nodeIP` permet de forcer cette adresse lorsque la détection externe ne
convient pas.

Le mode embarqué est mono-réplique et vise une installation simple. Pour la
haute disponibilité, le TURN, la topologie multi-région ou l'autoscaling,
utilisez une plateforme LiveKit dédiée.

## OIDC, SMTP et médias

OIDC est générique et désactivé par défaut. Lorsque `oidc.enabled=true`, les
endpoints d'autorisation, de jeton, de profil, de clés et de déconnexion ainsi
que le client ID deviennent obligatoires. Le secret client n'est jamais placé
dans les valeurs. Pour une installation sans OIDC, contrôlez
`application.allowUnregisteredRooms`.

SMTP est activé avec `smtp.enabled=true`. L'hôte, le port, l'expéditeur, TLS
et SSL sont configurables ; le mot de passe reste dans `existingSecret`.

Le stockage média compatible S3 est activé avec `media.enabled=true`.
L'endpoint interne, l'endpoint public facultatif, le bucket, la région et la
version de signature sont configurables. Les identifiants restent dans le
Secret existant. Le chart ne crée pas le bucket.

## Routage

`routing.type` accepte `ingress`, `gateway` ou `none`.

Le routage applicatif envoie `/api/`, `/external-api/` et `/admin/` au
backend, et le reste au frontend. En mode LiveKit embarqué, une route séparée
est créée sur `livekit.host`; elle transporte aussi la mise à niveau
WebSocket. Vérifiez que votre contrôleur autorise les connexions longues.

Gateway API exige au moins un élément dans `routing.gateway.parentRefs`. Le
chart crée des `HTTPRoute` standards et ne crée ni `Gateway` ni certificat.
Ingress permet de régler la classe, les annotations et les Secrets TLS de
l'application et de LiveKit.

## Ressources et sécurité

Les images, ressources, probes et contextes de sécurité sont configurables
pour les composants applicatifs et les services embarqués. Les PVC
PostgreSQL et Redis acceptent un `storageClass`, une taille et des modes
d'accès. Les sélecteurs de nœuds, tolérances et affinités sont disponibles
pour les composants exposés à la charge.

Les comptes de service n'obtiennent pas de jeton par défaut. Les conteneurs
abandonnent leurs capabilities et refusent l'élévation de privilèges. Adaptez
les UID, le système de fichiers en lecture seule et les limites aux politiques
de votre cluster et aux images choisies.

## Fonctions avancées

L'enregistrement, la transcription et le résumé sont désactivés par défaut.
Le chart ne déploie pas les services lourds associés.

- `advanced.recording.enabled` expose la fonction d'enregistrement du
  backend, mais exige un stockage média et une infrastructure d'enregistrement
  LiveKit séparée ;
- `advanced.transcription.enabled` publie la destination configurée, mais
  exige un service de transcription externe ;
- `advanced.summary.enabled` configure un service de résumé externe et exige
  son endpoint ainsi que ses jetons API et webhook dans `existingSecret`.

N'activez ces options qu'après avoir déployé, dimensionné et sécurisé leurs
dépendances.

## Installation

Installation minimale avec services embarqués :

```shell
helm upgrade --install meet ./charts/meet \
  --namespace meet \
  --create-namespace \
  --wait --wait-for-jobs --timeout 15m \
  -f ./charts/meet/examples/values-minimal.yaml
```

Installation de production avec dépendances externes et Ingress :

```shell
helm upgrade --install meet ./charts/meet \
  --namespace meet \
  --create-namespace \
  --wait --wait-for-jobs --timeout 15m \
  -f ./charts/meet/examples/values-production.yaml
```

Les exemples utilisent exclusivement des domaines réservés à la
documentation et ne contiennent ni clé, ni mot de passe, ni adresse
d'exploitation.

Les migrations sont exécutées comme hook pré-upgrade. Au premier déploiement,
un Job ordinaire attend la base et les initContainers du backend et de Celery
bloquent le trafic tant que le schéma n'est pas à jour. Utilisez
obligatoirement `--wait --wait-for-jobs --timeout` pour bloquer la livraison
en cas d'échec.

Toutes les images acceptent un `digest` optionnel. En production, épinglez un
digest `sha256:` vérifié ; le tag reste alors informatif.

## Validation et test

Le chart se valide hors ligne :

```shell
helm lint --strict ./charts/meet
helm template meet ./charts/meet \
  -f ./charts/meet/examples/values-minimal.yaml
```

Après déploiement, le test Helm vérifie le frontend et le heartbeat du
backend :

```shell
helm test meet -n meet
```
