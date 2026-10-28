# Tchap

Ce chart fournit une base self-hosted monodomaine composée du client Web
officiel Tchap 4.21.10 et du fork Synapse Tchap 1.161.0.

Il ne reproduit pas l’infrastructure nationale Tchap : le multidomaine,
Sydent, les passerelles de bord, les modules de politique spécifiques,
le push mobile et le dépôt média distribué restent à exploiter séparément.

## PostgreSQL, SSO et secrets

Un PostgreSQL externe est obligatoire. Le Secret `tchap-secrets` contient :

- `signing.key`, clé de signature Matrix durable ;
- `secrets.yaml`, seconde configuration Synapse avec la base et OIDC.

Exemple de structure à préparer hors Git :

```yaml
database:
  name: psycopg2
  args:
    host: postgres.example.com
    port: 5432
    database: tchap
    user: tchap
    password: <VALEUR_SECRETE>
    sslmode: require
macaroon_secret_key: <VALEUR_SECRETE>
form_secret: <VALEUR_SECRETE>
        password_config:
          enabled: false
oidc_providers:
  - idp_id: proconnect
    idp_name: ProConnect
    issuer: https://sso.example.com
    client_id: tchap
    client_secret: <VALEUR_SECRETE>
    scopes: [openid, profile, email]
            allow_existing_users: true
    user_mapping_provider:
      config:
        localpart_template: "{{ user.email.split('@')[0] }}"
        display_name_template: "{{ user.name }}"
```

Créez ensuite le Secret :

```shell
kubectl create secret generic tchap-secrets           --from-file=secrets.yaml           --from-file=signing.key
```

Aucun Secret n’est rendu par Helm.

```shell
helm upgrade --install tchap ./charts/tchap -n tchap --create-namespace           -f ./charts/tchap/examples/values-minimal.yaml
```

Conservez impérativement `signing.key` pendant toute la vie du domaine.
