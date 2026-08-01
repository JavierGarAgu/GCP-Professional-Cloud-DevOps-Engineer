terraform {

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

#
# Enable APIs
#

resource "google_project_service" "run" {

  service = "run.googleapis.com"

}

resource "google_project_service" "artifactregistry" {

  service = "artifactregistry.googleapis.com"

}

#
# Cloud Run Service
#

resource "google_cloud_run_v2_service" "app" {


  depends_on = [
    google_project_service.run,
    google_project_service.artifactregistry
  ]

  name     = "cost-optimization-demo"
  location = "europe-west1"

  template {

    containers {

      image = "us-docker.pkg.dev/cloudrun/container/hello"

    }

  }

}

#
# Public Access
#

resource "google_cloud_run_service_iam_member" "public" {

  location = google_cloud_run_v2_service.app.location

  service  = google_cloud_run_v2_service.app.name

  role = "roles/run.invoker"

  member = "allUsers"

}

output "url" {

  value = google_cloud_run_v2_service.app.uri

}