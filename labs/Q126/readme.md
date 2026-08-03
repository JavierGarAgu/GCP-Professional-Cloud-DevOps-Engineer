COMMANDS
```
gcloud compute ssh oversized-vm --zone=europe-west1-b
#inside the machine
stress-ng --cpu 2 --timeout 600
gcloud recommender recommendations list --project=devops-cert-labs-v4 --location=europe-west1-b --recommender=google.compute.instance.MachineTypeRecommender
```