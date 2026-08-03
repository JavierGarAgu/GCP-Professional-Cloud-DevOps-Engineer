terraform {

  required_version = ">= 1.5"

  required_providers {

    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.35"
    }

  }

}

provider "google" {

  project = "devops-cert-labs-v4"
  region  = "europe-west1"

}

resource "google_project_service" "container" {

  project = "devops-cert-labs-v4"
  service = "container.googleapis.com"

  disable_on_destroy = false

}

resource "google_project_service" "compute" {

  project = "devops-cert-labs-v4"
  service = "compute.googleapis.com"

  disable_on_destroy = false

}

resource "google_project_service" "artifact" {

  project = "devops-cert-labs-v4"
  service = "artifactregistry.googleapis.com"

  disable_on_destroy = false

}
resource "google_container_cluster" "gke_cluster" {

  name     = "liveness-demo-cluster"
  location = "europe-west1-b"

  deletion_protection = false

  remove_default_node_pool = true

  initial_node_count = 1

  network    = "default"
  subnetwork = "default"

  depends_on = [

    google_project_service.container,
    google_project_service.compute

  ]

}

resource "google_container_node_pool" "primary_nodes" {

  name     = "primary-node-pool"
  cluster  = google_container_cluster.gke_cluster.id
  location = "europe-west1-b"

  node_count = 1

  node_config {

    machine_type = "e2-medium"

    disk_size_gb = 30
    disk_type    = "pd-balanced"

    oauth_scopes = [

      "https://www.googleapis.com/auth/cloud-platform"

    ]

    labels = {

      environment = "lab"

    }

    tags = [

      "gke-node"

    ]

  }

}
data "google_client_config" "default" {}

provider "kubernetes" {

  host = "https://${google_container_cluster.gke_cluster.endpoint}"

  token = data.google_client_config.default.access_token

  cluster_ca_certificate = base64decode(
    google_container_cluster.gke_cluster.master_auth[0].cluster_ca_certificate
  )

}

resource "kubernetes_namespace" "demo" {

  metadata {

    name = "liveness-demo"

  }

}

resource "kubernetes_deployment" "nginx" {

  metadata {

    name      = "nginx-demo"
    namespace = kubernetes_namespace.demo.metadata[0].name

    labels = {

      app = "nginx"

    }

  }

  spec {

    replicas = 1

    selector {

      match_labels = {

        app = "nginx"

      }

    }

    template {

      metadata {

        labels = {

          app = "nginx"

        }

      }

      spec {

        container {

          name  = "nginx"
          image = "nginx:latest"

          port {

            container_port = 80

          }

          liveness_probe {

            http_get {

              path = "/"
              port = 80

            }

            initial_delay_seconds = 10
            period_seconds        = 10
            timeout_seconds       = 5
            failure_threshold     = 3

          }

        }

      }

    }

  }

  depends_on = [

    google_container_node_pool.primary_nodes

  ]

}

resource "kubernetes_service" "nginx" {

  metadata {

    name      = "nginx-service"
    namespace = kubernetes_namespace.demo.metadata[0].name

  }

  spec {

    selector = {

      app = "nginx"

    }

    port {

      port        = 80
      target_port = 80

    }

    type = "LoadBalancer"

  }

}
output "cluster_name" {

  description = "GKE Cluster Name"

  value = google_container_cluster.gke_cluster.name

}

output "cluster_endpoint" {

  description = "GKE Cluster Endpoint"

  value = google_container_cluster.gke_cluster.endpoint

}

output "cluster_location" {

  description = "GKE Cluster Zone"

  value = google_container_cluster.gke_cluster.location

}

output "namespace" {

  description = "Kubernetes Namespace"

  value = kubernetes_namespace.demo.metadata[0].name

}

output "deployment_name" {

  description = "Deployment Name"

  value = kubernetes_deployment.nginx.metadata[0].name

}

output "service_name" {

  description = "Service Name"

  value = kubernetes_service.nginx.metadata[0].name

}

output "load_balancer_ip" {

  description = "Load Balancer External IP"

  value = try(
    kubernetes_service.nginx.status[0].load_balancer[0].ingress[0].ip,
    "Pending..."
  )

}