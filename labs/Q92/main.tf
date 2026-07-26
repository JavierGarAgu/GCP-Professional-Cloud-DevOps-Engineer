terraform {

  required_version = ">= 1.5"

  required_providers {

    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.30"
    }

  }

}

#######################################################
#
# PROVIDERS
#
#######################################################

provider "google" {

  project = "devops-cert-labs-v3"
  region  = "europe-west1"

}

#######################################################
#
# ENABLE APIS
#
#######################################################

locals {

  apis = [

    "container.googleapis.com",
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
# GOOGLE SERVICE ACCOUNT
#
#######################################################

resource "google_service_account" "terraform_sa" {

  account_id   = "terraform-deployer"
  display_name = "Terraform Deployment Service Account"

}

#######################################################
#
# IAM ROLES
#
#######################################################

resource "google_project_iam_member" "container_admin" {

  project = "devops-cert-labs-v3"

  role = "roles/container.admin"

  member = "serviceAccount:${google_service_account.terraform_sa.email}"

}

resource "google_project_iam_member" "compute_admin" {

  project = "devops-cert-labs-v3"

  role = "roles/compute.admin"

  member = "serviceAccount:${google_service_account.terraform_sa.email}"

}

resource "google_project_iam_member" "service_account_user" {

  project = "devops-cert-labs-v3"

  role = "roles/iam.serviceAccountUser"

  member = "serviceAccount:${google_service_account.terraform_sa.email}"

}

#######################################################
#
# GKE CLUSTER
#
#######################################################

resource "google_container_cluster" "cluster" {

  depends_on = [

    google_project_service.services

  ]

  name     = "terraform-cluster"
  location = "europe-west1-b"

  deletion_protection = false

  remove_default_node_pool = true
  initial_node_count       = 1

  workload_identity_config {

    workload_pool = "devops-cert-labs-v3.svc.id.goog"

  }

}

resource "google_container_node_pool" "primary_pool" {

  name     = "primary-pool"
  cluster  = google_container_cluster.cluster.name
  location = google_container_cluster.cluster.location

  node_count = 1

  node_config {

    machine_type = "e2-medium"

    workload_metadata_config {

      mode = "GKE_METADATA"

    }

  }

}

#######################################################
#
# KUBERNETES PROVIDER
#
#######################################################

data "google_client_config" "current" {}

provider "kubernetes" {

  host = "https://${google_container_cluster.cluster.endpoint}"

  token = data.google_client_config.current.access_token

  cluster_ca_certificate = base64decode(
    google_container_cluster.cluster.master_auth[0].cluster_ca_certificate
  )

}

#######################################################
#
# KUBERNETES SERVICE ACCOUNT
#
#######################################################

resource "kubernetes_service_account" "terraform_runner" {

  metadata {

    name      = "terraform-runner"
    namespace = "default"

    annotations = {
      "iam.gke.io/gcp-service-account" = google_service_account.terraform_sa.email
    }

  }

}

#######################################################
#
# WORKLOAD IDENTITY
#
#######################################################

resource "google_service_account_iam_member" "workload_identity" {

  depends_on = [
    google_container_cluster.cluster
  ]

  service_account_id = google_service_account.terraform_sa.name

  role = "roles/iam.workloadIdentityUser"

  member = "serviceAccount:devops-cert-labs-v3.svc.id.goog[default/terraform-runner]"

}

#######################################################
#
# OUTPUTS
#
#######################################################

output "google_service_account" {

  value = google_service_account.terraform_sa.email

}

output "kubernetes_service_account" {

  value = kubernetes_service_account.terraform_runner.metadata[0].name

}

output "cluster_name" {

  value = google_container_cluster.cluster.name

}
