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

provider "google" {
  project = "devops-cert-labs-v2"
  region  = "europe-west1"
}

#
# GKE CLUSTER

#

resource "google_container_cluster" "cluster" {
  name                     = "logging-sidecar-lab"
  location                 = "europe-west1-b"
  deletion_protection      = false
  remove_default_node_pool = true
  initial_node_count       = 1
}

#
# NODE POOL
#

resource "google_container_node_pool" "nodes" {
  name     = "node-pool"
  cluster  = google_container_cluster.cluster.name
  location = google_container_cluster.cluster.location

  node_count = 1

  node_config {
    machine_type = "e2-small"
    disk_type    = "pd-standard"
    disk_size_gb = 20
    preemptible  = true
  }
}

#
# KUBERNETES AUTH
#

data "google_client_config" "current" {}

provider "kubernetes" {
  host = "https://${google_container_cluster.cluster.endpoint}"

  token = data.google_client_config.current.access_token

  cluster_ca_certificate = base64decode(
    google_container_cluster.cluster.master_auth[0].cluster_ca_certificate
  )
}

#
# NAMESPACE
#

resource "kubernetes_namespace" "production" {
  depends_on = [google_container_node_pool.nodes]

  metadata {
    name = "production"
  }
}

#
# THIRD PARTY APPLICATION
#

resource "kubernetes_deployment" "third_party_app" {

  depends_on = [google_container_node_pool.nodes]

  metadata {
    name      = "third-party-app"
    namespace = kubernetes_namespace.production.metadata[0].name

    labels = {
      app = "third-party"
    }
  }

  spec {

    replicas = 1

    selector {
      match_labels = {
        app = "third-party"
      }
    }

    template {

      metadata {
        labels = {
          app = "third-party"
        }
      }

      spec {

        volume {
          name = "logs"

          empty_dir {}
        }

        #
        # THIRD PARTY APPLICATION
        #

        container {

          name  = "third-party-app"
          image = "busybox"

          command = [
            "sh",
            "-c"
          ]

          args = [
            "touch /var/log/app_messages.log && while true; do echo \"Application log $(date)\" >> /var/log/app_messages.log; sleep 5; done"
          ]

          volume_mount {
            name       = "logs"
            mount_path = "/var/log"
          }

        }

        #
        # Stackdriver logging agent intentionally missing.
        #
        # The application writes logs successfully to
        # /var/log/app_messages.log, but no component is
        # installed to collect and forward them to
        # Cloud Logging (Stackdriver).
        #
        # Troubleshooting:
        # Confirm that the Stackdriver agent has been
        # installed in the hosting virtual machine.
        #

      }
    }
  }
}

