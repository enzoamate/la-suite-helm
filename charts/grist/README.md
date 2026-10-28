# Grist

Ce chart déploie Grist Core 1.7.21 avec PostgreSQL externe, OIDC générique,
Redis et stockage S3 optionnels. L’image est épinglée par digest.

## Secret requis

`grist-secrets` contient `session-secret`, `database-password`,
`oidc-client-secret`, et, selon les options, `redis-url`, `s3-access-key`
et `s3-secret-key`. Le chart ne rend aucun Secret.

```shell
kubectl create secret generic grist-secrets           --from-literal=session-secret='…'           --from-literal=database-password='…'           --from-literal=oidc-client-secret='…'           --from-literal=redis-url='…'           --from-literal=s3-access-key='…'           --from-literal=s3-secret-key='…'
```

Le bucket S3 doit avoir le versionnement activé.

```shell
helm upgrade --install grist ./charts/grist -n grist --create-namespace           -f ./charts/grist/examples/values-minimal.yaml
```

L’édition Core est libre. Les fonctions de l’édition commerciale Grist
ne sont pas activées par ce chart.
