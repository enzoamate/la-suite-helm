# Contribuer

Merci de contribuer à ces charts Helm.

## Préparer une modification

1. Créez une branche dédiée.
2. Modifiez un seul sujet cohérent par proposition.
3. Mettez à jour le README, `values.yaml`, `values.schema.json`, les exemples
   et `templates/NOTES.txt` lorsque l’interface du chart évolue.
4. N’ajoutez aucun secret, kubeconfig, domaine d’exploitation ou donnée
   personnelle. Les domaines d’exemple doivent appartenir à `example.com` ou
   `example.org`, et les adresses IP aux plages documentaires.
5. Ajoutez une entrée de provenance ou de licence lorsque du contenu amont
   est repris.

## Valider

Helm 3 est requis. `kubeconform` est recommandé.

```shell
./scripts/check-placeholders.sh
./scripts/validate.sh
```

Vérifiez aussi le rendu du profil concerné :

```shell
helm template test charts/meet \
  -f charts/meet/examples/values-minimal.yaml
```

Ne versionnez ni `Chart.lock`, ni paquet `.tgz`, ni répertoire
`charts/<nom>/charts/`.

## Versionner un chart

Toute modification du contenu rendu doit entraîner une mise à jour SemVer du
champ `version` de son `Chart.yaml`. Mettez `appVersion` à jour uniquement
lorsque la version de l’application change.

## Proposition de changement

Décrivez le besoin, les choix effectués, les impacts de mise à niveau et les
validations réalisées. Une modification incompatible doit fournir une
procédure de migration.
