# Architecture

## Principes

Chaque répertoire sous `charts/` est un chart Helm autonome. Aucun chart ne
télécharge de sous-chart au rendu. Les dépendances applicatives sont soit
rendues directement par les templates, soit référencées comme services
externes.

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

## Routage

Les trois charts acceptent `ingress`, `gateway` ou `none`. Le mode Gateway
API crée des `HTTPRoute`, mais ni `Gateway`, ni certificat. Les ressources
propres à un contrôleur ou à un opérateur sont désactivées par défaut et
nécessitent leurs CRD lorsqu’elles sont activées.

## Limites

Les services embarqués sont conçus pour l’évaluation ou les installations
simples. Ils ne constituent pas, à eux seuls, une architecture hautement
disponible. Les charts ne gèrent ni sauvegardes, ni restauration, ni rotation
des secrets, ni supervision externe.
