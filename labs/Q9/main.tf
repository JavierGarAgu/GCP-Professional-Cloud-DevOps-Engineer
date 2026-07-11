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
# PROVIDERS
####################################################

provider "google" {

  project = "devops-cert-labs"
  region  = "europe-west1"

}

data "google_client_config" "current" {}

resource "google_container_cluster" "cluster" {

  name                     = "bluegreen-lab"
  location                 = "europe-west1-b"
  deletion_protection      = false
  remove_default_node_pool = true
  initial_node_count       = 1

}

resource "google_container_node_pool" "nodes" {

  name       = "default"
  cluster    = google_container_cluster.cluster.name
  location   = "europe-west1-b"
  node_count = 1

  node_config {

    machine_type = "e2-small"
    preemptible  = true

  }

}

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
# BLUE VERSION
####################################################

resource "kubernetes_deployment" "blue" {

  metadata {

    name = "homepage-blue"
    namespace = kubernetes_namespace.prod.metadata[0].name

  }

  spec {

    replicas = 1

    selector {

      match_labels = {

        version = "blue"

      }

    }

    template {

      metadata {

        labels = {

          version = "blue"

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

####################################################
# GREEN VERSION
####################################################

resource "kubernetes_deployment" "green" {

  metadata {

    name = "homepage-green"
    namespace = kubernetes_namespace.prod.metadata[0].name

  }

  spec {

    replicas = 1

    selector {

      match_labels = {

        version = "green"

      }

    }

    template {

      metadata {

        labels = {

          version = "green"

        }

      }

      spec {

        container {

          name  = "app"
          image = "nginxdemos/hello:plain-text"

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

resource "kubernetes_service" "homepage" {

  metadata {

    name = "homepage"
    namespace = kubernetes_namespace.prod.metadata[0].name

  }

  spec {

    selector = {

      version = "green"

      # cambiar a "green" para desplegar
      # volver a "blue" si hay problemas

    }

    port {

      port = 80

      target_port = 80

    }

    type = "LoadBalancer"

  }

}

####################################################
# OUTPUT
####################################################

output "ip" {

  value = kubernetes_service.homepage.status[0].load_balancer[0].ingress[0].ip

}