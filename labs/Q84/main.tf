#######################################################
#
# TERRAFORM
#
#######################################################

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
# GOOGLE
#
#######################################################

provider "google" {

  project = "devops-cert-labs-v3"
  region  = "europe-west1"

}

#######################################################
#
# APIS
#
#######################################################

locals {

  apis = [

    "container.googleapis.com",
    "compute.googleapis.com",
    "serviceusage.googleapis.com"

  ]

}

resource "google_project_service" "apis" {

  for_each = toset(local.apis)

  service = each.key

  disable_on_destroy = false

}

#######################################################
#
# NETWORK
#
#######################################################

resource "google_compute_network" "network" {

  name = "slo-network"

  auto_create_subnetworks = false

}

resource "google_compute_subnetwork" "subnet" {

  name          = "slo-subnet"
  region        = "europe-west1"
  network       = google_compute_network.network.id
  ip_cidr_range = "10.20.0.0/24"

}

#######################################################
#
# GKE
#
#######################################################

resource "google_container_cluster" "cluster" {

  depends_on = [
    google_project_service.apis
  ]

  name     = "slo-cluster"
  location = "europe-west1-b"

  network    = google_compute_network.network.id
  subnetwork = google_compute_subnetwork.subnet.id

  remove_default_node_pool = true
  initial_node_count       = 1

  deletion_protection = false

}

resource "google_container_node_pool" "nodes" {

  name     = "primary"
  cluster  = google_container_cluster.cluster.name
  location = google_container_cluster.cluster.location

  node_count = 1

  node_config {

    machine_type = "e2-medium"

  }

}

#######################################################
#
# KUBERNETES
#
#######################################################

data "google_client_config" "default" {}

provider "kubernetes" {

  host = "https://${google_container_cluster.cluster.endpoint}"

  token = data.google_client_config.default.access_token

  cluster_ca_certificate = base64decode(
    google_container_cluster.cluster.master_auth[0].cluster_ca_certificate
  )

}

#######################################################
#
# NAMESPACE
#
#######################################################

resource "kubernetes_namespace" "production" {

  depends_on = [
    google_container_node_pool.nodes
  ]

  metadata {

    name = "production"

  }

}

#######################################################
#
# APPLICATION
#
#######################################################

resource "kubernetes_deployment" "app" {

  metadata {

    name      = "demo-app"
    namespace = kubernetes_namespace.production.metadata[0].name

  }

  spec {

    replicas = 2

    selector {

      match_labels = {

        app = "demo"

      }

    }

    template {

      metadata {

        labels = {

          app = "demo"

        }

      }

      spec {

        container {

          name  = "app"
          image = "nginxdemos/hello"

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
# SERVICE
#
#######################################################

resource "kubernetes_service" "app" {

  metadata {

    name      = "demo-service"
    namespace = kubernetes_namespace.production.metadata[0].name

  }

  spec {

    selector = {

      app = "demo"

    }

    port {

      port        = 80
      target_port = 80

    }

    type = "LoadBalancer"

  }

}

#######################################################
#
# SIMULATED SLO
#
#######################################################

resource "kubernetes_config_map" "slo" {

  metadata {

    name      = "service-slo"
    namespace = kubernetes_namespace.production.metadata[0].name

  }

  data = {

    slo_name       = "availability"
    objective      = "99.9%"
    sli            = "request_success_rate"
    error_budget   = "0.1%"
    alert_policy   = "select_slo_burn_rate"

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

output "external_ip" {

  value = try(

    kubernetes_service.app.status[0].load_balancer[0].ingress[0].ip,

    "Pending..."

  )

}

output "configured_slo" {

  value = "Availability SLO 99.9% with alert on select_slo_burn_rate"

}