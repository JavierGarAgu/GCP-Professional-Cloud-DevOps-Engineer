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

  project = "devops-cert-labs-v4"
  region  = "europe-west1"

}

#######################################################
#
# DATA
#
#######################################################

data "google_project" "project" {

  project_id = "devops-cert-labs-v4"

}

#######################################################
#
# ENABLE APIS
#
#######################################################

locals {

  apis = [

    "container.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com"

  ]

}

resource "google_project_service" "apis" {

  for_each = toset(local.apis)

  service = each.key

  disable_on_destroy = false

}

#######################################################
#
# GKE STANDARD CLUSTER
#
#######################################################

resource "google_container_cluster" "cluster" {

  depends_on = [
    google_project_service.apis
  ]

  name = "prometheus-demo"

  location = "europe-west1-b"


  deletion_protection = false


  remove_default_node_pool = true

  initial_node_count = 1


  networking_mode = "VPC_NATIVE"


  network = "default"

  subnetwork = "default"


  workload_identity_config {

    workload_pool = "${data.google_project.project.project_id}.svc.id.goog"

  }


  monitoring_config {

    managed_prometheus {

      enabled = true

    }

  }


}



resource "google_container_node_pool" "primary" {


  cluster = google_container_cluster.cluster.name


  location = google_container_cluster.cluster.location


  name = "prometheus-pool"


  node_count = 1



  node_config {


    machine_type = "e2-standard-2"


    disk_size_gb = 50


    oauth_scopes = [

      "https://www.googleapis.com/auth/cloud-platform"

    ]


    workload_metadata_config {

      mode = "GKE_METADATA"

    }


  }


}

#######################################################
#
# OUTPUTS
#
#######################################################

output "cluster_name" {

  value = google_container_cluster.cluster.name

}

output "cluster_region" {

  value = google_container_cluster.cluster.location

}

output "project_id" {

  value = data.google_project.project.project_id

}

output "connect_cluster" {

  value = "gcloud container clusters get-credentials ${google_container_cluster.cluster.name} --region ${google_container_cluster.cluster.location}"

}