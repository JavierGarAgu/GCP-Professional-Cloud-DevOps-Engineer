#######################################################
# TERRAFORM
#######################################################

terraform {

  required_version = ">= 1.5"

  required_providers {

    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }

  }

}

#######################################################
# PROVIDER
#######################################################

provider "google" {

  project = "devops-cert-labs-v2"
  region  = "europe-west1"

}

#######################################################
# REQUIRED APIS
#######################################################

resource "google_project_service" "artifactregistry" {

  service = "artifactregistry.googleapis.com"

  disable_on_destroy = false

}

resource "google_project_service" "cloudbuild" {

  service = "cloudbuild.googleapis.com"

  disable_on_destroy = false

}

#
# Container Analysis API intentionally NOT enabled.
#
# resource "google_project_service" "containeranalysis" {
#
#   service = "containeranalysis.googleapis.com"
#
#   disable_on_destroy = false
#
# }
#

#######################################################
# ARTIFACT REGISTRY
#######################################################

resource "google_artifact_registry_repository" "repository" {

  depends_on = [
    google_project_service.artifactregistry
  ]

  repository_id = "secure-images"

  location = "europe-west1"

  format = "DOCKER"

}

#######################################################
# STORAGE BUCKET
#######################################################

resource "random_id" "id" {

  byte_length = 4

}

resource "google_storage_bucket" "source_bucket" {

  name = "container-analysis-lab-${random_id.id.hex}"

  location = "EU"

  uniform_bucket_level_access = true

}

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

resource "google_project_service" "containeranalysis" {

  service = "containeranalysis.googleapis.com"

  disable_on_destroy = false

}

#######################################################
# OUTPUTS
#######################################################

output "artifact_registry" {

  value = google_artifact_registry_repository.repository.repository_id

}

output "artifact_registry_url" {

  value = "europe-west1-docker.pkg.dev/${google_artifact_registry_repository.repository.project}/${google_artifact_registry_repository.repository.repository_id}"

}

output "cloud_build_trigger" {

  value = google_cloudbuild_trigger.container_pipeline.name

}

output "bucket" {

  value = google_storage_bucket.source_bucket.name

}

output "region" {

  value = "europe-west1"

}
