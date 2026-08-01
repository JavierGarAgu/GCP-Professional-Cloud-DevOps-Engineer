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
# SERVICE ACCOUNT
#

resource "google_service_account" "third_party" {

  account_id   = "third-party-app"
  display_name = "Third Party Application"

}

#
# PROJECT ORGANIZATION POLICY
#
# Simulates Answer D:
# Override the inherited policy only for this project.
#

resource "google_project_organization_policy" "allow_service_account_keys" {

  project    = "devops-cert-labs-v4"
  constraint = "iam.disableServiceAccountKeyCreation"

  boolean_policy {

    enforced = false

  }

}

#
# SERVICE ACCOUNT KEY
#
# This resource succeeds because the project
# overrides the inherited organization policy.
#

resource "google_service_account_key" "third_party_key" {

  service_account_id = google_service_account.third_party.name

  depends_on = [

    google_project_organization_policy.allow_service_account_keys

  ]

}

#
# OUTPUTS
#

output "service_account_email" {

  value = google_service_account.third_party.email

}

output "private_key_file" {

  value = "terraform.tfstate contains the generated key."

  description = "Only for lab purposes."

}