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

  project = "devops-cert-labs-v4"
  region  = "europe-west1"

}

data "google_client_config" "current" {}

####################################################
# GKE CLUSTER
####################################################

resource "google_container_cluster" "cluster" {

  name                     = "bluegreen-q111"
  location                 = "europe-west1-b"

  deletion_protection      = false

  remove_default_node_pool = true
  initial_node_count       = 1

}

####################################################
# NODE POOL
####################################################

resource "google_container_node_pool" "nodes" {

  name     = "default-pool"

  cluster  = google_container_cluster.cluster.name

  location = "europe-west1-b"

  node_count = 1

  node_config {

    machine_type = "e2-small"

    disk_size_gb = 20

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

resource "kubernetes_namespace" "production" {

  metadata {

    name = "production"

  }

}

####################################################
# BLUE DEPLOYMENT (WORKING VERSION)
####################################################

resource "kubernetes_deployment" "app_blue" {

  metadata {

    name      = "app-blue"
    namespace = kubernetes_namespace.production.metadata[0].name

    labels = {

      app     = "my-app"
      version = "blue"

    }

  }

  spec {

    replicas = 1

    selector {

      match_labels = {

        app     = "my-app"
        version = "blue"

      }

    }

    template {

      metadata {

        labels = {

          app     = "my-app"
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
# GREEN DEPLOYMENT (BROKEN VERSION)
####################################################

resource "kubernetes_deployment" "app_green" {

  metadata {

    name      = "app-green"
    namespace = kubernetes_namespace.production.metadata[0].name

    labels = {

      app     = "my-app"
      version = "green"

    }

  }

  spec {

    replicas = 1

    selector {

      match_labels = {

        app     = "my-app"
        version = "green"

      }

    }

    template {

      metadata {

        labels = {

          app     = "my-app"
          version = "green"

        }

      }

      spec {

        container {

          name = "app"

          #
          # Broken image to simulate a failed deployment
          #

          image = "nginxdemos/hello-does-not-exist"

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

resource "kubernetes_service" "app_service" {

  metadata {

    name      = "app-svc"

    namespace = kubernetes_namespace.production.metadata[0].name

  }

  spec {

    #
    # Initially send all traffic to Green
    #

    selector = {

      app     = "my-app"

      version = "green"

    }

    port {

      port        = 80

      target_port = 80

    }

    type = "NodePort"

  }

}

####################################################
# INGRESS
####################################################

resource "kubernetes_ingress_v1" "app_ingress" {

  metadata {

    name      = "app-ingress"

    namespace = kubernetes_namespace.production.metadata[0].name

  }

  spec {

    default_backend {

      service {

        name = kubernetes_service.app_service.metadata[0].name

        port {

          number = 80

        }

      }

    }

  }

}

####################################################
# LOAD BALANCER
####################################################

resource "kubernetes_service" "ingress_lb" {

  metadata {

    name      = "ingress-lb"

    namespace = "ingress-nginx"

  }

  spec {

    type = "LoadBalancer"

    selector = {

      "app.kubernetes.io/name" = "ingress-nginx"

    }

    port {

      port = 80

      target_port = 80

    }

  }

}

####################################################
# OUTPUTS
####################################################

output "service_selector" {

  value = kubernetes_service.app_service.spec[0].selector

}

output "service_name" {

  value = kubernetes_service.app_service.metadata[0].name

}

output "namespace" {

  value = kubernetes_namespace.production.metadata[0].name

}