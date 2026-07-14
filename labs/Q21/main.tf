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
#
# PROVIDER
#
####################################################

provider "google" {

  project = "devops-cert-labs"
  region  = "europe-west1"

}

####################################################
#
# ENABLE APIS
#
####################################################

resource "google_project_service" "artifactregistry" {

  service = "artifactregistry.googleapis.com"

  disable_on_destroy = false

}

resource "google_project_service" "cloudbuild" {

  service = "cloudbuild.googleapis.com"

  disable_on_destroy = false

}

####################################################
#
# ARTIFACT REGISTRY
#
####################################################

resource "google_artifact_registry_repository" "images" {

  depends_on = [
    google_project_service.artifactregistry
  ]

  repository_id = "release-images"

  location = "europe-west1"

  format = "DOCKER"

  description = "Application images tagged with Git releases"

}

####################################################
#
# CLOUD BUILD SERVICE ACCOUNT
#
####################################################

resource "google_service_account" "cloudbuild_sa" {

  account_id   = "cloudbuild-release"

  display_name = "Cloud Build Release Service Account"

}

####################################################
#
# IAM
#
####################################################

resource "google_project_iam_member" "artifact_writer" {

  project = "devops-cert-labs"

  role = "roles/artifactregistry.writer"

  member = "serviceAccount:${google_service_account.cloudbuild_sa.email}"

}

resource "google_project_iam_member" "logging_writer" {

  project = "devops-cert-labs"

  role = "roles/logging.logWriter"

  member = "serviceAccount:${google_service_account.cloudbuild_sa.email}"

}

resource "google_project_iam_member" "storage_admin" {

  project = "devops-cert-labs"

  role = "roles/storage.admin"

  member = "serviceAccount:${google_service_account.cloudbuild_sa.email}"

}

resource "google_project_iam_member" "cloudbuild_builder" {

  project = "devops-cert-labs"

  role = "roles/cloudbuild.builds.builder"

  member = "serviceAccount:${google_service_account.cloudbuild_sa.email}"

}

####################################################
#
# CLOUD BUILD TRIGGER
#
####################################################

resource "google_cloudbuild_trigger" "release_trigger" {

  depends_on = [
    google_project_service.cloudbuild,
    google_artifact_registry_repository.images
  ]

  name = "release-build"

  description = "Build Docker image using Git release tag"

  location = "global"

  service_account = google_service_account.cloudbuild_sa.name

  filename = "cloudbuild.yaml"

  substitutions = {

    _REGION     = "europe-west1"
    _REPOSITORY = google_artifact_registry_repository.images.repository_id
    _IMAGE      = "demo-app"

  }

  github {

    owner = "JavierGarAgu"

    name = "Q21-release-version-lab"

    push {

      tag = "^v.*"

    }

  }

}

####################################################
#
# OUTPUTS
#
####################################################

output "repository" {

  value = google_artifact_registry_repository.images.repository_id

}

output "trigger_name" {

  value = google_cloudbuild_trigger.release_trigger.name

}