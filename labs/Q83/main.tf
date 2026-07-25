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
# GOOGLE PROVIDER
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

  name                    = "asm-network"
  auto_create_subnetworks = false

}

resource "google_compute_subnetwork" "subnet" {

  name          = "asm-subnet"
  region        = "europe-west1"
  network       = google_compute_network.network.id
  ip_cidr_range = "10.10.0.0/24"

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

  name                     = "asm-cluster"
  location                 = "europe-west1-b"

  network    = google_compute_network.network.id
  subnetwork = google_compute_subnetwork.subnet.id

  remove_default_node_pool = true
  initial_node_count       = 1

  deletion_protection = false

}

resource "google_container_node_pool" "nodes" {

  name     = "primary"
  cluster  = google_container_cluster.cluster.name
  location = "europe-west1-b"

  node_count = 1

  node_config {

    machine_type = "e2-medium"

  }

}

#######################################################
#
# KUBERNETES PROVIDER
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
# APP V1
#
#######################################################

resource "kubernetes_deployment" "app_v1" {

  metadata {

    name      = "app-v1"
    namespace = kubernetes_namespace.production.metadata[0].name

    labels = {

      version = "v1"

    }

  }

  spec {

    replicas = 1

    selector {

      match_labels = {

        app     = "demo"
        version = "v1"

      }

    }

    template {

      metadata {

        labels = {

          app     = "demo"
          version = "v1"

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
# APP V2
#
#######################################################

resource "kubernetes_deployment" "app_v2" {

  metadata {

    name      = "app-v2"
    namespace = kubernetes_namespace.production.metadata[0].name

    labels = {

      version = "v2"

    }

  }

  spec {

    replicas = 1

    selector {

      match_labels = {

        app     = "demo"
        version = "v2"

      }

    }

    template {

      metadata {

        labels = {

          app     = "demo"
          version = "v2"

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