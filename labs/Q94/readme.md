COMMANDS
```
# Conectar al clúster
gcloud container clusters get-credentials config-sync-cluster `
    --zone=europe-west1-b `
    --project=devops-cert-labs-v4

# Comprobar nodos
kubectl get nodes

# Ver RootSync
kubectl get rootsync -A

# Estado detallado del RootSync
kubectl describe rootsync root-sync -n config-management-system

# Ver los pods de Config Sync
kubectl get pods -n config-management-system

# Ver deployments de Config Sync
kubectl get deployments -n config-management-system

# Ver NetworkPolicies
kubectl get networkpolicy -A

# Ver DaemonSets
kubectl get daemonset -A

# Ver eventos recientes
kubectl get events -A --sort-by=.lastTimestamp

# Ver consumo del nodo
kubectl describe node

# Si el reconciler existe, ver sus logs
kubectl logs -n config-management-system deployment/root-reconciler

# Si el deployment no está disponible, listar pods
kubectl get pods -n config-management-system -o wide
```