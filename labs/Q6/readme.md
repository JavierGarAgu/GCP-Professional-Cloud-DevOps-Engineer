create repo JavierGarAgu/cloudbuild-webhook-lab

https://console.cloud.google.com/cloud-build/triggers?project=devops-cert-labs

![](../../doc/images/17.PNG)

![](../../doc/images/18.PNG)

![](../../doc/images/19.PNG)

![](../../doc/images/20.PNG)

![](../../doc/images/21.PNG)

![](../../doc/images/22.PNG)

![](../../doc/images/23.PNG)

for now is implemented with B response, but is not the correct

gcloud container clusters get-credentials cloudbuild-webhook-lab --zone=europe-west1-b --project=devops-cert-labs

añadir artifact reader

gcloud projects add-iam-policy-binding devops-cert-labs `
  --member="serviceAccount:gke-node-sa@devops-cert-labs.iam.gserviceaccount.com" `
  --role="roles/artifactregistry.reader"

PENDIENTE COMPROBAR WEBHOOK 1.0.0