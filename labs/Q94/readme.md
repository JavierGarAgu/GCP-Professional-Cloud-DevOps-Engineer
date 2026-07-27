COMMANDS
```
gcloud container clusters get-credentials config-sync-cluster `
    --zone=europe-west1-b `
    --project=devops-cert-labs-v3

gcloud container fleet memberships register config-sync-cluster `
    --gke-cluster=europe-west1-b/config-sync-cluster `
    --enable-workload-identity `
    --project=devops-cert-labs-v3

gcloud beta container fleet config-management enable `
    --project=devops-cert-labs-v3

#AFTER CLOUDBUILD TRIGGER


```