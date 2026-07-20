gcloud projects delete devops-cert-labs

gcloud projects describe devops-cert-labs --format="value(lifecycleState)"

gcloud projects create devops-cert-labs-v2 --name="DevOps Cert Labs V2"

gcloud config set project devops-cert-labs-v2

#get billing_id
gcloud billing accounts list
gcloud billing projects link devops-cert-labs-v2 --billing-account=ACCOUNT_ID

gcloud services enable `
container.googleapis.com `
compute.googleapis.com `
artifactregistry.googleapis.com `
monitoring.googleapis.com `
logging.googleapis.com `
cloudbuild.googleapis.com `
iam.googleapis.com `
serviceusage.googleapis.com
cloudbuild.googleapis.com `
artifactregistry.googleapis.com `
secretmanager.googleapis.com