terraform {

  required_version = ">= 1.5"

  required_providers {

    google = {

      source  = "hashicorp/google"

      version = "~> 5.0"

    }

    kubernetes = {

      source  = "hashicorp/kubernetes"

      version = "~> 2.31"

    }

  }

}

#######################################################
#
# GOOGLE PROVIDER
#
#######################################################

provider "google" {

  project = "devops-cert-labs-v3"

  region  = "europe-west1"

}

#######################################################
#
# ENABLE REQUIRED APIS
#
#######################################################

locals {

  apis = [

    "container.googleapis.com",

    "compute.googleapis.com",

    "serviceusage.googleapis.com"

  ]

}

resource "google_project_service" "services" {

  for_each = toset(local.apis)

  service = each.key

  disable_on_destroy = false

}

#######################################################
#
# NETWORK
#
#######################################################

resource "google_compute_network" "gke_network" {

  depends_on = [
    google_project_service.services
  ]

  name = "gke-lab-network"

  auto_create_subnetworks = false

}

resource "google_compute_subnetwork" "gke_subnet" {

  name = "gke-lab-subnet"

  region = "europe-west1"

  network = google_compute_network.gke_network.id

  ip_cidr_range = "10.10.0.0/24"

}

#######################################################
#
# GKE CLUSTER (single cluster, single node, lab-only)
#
#######################################################

resource "google_container_cluster" "lab" {

  depends_on = [
    google_project_service.services
  ]

  name = "game-cluster-lab"

  location = "europe-west1-b"

  network    = google_compute_network.gke_network.id
  subnetwork = google_compute_subnetwork.gke_subnet.id

  deletion_protection = false

  remove_default_node_pool = true

  initial_node_count = 1

}

resource "google_container_node_pool" "lab_nodes" {

  name = "primary-pool"

  location = "europe-west1-b"

  cluster = google_container_cluster.lab.name

  node_count = 1

  node_config {

    machine_type = "e2-medium"

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

  }

}

#######################################################
#
# KUBERNETES PROVIDER (points at the lab cluster)
#
#######################################################

data "google_client_config" "default" {}

provider "kubernetes" {

  host                   = "https://${google_container_cluster.lab.endpoint}"
  token                  = data.google_client_config.default.access_token
  cluster_ca_certificate = base64decode(google_container_cluster.lab.master_auth[0].cluster_ca_certificate)

}

#######################################################
#
# WEB SERVER STATEFULSET
#
# Phased rollout to half of the pods: with 4 replicas
# and partition = 2, only pods with ordinal >= 2
# (web-server-2, web-server-3) pick up a pod template
# change. web-server-0 and web-server-1 stay on the old
# version until the partition is lowered (e.g. to 0) to
# finish the rollout. This is "Use a partitioned rolling
# update" (option A).
#
#######################################################

resource "kubernetes_stateful_set" "web_server" {

  depends_on = [
    google_container_node_pool.lab_nodes
  ]

  wait_for_rollout = false

  metadata {

    name = "web-server"

    labels = {
      app = "web-server"
    }

  }

  spec {

    service_name = "web-server"
    replicas     = 4

    selector {
      match_labels = {
        app = "web-server"
      }
    }

    update_strategy {

      type = "RollingUpdate"

      rolling_update {
        partition = 2
      }

    }

    template {

      metadata {
        labels = {
          app = "web-server"
        }
      }

      spec {

        container {

          name  = "web-server"
          image = "nginx:1.25"

          port {
            container_port = 80
          }

        }

      }

    }

  }

}

#######################################################
#
# OUTPUTS
#
#######################################################

output "cluster_name" {
  value = google_container_cluster.lab.name
}

output "cluster_endpoint" {
  value = google_container_cluster.lab.endpoint
}

output "statefulset_partition" {
  value = kubernetes_stateful_set.web_server.spec[0].update_strategy[0].rolling_update[0].partition
}
