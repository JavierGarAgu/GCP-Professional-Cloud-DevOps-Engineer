terraform {

  required_version = ">= 1.5"

  required_providers {

    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }

  }

}

#######################################################
#
# PROVIDER
#
#######################################################

provider "google" {

  project = "devops-cert-labs"

  region = "europe-west1"

}


#######################################################
#
# ENABLE REQUIRED APIS
#
#######################################################

locals {

  apis = [

    "cloudbuild.googleapis.com",
    "secretmanager.googleapis.com",
    "iam.googleapis.com"

  ]

}


resource "google_project_service" "services" {

  for_each = toset(local.apis)

  service = each.key

  disable_on_destroy = false

}


#######################################################
#
# CLOUD BUILD SERVICE ACCOUNT
#
#######################################################

resource "google_service_account" "cloudbuild_sa" {


  account_id = "cloudbuild-secrets"


  display_name = "Cloud Build Secret Manager Access"


}



#######################################################
#
# CLOUD BUILD LOGGING PERMISSION
#
#######################################################

resource "google_project_iam_member" "logging_writer" {


  project = "devops-cert-labs"


  role = "roles/logging.logWriter"


  member = "serviceAccount:${google_service_account.cloudbuild_sa.email}"


}



#######################################################
#
# SECRET MANAGER
#
#######################################################

resource "google_secret_manager_secret" "database_password" {


  depends_on = [

    google_project_service.services

  ]


  secret_id = "database-password"


  replication {

    auto {}

  }


}



#######################################################
#
# SECRET VERSION
#
#######################################################

resource "google_secret_manager_secret_version" "database_password_version" {


  secret = google_secret_manager_secret.database_password.id


  secret_data = "SuperSecretPassword123"


}



#######################################################
#
# CLOUD BUILD ACCESS TO SECRET
#
#######################################################

resource "google_secret_manager_secret_iam_member" "cloudbuild_secret_access" {


  secret_id = google_secret_manager_secret.database_password.id


  role = "roles/secretmanager.secretAccessor"


  member = "serviceAccount:${google_service_account.cloudbuild_sa.email}"


}



#######################################################
#
# CLOUD BUILD TRIGGER
#
#######################################################

resource "google_cloudbuild_trigger" "secret_pipeline" {


  depends_on = [

    google_secret_manager_secret_iam_member.cloudbuild_secret_access

  ]


  name = "secret-manager-cicd"


  description = "CI/CD pipeline accessing secrets securely"


  location = "global"


  service_account = google_service_account.cloudbuild_sa.id


  filename = "cloudbuild.yaml"



  github {


    owner = "JavierGarAgu"


    name = "Q33-Secret-Uses"


    push {


      branch = "^main$"


    }


  }


}



#######################################################
#
# OUTPUTS
#
#######################################################

output "cloudbuild_service_account" {


  value = google_service_account.cloudbuild_sa.email


}


output "secret_name" {


  value = google_secret_manager_secret.database_password.secret_id


}