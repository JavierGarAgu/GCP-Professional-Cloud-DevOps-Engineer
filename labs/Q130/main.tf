terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "google" {
  project = "devops-cert-labs-v4"
  region  = "europe-west1"
}

##################################################
# VARIABLES
##################################################

variable "billing_account" {
  type = string
}

##################################################
# RANDOM SUFFIX
##################################################

resource "random_id" "suffix" {
  byte_length = 2
}

locals {

  suffix = lower(random_id.suffix.hex)

  projects = {
    logging = "logging-central-${local.suffix}"
    app1    = "logging-app1-${local.suffix}"
    app2    = "logging-app2-${local.suffix}"
  }

}

##################################################
# ENABLE RESOURCE MANAGER
##################################################

resource "google_project_service" "crm" {

  project = "devops-cert-labs-v4"
  service = "cloudresourcemanager.googleapis.com"

}

##################################################
# CREATE PROJECTS
##################################################

resource "google_project" "projects" {

  for_each = local.projects

  name            = each.key
  project_id      = each.value
  billing_account = var.billing_account

  depends_on = [
    google_project_service.crm
  ]

}

##################################################
# ENABLE LOGGING API
##################################################

resource "google_project_service" "logging" {

  for_each = google_project.projects

  project = each.value.project_id
  service = "logging.googleapis.com"

}

##################################################
# CENTRAL LOG BUCKET
##################################################

resource "google_logging_project_bucket_config" "central" {

  project = google_project.projects["logging"].project_id

  bucket_id = "central-logs"

  location = "global"

  retention_days = 30

  depends_on = [
    google_project_service.logging
  ]

}

##################################################
# APP1 -> CENTRAL
##################################################

resource "google_logging_project_sink" "app1" {

  project = google_project.projects["app1"].project_id

  name = "central-sink"

  destination = "logging.googleapis.com/projects/${google_project.projects["logging"].project_id}/locations/global/buckets/central-logs"

  unique_writer_identity = true

  depends_on = [
    google_logging_project_bucket_config.central
  ]

}

##################################################
# APP2 -> CENTRAL
##################################################

resource "google_logging_project_sink" "app2" {

  project = google_project.projects["app2"].project_id

  name = "central-sink"

  destination = "logging.googleapis.com/projects/${google_project.projects["logging"].project_id}/locations/global/buckets/central-logs"

  unique_writer_identity = true

  depends_on = [
    google_logging_project_bucket_config.central
  ]

}

##################################################
# IAM SO SINKS CAN WRITE
##################################################

resource "google_project_iam_member" "app1_writer" {

  project = google_project.projects["logging"].project_id

  role = "roles/logging.bucketWriter"

  member = google_logging_project_sink.app1.writer_identity

}

resource "google_project_iam_member" "app2_writer" {

  project = google_project.projects["logging"].project_id

  role = "roles/logging.bucketWriter"

  member = google_logging_project_sink.app2.writer_identity

}

##################################################
# OUTPUTS
##################################################

output "logging_project" {
  value = google_project.projects["logging"].project_id
}

output "app1_project" {
  value = google_project.projects["app1"].project_id
}

output "app2_project" {
  value = google_project.projects["app2"].project_id
}

output "bucket_name" {
  value = google_logging_project_bucket_config.central.bucket_id
}