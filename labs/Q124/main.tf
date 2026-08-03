terraform {

  required_version = ">= 1.5"

  required_providers {

    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }

    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.7"
    }

  }

}

provider "google" {

  project = "devops-cert-labs-v4"
  region  = "europe-west1"

}

#########################################################
# CURRENT PROJECT DATA
#########################################################

data "google_project" "current" {}


#########################################################
# EVENTARC + CLOUD STORAGE IAM
#########################################################

# Cloud Storage Service Agent can publish events to Pub/Sub
# used internally by Eventarc

resource "google_project_iam_member" "storage_service_agent_pubsub" {

  project = data.google_project.current.project_id

  role = "roles/pubsub.publisher"

  member = "serviceAccount:service-${data.google_project.current.number}@gs-project-accounts.iam.gserviceaccount.com"

}


# Eventarc service agent permissions

resource "google_project_iam_member" "eventarc_service_agent" {

  project = data.google_project.current.project_id

  role = "roles/eventarc.serviceAgent"

  member = "serviceAccount:service-${data.google_project.current.number}@gcp-sa-eventarc.iam.gserviceaccount.com"

}


# Cloud Functions Gen2 service agent

resource "google_project_iam_member" "cloudfunctions_service_agent" {

  project = data.google_project.current.project_id

  role = "roles/cloudfunctions.serviceAgent"

  member = "serviceAccount:service-${data.google_project.current.number}@gcf-admin-robot.iam.gserviceaccount.com"

}


#########################################################
# CLOUD FUNCTION SERVICE ACCOUNT IAM
#########################################################

# Allows receiving Eventarc events

resource "google_project_iam_member" "function_event_receiver" {

  project = data.google_project.current.project_id

  role = "roles/eventarc.eventReceiver"

  member = "serviceAccount:${google_service_account.cloud_function.email}"

}


# Write logs to Cloud Logging

resource "google_project_iam_member" "function_log_writer" {

  project = data.google_project.current.project_id

  role = "roles/logging.logWriter"

  member = "serviceAccount:${google_service_account.cloud_function.email}"

}


# Manage Compute Engine MIG

resource "google_project_iam_member" "function_compute_admin" {

  project = data.google_project.current.project_id

  role = "roles/compute.instanceAdmin.v1"

  member = "serviceAccount:${google_service_account.cloud_function.email}"

}


# Allow using service accounts

resource "google_project_iam_member" "function_service_account_user" {

  project = data.google_project.current.project_id

  role = "roles/iam.serviceAccountUser"

  member = "serviceAccount:${google_service_account.cloud_function.email}"

}


# Read Artifact Registry images during Cloud Function build

resource "google_project_iam_member" "function_artifact_reader" {

  project = data.google_project.current.project_id

  role = "roles/artifactregistry.reader"

  member = "serviceAccount:${google_service_account.cloud_function.email}"

}


#########################################################
# CLOUD STORAGE BUCKET IAM FOR EVENTS
#########################################################

resource "google_storage_bucket_iam_member" "storage_service_agent_access" {

  bucket = google_storage_bucket.uploads.name

  role = "roles/storage.admin"

  member = "serviceAccount:service-${data.google_project.current.number}@gs-project-accounts.iam.gserviceaccount.com"

}


#########################################################
# CLOUD BUILD SERVICE AGENT (FUNCTION BUILD)
#########################################################

resource "google_project_iam_member" "cloudbuild_service_agent" {

  project = data.google_project.current.project_id

  role = "roles/cloudbuild.builds.builder"

  member = "serviceAccount:${data.google_project.current.number}@cloudbuild.gserviceaccount.com"

}


#########################################################
# RUN SERVICE AGENT (FUNCTION GEN2 BACKEND)
#########################################################

resource "google_project_iam_member" "run_service_agent" {

  project = data.google_project.current.project_id

  role = "roles/run.serviceAgent"

  member = "serviceAccount:service-${data.google_project.current.number}@serverless-robot-prod.iam.gserviceaccount.com"

}

#########################################################
# ENABLE APIS
#########################################################

resource "google_project_service" "compute" {

  project = "devops-cert-labs-v4"
  service = "compute.googleapis.com"

  disable_on_destroy = false

}

resource "google_project_service" "storage" {

  project = "devops-cert-labs-v4"
  service = "storage.googleapis.com"

  disable_on_destroy = false

}

resource "google_project_service" "functions" {

  project = "devops-cert-labs-v4"
  service = "cloudfunctions.googleapis.com"

  disable_on_destroy = false

}

resource "google_project_service" "cloudbuild" {

  project = "devops-cert-labs-v4"
  service = "cloudbuild.googleapis.com"

  disable_on_destroy = false

}

resource "google_project_service" "run" {

  project = "devops-cert-labs-v4"
  service = "run.googleapis.com"

  disable_on_destroy = false

}

resource "google_project_service" "eventarc" {

  project = "devops-cert-labs-v4"
  service = "eventarc.googleapis.com"

  disable_on_destroy = false

}

resource "google_project_service" "artifactregistry" {

  project = "devops-cert-labs-v4"
  service = "artifactregistry.googleapis.com"

  disable_on_destroy = false

}

#########################################################
# STORAGE BUCKET FOR THIRD PARTIES
#########################################################

resource "google_storage_bucket" "uploads" {

  name                        = "devops-cert-labs-v4-batch-uploads"
  location                    = "europe-west1"
  uniform_bucket_level_access = true
  force_destroy               = true

  depends_on = [
    google_project_service.storage
  ]

}

#########################################################
# FUNCTION SOURCE BUCKET
#########################################################

resource "google_storage_bucket" "function_source" {

  name                        = "devops-cert-labs-v4-function-source"
  location                    = "europe-west1"
  uniform_bucket_level_access = true
  force_destroy               = true

  depends_on = [
    google_project_service.storage
  ]

}

#########################################################
# SERVICE ACCOUNT FOR THIRD PARTIES
#########################################################

resource "google_service_account" "third_party" {

  account_id   = "third-party-upload"
  display_name = "Third Party Upload"

}

resource "google_storage_bucket_iam_member" "upload_permission" {

  bucket = google_storage_bucket.uploads.name
  role   = "roles/storage.objectCreator"
  member = "serviceAccount:${google_service_account.third_party.email}"

}

#########################################################
# INSTANCE TEMPLATE
#########################################################

resource "google_compute_instance_template" "processor" {
  lifecycle {
    create_before_destroy = true
  }
  name_prefix  = "processor-template-"
  machine_type = "n2-standard-8"

  disk {

    auto_delete  = true
    boot         = true
    source_image = "projects/debian-cloud/global/images/family/debian-12"

  }

  network_interface {

    network = "default"

    access_config {}

  }

  metadata_startup_script = <<EOF
#!/bin/bash

echo "Batch processor started"

# Placeholder
# Here the processing software would already exist
# because the exam says:
# "Use an image pre-loaded with the data processing software"

sleep 120

shutdown -h now
EOF

  depends_on = [
    google_project_service.compute
  ]

}

#########################################################
# MANAGED INSTANCE GROUP
#########################################################

resource "google_compute_region_instance_group_manager" "processor" {

  name               = "processor-mig"
  region             = "europe-west1"
  base_instance_name = "processor"

  version {

    instance_template = google_compute_instance_template.processor.id

  }

  target_size = 0

}

#########################################################
# AUTOSCALER
#########################################################

resource "google_compute_region_autoscaler" "processor" {

  name   = "processor-autoscaler"
  region = "europe-west1"
  target = google_compute_region_instance_group_manager.processor.id

autoscaling_policy {

  min_replicas = 0
  max_replicas = 20

  cpu_utilization {
    target = 0.70
  }

}

}
#########################################################
# CLOUD FUNCTION SOURCE
#########################################################

data "archive_file" "function" {

  type        = "zip"
  source_dir  = "./function"
  output_path = "./function.zip"

}

resource "google_storage_bucket_object" "function_zip" {

  name   = "function.zip"
  bucket = google_storage_bucket.function_source.name
  source = data.archive_file.function.output_path

}

#########################################################
# CLOUD FUNCTION SERVICE ACCOUNT
#########################################################

resource "google_service_account" "cloud_function" {

  account_id   = "cloud-function-sa"
  display_name = "Cloud Function Service Account"

}

#########################################################
# IAM
#########################################################

resource "google_project_iam_member" "compute_admin" {

  project = "devops-cert-labs"
  role    = "roles/compute.instanceAdmin.v1"
  member  = "serviceAccount:${google_service_account.cloud_function.email}"

}

resource "google_project_iam_member" "compute_viewer" {

  project = "devops-cert-labs"
  role    = "roles/compute.viewer"
  member  = "serviceAccount:${google_service_account.cloud_function.email}"

}

resource "google_project_iam_member" "service_account_user" {

  project = "devops-cert-labs"
  role    = "roles/iam.serviceAccountUser"
  member  = "serviceAccount:${google_service_account.cloud_function.email}"

}

resource "google_project_iam_member" "event_receiver" {

  project = "devops-cert-labs"
  role    = "roles/eventarc.eventReceiver"
  member  = "serviceAccount:${google_service_account.cloud_function.email}"

}

resource "google_project_iam_member" "artifact_registry_reader" {

  project = "devops-cert-labs"
  role    = "roles/artifactregistry.reader"
  member  = "serviceAccount:${google_service_account.cloud_function.email}"

}

#########################################################
# CLOUD FUNCTION GEN2
#########################################################

resource "google_cloudfunctions2_function" "scale_mig" {

  name     = "scale-managed-instance-group"
  location = "europe-west1"

  build_config {

    runtime     = "python312"
    entry_point = "main"

    source {

      storage_source {

        bucket = google_storage_bucket.function_source.name
        object = google_storage_bucket_object.function_zip.name

      }

    }

  }

  service_config {

    max_instance_count    = 1
    min_instance_count    = 0
    available_memory      = "256M"
    timeout_seconds       = 60
    ingress_settings      = "ALLOW_ALL"
    service_account_email = google_service_account.cloud_function.email

  }

  event_trigger {

    trigger_region = "europe-west1"
    event_type     = "google.cloud.storage.object.v1.finalized"

    event_filters {

      attribute = "bucket"
      value     = google_storage_bucket.uploads.name

    }

    retry_policy = "RETRY_POLICY_RETRY"

  }

  depends_on = [

    google_project_service.functions,
    google_project_service.eventarc,
    google_project_service.run,
    google_project_service.cloudbuild,
    google_project_service.artifactregistry

  ]

}

#########################################################
# OUTPUTS
#########################################################

output "upload_bucket" {

  value = google_storage_bucket.uploads.name

}

output "cloud_function" {

  value = google_cloudfunctions2_function.scale_mig.name

}

output "managed_instance_group" {

  value = google_compute_region_instance_group_manager.processor.name

}

output "autoscaler" {

  value = google_compute_region_autoscaler.processor.name

}
