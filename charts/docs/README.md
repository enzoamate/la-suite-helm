# Docs

Ce chart encapsule le chart Helm officiel `suitenumerique/docs` 6.0.4 et
épingle les quatre images applicatives à `v6.0.4`.

## Dépendances

PostgreSQL, Redis durable, un bucket S3 versionné et un fournisseur OIDC
sont requis. Docs utilise une base PostgreSQL séparée pour `yhub`.
Les services de données ne sont volontairement pas créés par ce chart.

## Secrets requis

Le Secret `docs-secrets` doit fournir `django-secret-key`,
`database-password`, `redis-url`, `celery-broker-url`, `s3-access-key`,
`s3-secret-key`, `oidc-client-secret`, `y-provider-api-key`,
`yhub-postgres-url` et `yhub-redis-url`.

Les clés RSA interservices sont fournies dans `docs-jwt-keys` sous
`private.pem` et `yhub-private.pem`. Le chart ne rend aucun Secret.

```shell
kubectl create secret generic docs-secrets           --from-literal=django-secret-key='…'           --from-literal=database-password='…'           --from-literal=redis-url='…'           --from-literal=celery-broker-url='…'           --from-literal=s3-access-key='…'           --from-literal=s3-secret-key='…'           --from-literal=oidc-client-secret='…'           --from-literal=y-provider-api-key='…'           --from-literal=yhub-postgres-url='…'           --from-literal=yhub-redis-url='…'
```

Générez les deux clés RSA hors du dépôt puis créez `docs-jwt-keys`.

## Installation

```shell
helm dependency build ./charts/docs
helm upgrade --install docs ./charts/docs -n docs --create-namespace           -f ./charts/docs/examples/values-minimal.yaml
```

Pour ProConnect, remplacez les cinq endpoints OIDC et l’identifiant client
de l’exemple par ceux de votre fournisseur.
