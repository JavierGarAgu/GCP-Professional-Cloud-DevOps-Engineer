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

  project = "devops-cert-labs"
  region  = "europe-west1"

}

####################################################
# ENABLE REQUIRED APIS
####################################################

resource "google_project_service" "services" {

  for_each = toset([
    "logging.googleapis.com",
    "bigquery.googleapis.com"
  ])

  project = "devops-cert-labs"
  service = each.key

  disable_on_destroy = false

}

####################################################
# BIGQUERY DATASET
####################################################

resource "google_bigquery_dataset" "vm_logs" {

  dataset_id = "vm_utilization_logs"

  location = "EU"

  description = "Dataset used to store exported VM utilization logs."

  depends_on = [
    google_project_service.services
  ]

}

####################################################
# LOGGING SINK
####################################################

resource "google_logging_project_sink" "vm_logs_sink" {

  name = "vm-utilization-to-bigquery"

  destination = "bigquery.googleapis.com/projects/devops-cert-labs/datasets/${google_bigquery_dataset.vm_logs.dataset_id}"

  filter = <<EOF
resource.type="gce_instance"
EOF

  unique_writer_identity = true

}

####################################################
# IAM
####################################################

resource "google_bigquery_dataset_iam_member" "logging_writer" {

  dataset_id = google_bigquery_dataset.vm_logs.dataset_id

  role = "roles/bigquery.dataEditor"

  member = google_logging_project_sink.vm_logs_sink.writer_identity

}

####################################################
# OUTPUTS
####################################################

output "bigquery_dataset" {

  value = google_bigquery_dataset.vm_logs.dataset_id

}

output "bigquery_console" {

  value = "https://console.cloud.google.com/bigquery?project=devops-cert-labs"

}

output "looker_studio" {

  value = "https://lookerstudio.google.com/"

}