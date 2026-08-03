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

#################################################
# VARIABLES
#################################################

variable "billing_account" {
  description = "Billing Account ID"
  type        = string
}

#################################################
# RANDOM SUFFIX
#################################################

resource "random_id" "suffix" {
  byte_length = 2
}

locals {
  suffix = lower(random_id.suffix.hex)

  projects = {
    scope = "devops-scope-${local.suffix}"
    app1  = "devops-app1-${local.suffix}"
    app2  = "devops-app2-${local.suffix}"
  }
}

#################################################
# ENABLE CLOUD RESOURCE MANAGER API
#################################################

resource "google_project_service" "crm" {
  project = "devops-cert-labs-v4"
  service = "cloudresourcemanager.googleapis.com"

  disable_on_destroy = true
}

#################################################
# CREATE PROJECTS
#################################################

resource "google_project" "projects" {
  for_each = local.projects

  name                = each.key
  project_id          = each.value
  billing_account     = var.billing_account

  depends_on = [
    google_project_service.crm
  ]
}

#################################################
# ENABLE MONITORING API
#################################################

resource "google_project_service" "monitoring" {
  for_each = google_project.projects

  project = each.value.project_id
  service = "monitoring.googleapis.com"

  disable_on_destroy = true
}