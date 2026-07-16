terraform {
  required_version = ">= 1.6"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 7.0"
    }
  }
}

provider "google" {

  project = "devops-cert-labs"
  region  = "europe-west1"
  zone    = "europe-west1-b"

}

############################
# Enable APIs
############################

resource "google_project_service" "services" {
  for_each = toset([
    "run.googleapis.com",
    "cloudscheduler.googleapis.com",
    "logging.googleapis.com"
  ])

  service = each.value

  disable_on_destroy = false
}

############################
# Cloud Run
############################

resource "google_cloud_run_v2_service" "app" {

  name     = "reliability-lab"
  location = "europe-west1"   # Obligatorio

  template {

    containers {

      image = "us-docker.pkg.dev/cloudrun/container/hello"

      ports {
        container_port = 8080
      }
    }
  }

  depends_on = [
    google_project_service.services
  ]
}

resource "google_cloud_run_service_iam_member" "public" {

  location = "europe-west1"   # Obligatorio
  service  = google_cloud_run_v2_service.app.name
  role      = "roles/run.invoker"
  member    = "allUsers"
}

############################
# Scheduler Service Account
############################

resource "google_service_account" "scheduler" {

  account_id   = "synthetic-client"
  display_name = "Synthetic Client"
}

resource "google_cloud_run_service_iam_member" "scheduler_invoker" {
 
  location = "europe-west1"   # Obligatorio
  service  = google_cloud_run_v2_service.app.name

  role   = "roles/run.invoker"
  member = "serviceAccount:${google_service_account.scheduler.email}"
}

############################
# Synthetic Client
############################

resource "google_cloud_scheduler_job" "synthetic_check" {

  name      = "synthetic-user-check"
  region    = "europe-west1"   # Obligatorio
  schedule  = "*/5 * * * *"

  http_target {

    uri         = google_cloud_run_v2_service.app.uri
    http_method = "GET"

    oidc_token {
      service_account_email = google_service_account.scheduler.email
    }
  }

  depends_on = [
    google_cloud_run_service_iam_member.scheduler_invoker
  ]
}