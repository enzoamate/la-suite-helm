# Fichiers

Ce chart encapsule le chart officiel `suitenumerique/drive` 0.25.0 et
épingle les images backend et frontend à `v0.25.0`.

## Dépendances

PostgreSQL, Redis durable, un stockage S3 et un fournisseur OIDC sont
requis. OnlyOffice/WOPI reste optionnel et doit être exploité séparément.

## Secrets requis

`fichiers-secrets` doit contenir `django-secret-key`,
`database-password`, `redis-url`, `celery-broker-url`, `s3-access-key`,
`s3-secret-key` et `oidc-client-secret`. Aucun Secret n’est rendu.

```shell
kubectl create secret generic fichiers-secrets           --from-literal=django-secret-key='…'           --from-literal=database-password='…'           --from-literal=redis-url='…'           --from-literal=celery-broker-url='…'           --from-literal=s3-access-key='…'           --from-literal=s3-secret-key='…'           --from-literal=oidc-client-secret='…'
```

## Installation

```shell
helm dependency build ./charts/fichiers
helm upgrade --install fichiers ./charts/fichiers -n fichiers           --create-namespace -f ./charts/fichiers/examples/values-minimal.yaml
```

Pour activer WOPI, remplacez la commande neutre
`upstream.backend.configureWopi.command` et fournissez les variables
attendues par l’instance OnlyOffice.
