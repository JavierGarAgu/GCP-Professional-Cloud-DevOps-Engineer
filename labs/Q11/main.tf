terraform {

  required_providers {

    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }

  }

}

####################################################
# PROVIDER
####################################################

provider "google" {

  project = "devops-cert-labs"
  region  = "europe-west1"

}

data "google_client_config" "current" {}

####################################################
# ENABLE APIS
####################################################

resource "google_project_service" "container" {

  service = "container.googleapis.com"

  disable_on_destroy = false

}

####################################################
# NETWORK
####################################################

resource "google_compute_network" "vpc" {

  name = "premium-tier-network"

}

resource "google_compute_subnetwork" "subnet" {

  name          = "gke-subnet"
  region        = "europe-west1"
  network       = google_compute_network.vpc.id
  ip_cidr_range = "10.10.0.0/16"

}

####################################################
# GKE
####################################################

resource "google_container_cluster" "cluster" {

  depends_on = [
    google_project_service.container
  ]

  name                     = "network-tier-lab"

  location                 = "europe-west1-b"

  deletion_protection      = false

  remove_default_node_pool = true

  initial_node_count       = 1

  network    = google_compute_network.vpc.id
  subnetwork = google_compute_subnetwork.subnet.id

}

resource "google_container_node_pool" "nodes" {

  name       = "default"

  cluster    = google_container_cluster.cluster.name

  location   = "europe-west1-b"

  node_count = 1

  node_config {

    machine_type = "e2-small"

    preemptible = true

  }

}

####################################################
# KUBERNETES PROVIDER
####################################################

provider "kubernetes" {

  host = "https://${google_container_cluster.cluster.endpoint}"

  token = data.google_client_config.current.access_token

  cluster_ca_certificate = base64decode(
    google_container_cluster.cluster.master_auth[0].cluster_ca_certificate
  )

}

####################################################
# NAMESPACE
####################################################

resource "kubernetes_namespace" "prod" {

  metadata {

    name = "production"

  }

}

####################################################
# DEPLOYMENT
####################################################

resource "kubernetes_deployment" "backend" {

  metadata {

    name      = "mobile-game-backend"

    namespace = kubernetes_namespace.prod.metadata[0].name

  }

  spec {

    replicas = 2

    selector {

      match_labels = {

        app = "backend"

      }

    }

    template {

      metadata {

        labels = {

          app = "backend"

        }

      }

      spec {

        container {

          name = "backend"

          image = "nginxdemos/hello"

          port {

            container_port = 80

          }

        }

      }

    }

  }

}

####################################################
# SERVICE
####################################################

resource "kubernetes_service" "backend" {

  metadata {

    name = "backend"

    namespace = kubernetes_namespace.prod.metadata[0].name

    annotations = {

      #
      # GOOGLE EXAM OBJECTIVE
      #
      # premium Tier reduces outbound networking costs.
      #

      "cloud.google.com/network-tier" = "PREMIUM"

    }

  }

  spec {

    selector = {

      app = "backend"

    }

    port {

      port = 80

      target_port = 80

    }

    type = "LoadBalancer"

  }

}

####################################################
# STATIC IP
####################################################

resource "google_compute_address" "lb_ip" {

  name = "backend-ip"

  region = "europe-west1"

  network_tier = "PREMIUM"

}

####################################################
# OUTPUTS
####################################################

output "load_balancer_ip" {

  value = kubernetes_service.backend.status[0].load_balancer[0].ingress[0].ip

}

output "network_tier" {

  value = google_compute_address.lb_ip.network_tier

}

# terraform destroy -auto-approve && terraform apply -auto-approve