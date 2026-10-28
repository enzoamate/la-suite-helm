# Exploitation

## Avant installation

1. Vérifiez les versions de Kubernetes, Helm et des CRD optionnelles.
2. Rendez le chart avec les valeurs de l’environnement.
3. Contrôlez les images, ressources, volumes, politiques réseau et contextes
   de sécurité.
4. Créez les Secrets, certificats, buckets et bases externes nécessaires.
5. Préparez les enregistrements DNS et les règles de pare-feu.

## Mise à niveau

Sauvegardez les données, lisez les changements applicatifs, puis comparez le
rendu avant d’appliquer :

```shell
helm lint --strict charts/meet -f values-meet.yaml
helm template meet charts/meet -f values-meet.yaml > rendered.yaml
helm upgrade --install meet charts/meet \
  --namespace meet \
  -f values-meet.yaml \
  --atomic \
  --wait \
  --wait-for-jobs \
  --timeout 15m
```

`--wait --wait-for-jobs --timeout` est obligatoire pour les trois charts :
les migrations et initialisations doivent terminer avant que la livraison
soit considérée réussie. Meet et Messages exécutent les migrations en
pré-upgrade ; au premier déploiement, leurs Jobs ordinaires attendent les
services nécessaires et les workloads applicatifs bloquent leur démarrage
tant que le schéma n'est pas à jour.

Les migrations de mise à jour doivent rester compatibles avec la version
applicative encore en service pendant le hook pré-upgrade. Si une migration
est destructive, prévoyez une fenêtre de maintenance et interrompez le trafic.
N'effectuez pas de retour arrière applicatif sans vérifier la compatibilité du
schéma de données.

## Contrôles

Après déploiement :

```shell
helm status meet -n meet
helm test meet -n meet
kubectl get pods,svc,pvc -n meet
```

Surveillez au minimum la disponibilité, les redémarrages, les erreurs HTTP,
les files de tâches, la saturation CPU/mémoire/disque, la latence des
dépendances et l’expiration des certificats.

## Sauvegarde et restauration

- Meet : PostgreSQL, stockage média et configuration externe.
- Messages : PostgreSQL et buckets S3 ; documentez la reconstruction de Redis
  et OpenSearch.
- France Transfert : stockage S3, Redis et volumes de travail nécessaires.

Définissez des objectifs de perte de données et de reprise, conservez des
copies isolées, puis testez régulièrement une restauration complète.

## Incidents

Conservez les événements Kubernetes, journaux applicatifs et versions de
chart sans y inclure de secret. En cas de compromission, isolez le service,
révoquez les identifiants, restaurez depuis une source vérifiée et documentez
les actions. Suivez `SECURITY.md` pour un signalement privé.
