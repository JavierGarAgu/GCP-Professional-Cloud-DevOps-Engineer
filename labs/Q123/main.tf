terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = "devops-cert-labs-v4"
  region  = "europe-west1"
}

#################################################
# ENABLE LOGGING API
#################################################

resource "google_project_service" "logging" {
  service = "logging.googleapis.com"
  project = "devops-cert-labs-v4"

  disable_on_destroy = true
}

#################################################
# SERVICE ACCOUNT
#################################################

resource "google_service_account" "security_team" {
  account_id   = "security-team"
  display_name = "Security Team"
}

#################################################
# IAM ROLE
#################################################

resource "google_project_iam_member" "logging_viewer" {
  project = "devops-cert-labs-v4"

  role = "roles/logging.viewer"

  member = "serviceAccount:${google_service_account.security_team.email}"

  depends_on = [
    google_project_service.logging
  ]
}

resource "google_service_account_key" "security_team" {
  service_account_id = google_service_account.security_team.name
}

#################################################
# OUTPUT
#################################################

output "service_account" {
  value = google_service_account.security_team.email
}

output "private_key" {
  value     = google_service_account_key.security_team.private_key
  sensitive = true
}