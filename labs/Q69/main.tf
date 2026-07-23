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
#
# GOOGLE PROVIDER
#
#######################################################

provider "google" {

  project = "devops-cert-labs-v3"

  region  = "europe-west1"

}

#######################################################
#
# ENABLE REQUIRED APIS
#
#######################################################

locals {

  apis = [

    "cloudbuild.googleapis.com",

    "cloudkms.googleapis.com",

    "secretmanager.googleapis.com",

    "artifactregistry.googleapis.com",

    "iam.googleapis.com",

    "serviceusage.googleapis.com"

  ]

}

resource "google_project_service" "services" {

  for_each = toset(local.apis)

  service = each.key

  disable_on_destroy = false

}

#######################################################
#
# CLOUD BUILD SERVICE ACCOUNT
#
#######################################################

resource "google_service_account" "cloud_build" {

  depends_on = [

    google_project_service.services

  ]

  account_id = "cloud-build-sa"

  display_name = "Cloud Build Service Account"

}

#######################################################
#
# IAM ROLES
#
#######################################################

resource "google_project_iam_member" "artifact_registry_writer" {

  project = "devops-cert-labs-v3"

  role = "roles/artifactregistry.writer"

  member = "serviceAccount:${google_service_account.cloud_build.email}"

}

resource "google_project_iam_member" "secret_accessor" {

  project = "devops-cert-labs-v3"

  role = "roles/secretmanager.secretAccessor"

  member = "serviceAccount:${google_service_account.cloud_build.email}"

}

resource "google_project_iam_member" "cloudkms_crypto" {

  project = "devops-cert-labs-v3"

  role = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

  member = "serviceAccount:${google_service_account.cloud_build.email}"

}

resource "google_project_iam_member" "storage_admin" {

  project = "devops-cert-labs-v3"

  role = "roles/storage.admin"

  member = "serviceAccount:${google_service_account.cloud_build.email}"

}

resource "google_project_iam_member" "logging_writer" {

  project = "devops-cert-labs-v3"

  role = "roles/logging.logWriter"

  member = "serviceAccount:${google_service_account.cloud_build.email}"

}

#######################################################
#
# VARIABLES
#
#######################################################

variable "database_password" {

  description = "Database password stored in Secret Manager"

  type = string

  sensitive = true

}

variable "database_username" {

  description = "Database username"

  type = string

  default = "application"

}
#######################################################
#
# CLOUD KMS KEY RING
#
#######################################################

resource "google_kms_key_ring" "cloudbuild" {

  depends_on = [

    google_project_service.services

  ]

  name = "cloud-build-keyring"

  location = "global"

}

#######################################################
#
# CLOUD KMS CRYPTO KEY
#
#######################################################

resource "google_kms_crypto_key" "cloudbuild" {

  name = "cloud-build-key"

  key_ring = google_kms_key_ring.cloudbuild.id

  rotation_period = "7776000s"

}

#######################################################
#
# SECRET MANAGER
#
#######################################################

resource "google_secret_manager_secret" "database_password" {

  depends_on = [

    google_project_service.services

  ]

  secret_id = "database-password"

  replication {

    auto {}

  }

}

#######################################################
#
# SECRET VERSION
#
#######################################################

resource "google_secret_manager_secret_version" "database_password" {

  secret = google_secret_manager_secret.database_password.id

  secret_data = var.database_password

}

#######################################################
#
# SECRET IAM
#
#######################################################

resource "google_secret_manager_secret_iam_member" "cloudbuild_secret_access" {

  secret_id = google_secret_manager_secret.database_password.id

  role = "roles/secretmanager.secretAccessor"

  member = "serviceAccount:${google_service_account.cloud_build.email}"

}

#######################################################
#
# KMS IAM
#
#######################################################

resource "google_kms_crypto_key_iam_member" "cloudbuild_kms" {

  crypto_key_id = google_kms_crypto_key.cloudbuild.id

  role = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

  member = "serviceAccount:${google_service_account.cloud_build.email}"

}

#######################################################
#
# OUTPUTS
#
#######################################################

output "key_ring" {

  value = google_kms_key_ring.cloudbuild.name

}

output "crypto_key" {

  value = google_kms_crypto_key.cloudbuild.name

}

output "secret_name" {

  value = google_secret_manager_secret.database_password.secret_id

}
#######################################################
#
# ARTIFACT REGISTRY
#
#######################################################

resource "google_artifact_registry_repository" "docker" {

  depends_on = [

    google_project_service.services

  ]

  location = "europe-west1"

  repository_id = "secure-images"

  description = "Docker repository for Cloud Build"

  format = "DOCKER"

}

#######################################################
#
# STORAGE BUCKET
#
#######################################################

resource "google_storage_bucket" "cloudbuild_logs" {

  depends_on = [

    google_project_service.services

  ]

  name = "devops-cert-labs-v3-cloudbuild-logs"

  location = "EU"

  uniform_bucket_level_access = true

  force_destroy = true

}

#######################################################
#
# CLOUD BUILD TRIGGER
#
#######################################################

resource "google_cloudbuild_trigger" "github" {

  depends_on = [

    google_project_service.services,

    google_artifact_registry_repository.docker

  ]

  name = "kms-build-trigger"

  description = "Build and deploy application using Cloud KMS and Secret Manager"

  location = "global"

  github {

    owner = "JavierGarAgu"

    name = "Q69-KMS"

    push {

      branch = "^main$"

    }

  }

  filename = "cloudbuild.yaml"

  service_account = google_service_account.cloud_build.id

}

#######################################################
#
# OUTPUTS
#
#######################################################

output "artifact_registry_repository" {

  description = "Artifact Registry repository"

  value = google_artifact_registry_repository.docker.repository_id

}

output "artifact_registry_location" {

  value = google_artifact_registry_repository.docker.location

}

output "cloudbuild_trigger" {

  value = google_cloudbuild_trigger.github.name

}

output "cloudbuild_service_account" {

  value = google_service_account.cloud_build.email

}

output "cloudbuild_logs_bucket" {

  value = google_storage_bucket.cloudbuild_logs.name

}

output "github_repository" {

  value = "https://github.com/JavierGarAgu/Q69-KMS"

}

output "artifact_registry_console" {

  value = "https://console.cloud.google.com/artifacts"

}

output "secret_manager_console" {

  value = "https://console.cloud.google.com/security/secret-manager"

}

output "cloud_kms_console" {

  value = "https://console.cloud.google.com/security/kms"

}

output "cloud_build_console" {

  value = "https://console.cloud.google.com/cloud-build"

}