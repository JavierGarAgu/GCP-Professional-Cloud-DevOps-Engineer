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

####################################################
# ENABLE GKE API
####################################################

resource "google_project_service" "container_api" {

  service = "container.googleapis.com"

  disable_on_destroy = false

}

####################################################
# GKE REGIONAL CLUSTER
####################################################

resource "google_container_cluster" "cluster" {

  name     = "capacity-planning-lab"
  location = "europe-west1"

  deletion_protection      = false
  remove_default_node_pool = true
  initial_node_count       = 1

  depends_on = [
    google_project_service.container_api
  ]

}

####################################################
# NODE POOL
####################################################

resource "google_container_node_pool" "nodes" {

  name     = "default-pool"
  cluster  = google_container_cluster.cluster.name
  location = google_container_cluster.cluster.location

  ##################################################
  # Cluster Autoscaler
  ##################################################

  autoscaling {

    min_node_count = 1
    max_node_count = 6

  }

  node_config {

    machine_type = "e2-small"

    disk_size_gb = 20

    disk_type = "pd-standard"

    preemptible = true

    oauth_scopes = [

      "https://www.googleapis.com/auth/cloud-platform"

    ]

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
# DEPLOYMENT
####################################################

resource "kubernetes_deployment" "homepage" {

  metadata {

    name      = "homepage"
    namespace = kubernetes_namespace.production.metadata[0].name

    labels = {

      app = "homepage"

    }

  }

  spec {

    replicas = 1

    selector {

      match_labels = {

        app = "homepage"

      }

    }

    template {

      metadata {

        labels = {

          app = "homepage"

        }

      }

      spec {

        container {

          name  = "homepage"
          image = "nginxdemos/hello"

          port {

            container_port = 80

          }

          ##################################################
          # CPU REQUESTS & LIMITS
          ##################################################

          resources {

            requests = {

              cpu    = "100m"
              memory = "128Mi"

            }

            limits = {

              cpu    = "500m"
              memory = "256Mi"

            }

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

    name      = "homepage"
    namespace = kubernetes_namespace.production.metadata[0].name

  }

  spec {

    selector = {

      app = "homepage"

    }

    port {

      port        = 80
      target_port = 80

    }

    type = "LoadBalancer"

  }

}

####################################################
# HORIZONTAL POD AUTOSCALER
####################################################

resource "kubernetes_horizontal_pod_autoscaler_v2" "homepage" {

  metadata {

    name      = "homepage-hpa"
    namespace = kubernetes_namespace.production.metadata[0].name

  }

  spec {

    min_replicas = 1
    max_replicas = 10

    scale_target_ref {

      api_version = "apps/v1"
      kind         = "Deployment"
      name         = kubernetes_deployment.homepage.metadata[0].name

    }

    metric {

      type = "Resource"

      resource {

        name = "cpu"

        target {

          type                = "Utilization"
          average_utilization = 70

        }

      }

    }

  }

}

####################################################
# OUTPUTS
####################################################

output "cluster_name" {

  value = google_container_cluster.cluster.name

}

output "cluster_region" {

  value = google_container_cluster.cluster.location

}

output "service_ip" {

  value = kubernetes_service.homepage.status[0].load_balancer[0].ingress[0].ip

}