terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = "devops-cert-labs"
  region  = "europe-west1"
}

#
# Enable required APIs
#
resource "google_project_service" "cloudbuild" {
  service = "cloudbuild.googleapis.com"
}

resource "google_project_service" "artifactregistry" {
  service = "artifactregistry.googleapis.com"
}

#
# Artifact Registry
#
resource "google_artifact_registry_repository" "repo" {
  location      = "europe-west1"
  repository_id = "production-images"
  format        = "DOCKER"
}

#
# Cloud Build Trigger
#
resource "google_cloudbuild_trigger" "production" {

  name = "production-main-build"

  github {

    owner = "JavierGarAgu"

    name = "Q107-main-trigger"

    push {

      branch = "^main$"

    }

  }

  filename = "cloudbuild.yaml"
}