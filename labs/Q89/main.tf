terraform {

  required_version = ">= 1.5"

  required_providers {

    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }

  }

}

####################################################
# PROVIDER
####################################################

provider "google" {

  project = "devops-cert-labs-v3"
  region  = "europe-west1"

}

####################################################
# ENABLE APIS
####################################################

resource "google_project_service" "run" {

  service = "run.googleapis.com"

  disable_on_destroy = false

}

resource "google_project_service" "artifactregistry" {

  service = "artifactregistry.googleapis.com"

  disable_on_destroy = false

}

resource "google_project_service" "cloudbuild" {

  service = "cloudbuild.googleapis.com"

  disable_on_destroy = false

}

resource "google_project_service" "iam" {

  service = "iam.googleapis.com"

  disable_on_destroy = false

}

####################################################
# ARTIFACT REGISTRY
####################################################

resource "google_artifact_registry_repository" "repo" {

  depends_on = [
    google_project_service.artifactregistry
  ]

  location      = "europe-west1"

  repository_id = "cloudrun-images"

  format = "DOCKER"

  description = "Docker images for Cloud Run"

}

####################################################
# CLOUD RUN SERVICE ACCOUNT
####################################################

resource "google_service_account" "cloudrun" {

  account_id   = "cloudrun-service"

  display_name = "Cloud Run Service Account"

}

####################################################
# CLOUD RUN IAM
####################################################

resource "google_project_iam_member" "cloudrun_artifact" {

  project = "devops-cert-labs-v3"

  role = "roles/artifactregistry.reader"

  member = "serviceAccount:${google_service_account.cloudrun.email}"

}

####################################################
# CLOUD BUILD SERVICE ACCOUNT
####################################################

resource "google_service_account" "cloudbuild" {

  account_id = "cloudbuild-cloudrun"

  display_name = "Cloud Build Cloud Run"

}

####################################################
# CLOUD BUILD IAM
####################################################

resource "google_project_iam_member" "build_run_admin" {

  project = "devops-cert-labs-v3"

  role = "roles/run.admin"

  member = "serviceAccount:${google_service_account.cloudbuild.email}"

}

resource "google_project_iam_member" "build_sa_user" {

  project = "devops-cert-labs-v3"

  role = "roles/iam.serviceAccountUser"

  member = "serviceAccount:${google_service_account.cloudbuild.email}"

}

resource "google_project_iam_member" "build_logs" {

  project = "devops-cert-labs-v3"

  role = "roles/logging.logWriter"

  member = "serviceAccount:${google_service_account.cloudbuild.email}"

}

resource "google_project_iam_member" "build_storage" {

  project = "devops-cert-labs-v3"

  role = "roles/storage.admin"

  member = "serviceAccount:${google_service_account.cloudbuild.email}"

}

####################################################
# CLOUD RUN SERVICE
####################################################

resource "google_cloud_run_v2_service" "frontend" {

  depends_on = [
    google_project_service.run
  ]

  name = "frontend"

  location = "europe-west1"

  ingress = "INGRESS_TRAFFIC_ALL"

  template {

    service_account = google_service_account.cloudrun.email

    containers {

      image = "us-docker.pkg.dev/cloudrun/container/hello"

      ports {

        container_port = 8080

      }

    }

  }

  traffic {

    percent = 100

    type = "TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"

  }

}

####################################################
# PUBLIC ACCESS
####################################################

resource "google_cloud_run_service_iam_member" "public" {

  location = google_cloud_run_v2_service.frontend.location

  service = google_cloud_run_v2_service.frontend.name

  role = "roles/run.invoker"

  member = "allUsers"

}

####################################################
# CLOUD BUILD TRIGGER
####################################################

resource "google_cloudbuild_trigger" "pipeline" {

  depends_on = [
    google_project_service.cloudbuild
  ]

  name = "cloudrun-canary"

  description = "Cloud Run deployment pipeline"

  location = "global"

  service_account = google_service_account.cloudbuild.id

  filename = "cloudbuild.yaml"

  github {

    owner = "JavierGarAgu"

    name  = "Q89-cloudrun-canary"

    push {

      branch = "^main$"

    }

  }

}

####################################################
# OUTPUTS
####################################################

output "service_url" {

  value = google_cloud_run_v2_service.frontend.uri

}