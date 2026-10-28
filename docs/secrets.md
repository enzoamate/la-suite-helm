# Gestion des secrets

## Modèle

Les charts ne créent aucun Secret. La valeur `existingSecret` référence un
Secret déjà présent dans le namespace de la release. Créez-le avec votre
gestionnaire de secrets, External Secrets Operator, SOPS ou un mécanisme
équivalent. Ne conservez jamais sa valeur déchiffrée dans Git.

## Clés attendues

### Meet

Toujours requises : `DJANGO_SECRET_KEY`, `DB_PASSWORD`,
`LIVEKIT_API_KEY`, `LIVEKIT_API_SECRET`.

Selon les fonctions : `OIDC_RP_CLIENT_SECRET`,
`DJANGO_EMAIL_HOST_PASSWORD`, `AWS_S3_ACCESS_KEY_ID`,
`AWS_S3_SECRET_ACCESS_KEY`, `SUMMARY_SERVICE_API_TOKEN`,
`SUMMARY_SERVICE_WEBHOOK_API_TOKEN`.

### Messages

Toujours requises : `DJANGO_SECRET_KEY`, `SALT_KEY`, `DB_PASSWORD`.

Selon les fonctions : `OIDC_RP_CLIENT_SECRET`, `MTA_OUT_RELAY_PASSWORD`,
`MDA_API_SECRET`. Les quatre variables de stockage
`STORAGE_MESSAGE_{IMPORTS,BLOBS}_{ACCESS,SECRET}_KEY` sont alimentées depuis
les noms de clés configurés sous `secretKeys`; les valeurs par défaut
réutilisent `AWS_ACCESS_KEY_ID` et `AWS_SECRET_ACCESS_KEY`.
Garage embarqué exige en plus `GARAGE_RPC_SECRET` et `GARAGE_ADMIN_TOKEN`.
CloudNativePG attend en outre les clés `username` et `password` dans le
Secret indiqué par `postgresql.cnpg.bootstrapSecretName`.

### France Transfert

Requises : `METALOAD_PASSWORD`, `STORAGE_ACCESS_KEY`,
`STORAGE_SECRET_KEY`, `PASSWORD_SALT`, `SPRING_MAIL_USERNAME`,
`SPRING_MAIL_PASSWORD`, `HEALTHCHECK_SMTP_USER`,
`HEALTHCHECK_SMTP_PASSWORD`.

`HEALTHCHECK_API_KEY` est requise lorsque le point de contrôle privé est
utilisé.

### Docs

`docs-secrets` fournit les identifiants Django, PostgreSQL, Redis, S3, OIDC,
Yhub et le convertisseur. `docs-jwt-keys` contient les clés RSA
`private.pem` et `yhub-private.pem`.

### Fichiers

`fichiers-secrets` fournit les identifiants Django, PostgreSQL, Redis, S3 et
OIDC.

### Grist

`grist-secrets` contient au minimum `session-secret`, `database-password` et
`oidc-client-secret`. Redis et S3 ajoutent les clés documentées dans le README.

### Tchap

`tchap-secrets` contient la clé Matrix durable `signing.key` et
`secrets.yaml`, qui regroupe la connexion PostgreSQL, les secrets Synapse et la
configuration OIDC sensible. La perte de la clé de signature casse la confiance
de fédération du domaine.

## Exploitation

- Accordez au mécanisme de livraison le minimum de droits nécessaire.
- Chiffrez les secrets au repos et en transit.
- Faites tourner les identifiants selon une procédure testée.
- Redémarrez les workloads concernés après une rotation si l’application ne
  recharge pas les variables d’environnement.
- Contrôlez les journaux et manifests rendus avant partage.
- Révoquez immédiatement toute valeur publiée par erreur, même après sa
  suppression de l’historique.

Les noms de clés configurables sont documentés dans le README et
`values.yaml` de chaque chart.
