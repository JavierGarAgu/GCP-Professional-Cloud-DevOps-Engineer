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
# ENABLE LOGGING API
####################################################

resource "google_project_service" "logging" {

  service = "logging.googleapis.com"

  disable_on_destroy = false

}

####################################################
# LOG BUCKET
####################################################

resource "google_logging_project_bucket_config" "client_logs" {

  depends_on = [
    google_project_service.logging
  ]

  project = "devops-cert-labs-v4"

  location = "global"

  bucket_id = "client-log-archive"

  description = "Log bucket with one year retention"

  retention_days = 365

}

####################################################
# LOGGING SINK
####################################################

resource "google_logging_project_sink" "client_sink" {

  depends_on = [
    google_logging_project_bucket_config.client_logs
  ]

  name = "client-log-export"

  destination = "logging.googleapis.com/projects/devops-cert-labs-v4/locations/global/buckets/${google_logging_project_bucket_config.client_logs.bucket_id}"

  unique_writer_identity = true

}

####################################################
# IAM
####################################################

resource "google_project_iam_member" "client_log_viewer" {

  project = "devops-cert-labs-v4"

  role = "roles/logging.viewer"

  member = "user:javiermovilx30@gmail.com"

}

####################################################
# OUTPUTS
####################################################

output "log_bucket" {

  value = google_logging_project_bucket_config.client_logs.bucket_id

}

output "retention_days" {

  value = google_logging_project_bucket_config.client_logs.retention_days

}

output "sink_name" {

  value = google_logging_project_sink.client_sink.name

}

output "generate_log" {

  value = "gcloud logging write client-demo \"Cloud Run log example\""

}