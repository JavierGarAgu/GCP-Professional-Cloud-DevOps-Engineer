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

#################################################
# PROVIDER
#################################################

provider "google" {

  project = "devops-cert-labs-v3"
  region  = "europe-west1"

}

#################################################
# ENABLE REQUIRED APIS
#################################################

locals {

  apis = [

    "container.googleapis.com",
    "pubsub.googleapis.com"

  ]

}

resource "google_project_service" "services" {

  for_each = toset(local.apis)

  service = each.key

  disable_on_destroy = false

}

#################################################
# PUB/SUB
#################################################

resource "google_pubsub_topic" "orders" {

  depends_on = [

    google_project_service.services

  ]

  name = "orders-topic"

}

resource "google_pubsub_subscription" "warehouse" {

  depends_on = [

    google_pubsub_topic.orders

  ]

  name  = "warehouse-subscription"

  topic = google_pubsub_topic.orders.name

}

#################################################
# GKE AUTOPILOT
#################################################

resource "google_container_cluster" "cluster" {

  depends_on = [

    google_project_service.services

  ]

  name     = "warehouse-cluster"
  location = "europe-west1"

  enable_autopilot = true

  deletion_protection = false

}

#################################################
# KUBERNETES PROVIDER
#################################################

data "google_client_config" "current" {}

provider "kubernetes" {

  host = "https://${google_container_cluster.cluster.endpoint}"

  token = data.google_client_config.current.access_token

  cluster_ca_certificate = base64decode(
    google_container_cluster.cluster.master_auth[0].cluster_ca_certificate
  )

}

#################################################
# NAMESPACE
#################################################

resource "kubernetes_namespace" "warehouse" {

  metadata {

    name = "warehouse"

  }

}

#################################################
# DEPLOYMENT
#################################################

resource "kubernetes_deployment" "consumer" {

  metadata {

    name = "warehouse-consumer"

    namespace = kubernetes_namespace.warehouse.metadata[0].name

  }

  spec {

    replicas = 1

    selector {

      match_labels = {

        app = "warehouse"

      }

    }

    template {

      metadata {

        labels = {

          app = "warehouse"

        }

      }

      spec {

        container {

          name = "consumer"

          image = "gcr.io/google-samples/hello-app:1.0"

          port {

            container_port = 8080

          }

        }

      }

    }

  }

}

#################################################
# SERVICE
#################################################

resource "kubernetes_service" "consumer" {

  metadata {

    name = "warehouse-service"

    namespace = kubernetes_namespace.warehouse.metadata[0].name

  }

  spec {

    selector = {

      app = "warehouse"

    }

    port {

      port        = 80
      target_port = 8080

    }

    type = "ClusterIP"

  }

}

#################################################
# OUTPUTS
#################################################

output "cluster_name" {

  value = google_container_cluster.cluster.name

}

output "topic_name" {

  value = google_pubsub_topic.orders.name

}

output "subscription_name" {

  value = google_pubsub_subscription.warehouse.name

}