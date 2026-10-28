# Politique de sécurité

Ne publiez jamais de mot de passe, jeton, clé privée, kubeconfig ou fichier de
valeurs contenant des secrets.

Les charts attendent des Secrets Kubernetes existants. Utilisez un gestionnaire
de secrets, SOPS ou External Secrets Operator pour les fournir.

Pour signaler une vulnérabilité, utilisez les avis de sécurité privés du dépôt
GitHub plutôt qu'une issue publique.
