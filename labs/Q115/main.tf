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

resource "google_project_service" "logging" {

  service = "logging.googleapis.com"

  disable_on_destroy = false

}

resource "google_project_service" "storage" {

  service = "storage.googleapis.com"

  disable_on_destroy = false

}

####################################################
# RANDOM SUFFIX
####################################################

resource "random_id" "suffix" {

  byte_length = 4

}

####################################################
# LOG ARCHIVE BUCKET
####################################################

resource "google_storage_bucket" "log_archive" {

  depends_on = [
    google_project_service.storage
  ]

  name = "devops-log-archive-${random_id.suffix.hex}"

  location = "EU"

  uniform_bucket_level_access = true

  force_destroy = true

  retention_policy {

    retention_period = 220752000

    is_locked = false

  }

}


####################################################
# PROJECT LOG SINK
####################################################

resource "google_logging_project_sink" "archive_logs" {

  depends_on = [
    google_project_service.logging
  ]

  name = "archive-all-logs"

  destination = "storage.googleapis.com/${google_storage_bucket.log_archive.name}"

  unique_writer_identity = true

}

####################################################
# PERMISSION FOR SINK WRITER
####################################################

resource "google_storage_bucket_iam_member" "sink_writer" {

  bucket = google_storage_bucket.log_archive.name

  role = "roles/storage.objectCreator"

  member = google_logging_project_sink.archive_logs.writer_identity

}

####################################################
# OUTPUTS
####################################################

output "bucket_name" {

  value = google_storage_bucket.log_archive.name

}

output "logging_sink" {

  value = google_logging_project_sink.archive_logs.name

}

output "bucket_lock_command" {

  value = "gsutil retention lock gs://${google_storage_bucket.log_archive.name}"

}

output "generate_log" {

  value = "gcloud logging write terraform-demo \"This is a compliance log.\""

}