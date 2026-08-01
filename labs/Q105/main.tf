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
# PROVIDER
#
#######################################################

provider "google" {

  project = "devops-cert-labs-v4"
  region  = "europe-west1"

}

#######################################################
#
# DATA
#
#######################################################

data "google_project" "project" {

  project_id = "devops-cert-labs-v4"

}

#######################################################
#
# ENABLE APIS
#
#######################################################

locals {

  apis = [

    "cloudbuild.googleapis.com"

  ]

}

resource "google_project_service" "apis" {

  for_each = toset(local.apis)

  service = each.key

  disable_on_destroy = false

}

#######################################################
#
# SERVICE ACCOUNT
#
#######################################################

resource "google_service_account" "cloudbuild" {

  account_id   = "packer-cloudbuild-sa"
  display_name = "Packer Cloud Build Service Account"

}

#######################################################
#
# IAM
#
#######################################################

resource "google_project_iam_member" "cloudbuild_builder" {

  project = data.google_project.project.project_id

  role   = "roles/cloudbuild.builds.builder"
  member = "serviceAccount:${google_service_account.cloudbuild.email}"

}

resource "google_project_iam_member" "logging_writer" {

  project = data.google_project.project.project_id

  role   = "roles/logging.logWriter"
  member = "serviceAccount:${google_service_account.cloudbuild.email}"

}

resource "google_project_iam_member" "compute_admin" {

  project = data.google_project.project.project_id

  role   = "roles/compute.admin"
  member = "serviceAccount:${google_service_account.cloudbuild.email}"

}

resource "google_project_iam_member" "iam_service_account_user" {

  project = data.google_project.project.project_id

  role   = "roles/iam.serviceAccountUser"
  member = "serviceAccount:${google_service_account.cloudbuild.email}"

}

resource "google_service_account_iam_member" "cloudbuild_use_sa" {

  service_account_id = google_service_account.cloudbuild.name

  role = "roles/iam.serviceAccountUser"

  member = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"

}

#######################################################
#
# CLOUD BUILD TRIGGER
#
#######################################################

resource "google_cloudbuild_trigger" "packer" {

  depends_on = [

    google_project_service.apis,
    google_project_iam_member.cloudbuild_builder

  ]

  name        = "Q105-packer-cloudbuild"
  description = "Build Compute Engine images with Packer"

  location = "global"

  github {

    owner = "JavierGarAgu"
    name  = "Q105-packer-cloudbuild"

    push {

      branch = "^main$"

    }

  }

  filename = "cloudbuild.yaml"

  service_account = google_service_account.cloudbuild.id

}

#######################################################
#
# OUTPUTS
#
#######################################################

output "cloudbuild_service_account" {

  value = google_service_account.cloudbuild.email

}

output "trigger_name" {

  value = google_cloudbuild_trigger.packer.name

}