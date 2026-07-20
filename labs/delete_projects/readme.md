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



CLOUDBUILD SETUP


resource "google_service_account" "cloudbuild_sa" {

  account_id   = "container-analysis-cloudbuild"
  display_name = "Container Analysis Cloud Build"

}

#######################################################
# LOGGING WRITER
#######################################################

resource "google_project_iam_member" "cloudbuild_logging" {

  project = "devops-cert-labs-v2"

  role = "roles/logging.logWriter"

  member = "serviceAccount:${google_service_account.cloudbuild_sa.email}"

}

#######################################################
# ARTIFACT REGISTRY WRITER
#######################################################

resource "google_project_iam_member" "cloudbuild_artifact_writer" {

  project = "devops-cert-labs-v2"

  role = "roles/artifactregistry.writer"

  member = "serviceAccount:${google_service_account.cloudbuild_sa.email}"

}


#######################################################
# CLOUD BUILD TRIGGER
#######################################################
resource "google_cloudbuild_trigger" "container_pipeline" {

  service_account = google_service_account.cloudbuild_sa.id
  depends_on = [
    google_project_service.cloudbuild,
    google_artifact_registry_repository.repository
  ]

  name = "container-analysis-pipeline"

  description = "Automatically builds and pushes container images."

  location = "global"

  filename = "cloudbuild.yaml"

  github {

    owner = "JavierGarAgu"

    name = "Q55-vuln-docker"

    push {

      branch = "^main$"

    }

  }

}