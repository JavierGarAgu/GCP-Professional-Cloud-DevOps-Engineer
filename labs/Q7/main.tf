terraform {

  required_version = ">= 1.5"

  required_providers {

    google = {

      source  = "hashicorp/google"
      version = ">= 5.20"

    }

    kubernetes = {

      source  = "hashicorp/kubernetes"
      version = "~> 2.38"

    }

  }

}

#######################################################
#
# PROVIDER
#
#######################################################

provider "google" {

  project = "devops-cert-labs"

  region = "europe-west1"

}

#######################################################
#
# REQUIRED APIS
#
#######################################################

resource "google_project_service" "container" {

  service = "container.googleapis.com"

  disable_on_destroy = false

}

resource "google_project_service" "compute" {

  service = "compute.googleapis.com"

  disable_on_destroy = false

}

resource "google_project_service" "iam" {

  service = "iam.googleapis.com"

  disable_on_destroy = false

}

#######################################################
#
# GKE NODE SERVICE ACCOUNT
#
#######################################################

resource "google_service_account" "gke_node_sa" {

  account_id = "spinnaker-node-sa"

  display_name = "Spinnaker GKE Node Service Account"

}

resource "google_project_iam_member" "artifact_reader" {

  project = "devops-cert-labs"

  role = "roles/artifactregistry.reader"

  member = "serviceAccount:${google_service_account.gke_node_sa.email}"

}

#######################################################
#
# NETWORK
#
#######################################################

resource "google_compute_network" "vpc" {

  name = "spinnaker-vpc"

  auto_create_subnetworks = true

}
#######################################################
#
# GKE CLUSTER
#
#######################################################

resource "google_container_cluster" "cluster" {

  depends_on = [

    google_project_service.container,

    google_project_service.compute,

    google_project_service.iam

  ]

  name = "spinnaker-canary-lab"

  location = "europe-west1-b"

  deletion_protection = false

  remove_default_node_pool = true

  initial_node_count = 1

  network = google_compute_network.vpc.name

}

#######################################################
#
# NODE POOL
#
#######################################################

resource "google_container_node_pool" "primary_nodes" {

  name = "primary-pool"

  cluster = google_container_cluster.cluster.name

  location = google_container_cluster.cluster.location

  depends_on = [

    google_project_iam_member.artifact_reader

  ]

  node_count = 1

  node_config {

    machine_type = "e2-small"

    disk_type = "pd-standard"

    disk_size_gb = 20

    preemptible = true

    service_account = google_service_account.gke_node_sa.email

    oauth_scopes = [

      "https://www.googleapis.com/auth/cloud-platform"

    ]

  }

}

#######################################################
#
# GOOGLE CLIENT CONFIG
#
#######################################################

data "google_client_config" "current" {}

#######################################################
#
# KUBERNETES PROVIDER
#
#######################################################

provider "kubernetes" {

  host = "https://${google_container_cluster.cluster.endpoint}"

  token = data.google_client_config.current.access_token

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

  metadata {

    name = "production"

  }

}
#######################################################
#
# PRODUCTION CURRENT
#
#######################################################

resource "kubernetes_deployment" "production_current" {

  metadata {

    name = "production-current"

    namespace = kubernetes_namespace.production.metadata[0].name

    labels = {

      app = "demo"

      version = "current"

    }

  }

  spec {

    replicas = 1

    selector {

      match_labels = {

        app = "demo"

        version = "current"

      }

    }

    template {

      metadata {

        labels = {

          app = "demo"

          version = "current"

        }

      }

      spec {

        container {

          name = "demo"

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
# PRODUCTION BASELINE
#
#######################################################

resource "kubernetes_deployment" "production_baseline" {

  metadata {

    name = "production-baseline"

    namespace = kubernetes_namespace.production.metadata[0].name

    labels = {

      app = "demo"

      version = "baseline"

    }

  }

  spec {

    replicas = 1

    selector {

      match_labels = {

        app = "demo"

        version = "baseline"

      }

    }

    template {

      metadata {

        labels = {

          app = "demo"

          version = "baseline"

        }

      }

      spec {

        container {

          name = "demo"

          image = "nginx:1.25"

          # MISMA versión que producción.
          # Este deployment representa la nueva copia
          # que Spinnaker utilizaría como baseline.

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
# CANARY
#
#######################################################

resource "kubernetes_deployment" "canary" {

  metadata {

    name = "canary"

    namespace = kubernetes_namespace.production.metadata[0].name

    labels = {

      app = "demo"

      version = "canary"

    }

  }

  spec {

    replicas = 1

    selector {

      match_labels = {

        app = "demo"

        version = "canary"

      }

    }

    template {

      metadata {

        labels = {

          app = "demo"

          version = "canary"

        }

      }

      spec {

        container {

          name = "demo"

          image = "nginx:1.26"

          # Nueva versión que queremos validar.

          port {

            container_port = 80

          }

        }

      }

    }

  }

}