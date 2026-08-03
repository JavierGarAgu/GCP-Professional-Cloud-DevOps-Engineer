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

variable "api_key" {
  description = "Third-party API key"
  type        = string
  sensitive   = true
}

resource "google_secret_manager_secret" "api_key" {
  secret_id = "third-party-api-key"

  replication {
    auto {}
  }
}

resource "google_secret_manager_secret_version" "api_key" {
  secret      = google_secret_manager_secret.api_key.id
  secret_data = var.api_key
}

resource "null_resource" "read_secret" {
  depends_on = [google_secret_manager_secret_version.api_key]

  provisioner "local-exec" {
    interpreter = ["PowerShell", "-Command"]

    command = <<EOT
gcloud secrets versions access latest --secret=third-party-api-key
EOT
  }
}