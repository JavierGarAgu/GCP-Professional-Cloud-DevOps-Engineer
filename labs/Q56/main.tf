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

    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }

  }

}


#######################################################
# PROVIDER
#######################################################

provider "google" {

  project = "devops-cert-labs-v2"

  region = "europe-west1"

}


#######################################################
# APIS
#######################################################

resource "google_project_service" "artifactregistry" {

  service = "artifactregistry.googleapis.com"

  disable_on_destroy = false

}


resource "google_project_service" "cloudbuild" {

  service = "cloudbuild.googleapis.com"

  disable_on_destroy = false

}


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
# CACHE BUCKET
#######################################################

resource "random_id" "bucket" {

  byte_length = 4

}


resource "google_storage_bucket" "cache_bucket" {

  name = "cloud-build-cache-${random_id.bucket.hex}"

  location = "EU"

  uniform_bucket_level_access = true

}


#######################################################
# CLOUD BUILD SERVICE ACCOUNT
#######################################################

resource "google_service_account" "cloudbuild_sa" {

  account_id = "container-cache-cloudbuild"

  display_name = "Cloud Build Cache Service Account"

}


#######################################################
# IAM LOGGING
#######################################################

resource "google_project_iam_member" "cloudbuild_logging" {

  project = "devops-cert-labs-v2"

  role = "roles/logging.logWriter"

  member = "serviceAccount:${google_service_account.cloudbuild_sa.email}"

}


#######################################################
# IAM ARTIFACT REGISTRY
#######################################################

resource "google_project_iam_member" "cloudbuild_artifact_writer" {

  project = "devops-cert-labs-v2"

  role = "roles/artifactregistry.writer"

  member = "serviceAccount:${google_service_account.cloudbuild_sa.email}"

}


#######################################################
# IAM STORAGE CACHE
#######################################################

resource "google_storage_bucket_iam_member" "cache_writer" {

  bucket = google_storage_bucket.cache_bucket.name

  role = "roles/storage.objectAdmin"

  member = "serviceAccount:${google_service_account.cloudbuild_sa.email}"

}


#######################################################
# CLOUD BUILD TRIGGER
#######################################################

resource "google_cloudbuild_trigger" "cache_pipeline" {

  depends_on = [

    google_project_service.cloudbuild,

    google_artifact_registry_repository.repository,

    google_storage_bucket_iam_member.cache_writer

  ]


  name = "cloud-build-cache-pipeline"


  description = "Cloud Build pipeline using Cloud Storage cache"


  location = "global"


  service_account = google_service_account.cloudbuild_sa.id


  filename = "cloudbuild.yaml"


  substitutions = {

    _CACHE_BUCKET = google_storage_bucket.cache_bucket.name

    _IMAGE = "cloud-build-cache"

    _REGION = "europe-west1"

    _REPOSITORY = google_artifact_registry_repository.repository.repository_id

  }


  github {

    owner = "JavierGarAgu"

    name = "Q56-cloud-build-cache"


    push {

      branch = "^main$"

    }

  }

}


#######################################################
# OUTPUTS
#######################################################

output "cache_bucket" {

  value = google_storage_bucket.cache_bucket.name

}


output "artifact_registry" {

  value = google_artifact_registry_repository.repository.repository_id

}


output "trigger" {

  value = google_cloudbuild_trigger.cache_pipeline.name

}