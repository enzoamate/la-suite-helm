# Architecture

## Principes

Chaque répertoire sous `charts/` est un chart Helm installable. Docs et
Fichiers encapsulent leurs charts officiels, verrouillés dans `Chart.lock` et
embarqués dans le paquet publié. Aucun accès réseau n’est nécessaire au rendu.
Les autres dépendances applicatives sont rendues directement par les templates
ou référencées comme services externes.

Les valeurs non sensibles produisent des ConfigMaps, Deployments,
StatefulSets, Services, jobs d’initialisation et ressources de routage. Les
identifiants sont toujours lus depuis un Secret Kubernetes existant.

## Meet

Meet déploie un frontend, un backend Django, un worker Celery et un job de
migration. PostgreSQL, Redis et LiveKit peuvent être embarqués ou externes.
Le trafic HTTP passe par Ingress, HTTPRoute ou reste interne. En mode LiveKit
embarqué, les ports média TCP et UDP sont publiés directement par le Service :
ils ne traversent pas la route HTTP.

## Messages

Messages déploie un frontend, un backend Django, un worker Celery et un hook
de migration. PostgreSQL est fourni par CloudNativePG ou par un service
externe. Redis, OpenSearch et le stockage compatible S3 disposent de modes
embarqué et externe. Le mode S3 embarqué utilise Garage, initialisé par un Job
idempotent avec un RBAC limité aux pods Garage. Le MTA entrant est optionnel
et expose un port SMTP distinct du routage HTTP.

## France Transfert

France Transfert déploie le frontend, les API de téléversement et de
téléchargement, ainsi qu’un worker. Redis, ClamAV et CloudServer peuvent être
embarqués. Le stockage externe doit prendre en charge la signature S3 SigV2,
requise par la version applicative distribuée.

## Docs

Docs utilise le chart officiel et déploie le frontend, Django/Celery, le
convertisseur et le serveur collaboratif Yhub. PostgreSQL, Redis et S3 sont
externes. Yhub possède sa propre base PostgreSQL et son Redis doit être durable,
sans politique d’éviction.

## Fichiers

Fichiers encapsule le chart officiel Drive. Il déploie le frontend,
Django/Celery et les tâches planifiées. PostgreSQL, Redis et S3 sont externes.
L’édition en ligne via WOPI/OnlyOffice est optionnelle.

## Grist

Grist est déployé en instance unique avec stockage persistant, PostgreSQL
externe, OIDC et, en option, Redis et un bucket S3 versionné.

## Tchap

Le chart Tchap associe le client Web officiel et le fork Synapse de Tchap dans
une architecture monodomaine. PostgreSQL et les secrets de configuration
Synapse sont externes. Cette base self-hosted ne reproduit pas les composants
multidomaines de l’infrastructure nationale Tchap.

## Routage

Meet, Messages et France Transfert acceptent `ingress`, `gateway` ou `none`.
Les quatre autres charts utilisent Ingress. Le mode Gateway API crée des
`HTTPRoute`, mais ni `Gateway`, ni certificat. Les ressources propres à un
contrôleur ou à un opérateur sont désactivées par défaut et nécessitent leurs
CRD lorsqu’elles sont activées.

## Limites

Les services embarqués sont conçus pour l’évaluation ou les installations
simples. Ils ne constituent pas, à eux seuls, une architecture hautement
disponible. Les charts ne gèrent ni sauvegardes, ni restauration, ni rotation
des secrets, ni supervision externe.
