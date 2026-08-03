terraform {

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

  project = "devops-cert-labs-v4"
  region  = "europe-west1"

}

####################################################
# ENABLE APIS
####################################################

resource "google_project_service" "artifactregistry" {

  service = "artifactregistry.googleapis.com"

  disable_on_destroy = false

}

####################################################
# ARTIFACT REGISTRY REPOSITORY
####################################################

resource "google_artifact_registry_repository" "helm_repo" {

  depends_on = [
    google_project_service.artifactregistry
  ]

  repository_id = "helm-oci"

  location = "europe-west1"

  description = "OCI repository for Helm charts"

  format = "DOCKER"

}

####################################################
# SERVICE ACCOUNT
####################################################

resource "google_service_account" "helm_writer" {

  account_id = "helm-artifact-writer"

  display_name = "Helm OCI Writer"

}

####################################################
# IAM
####################################################

resource "google_project_iam_member" "artifact_writer" {

  project = "devops-cert-labs-v4"

  role = "roles/artifactregistry.writer"

  member = "serviceAccount:${google_service_account.helm_writer.email}"

}

####################################################
# OUTPUTS
####################################################

output "repository" {

  value = google_artifact_registry_repository.helm_repo.repository_id

}

output "oci_url" {

  value = "oci://europe-west1-docker.pkg.dev/devops-cert-labs-v4/helm-oci"

}

output "docker_login" {

  value = "gcloud auth configure-docker europe-west1-docker.pkg.dev"

}

output "helm_push_example" {

  value = "helm push mychart-0.1.0.tgz oci://europe-west1-docker.pkg.dev/devops-cert-labs-v4/helm-oci"

}

output "oras_push_example" {

  value = "oras push europe-west1-docker.pkg.dev/devops-cert-labs-v4/helm-oci/random:v1 artifact.txt:text/plain"

}