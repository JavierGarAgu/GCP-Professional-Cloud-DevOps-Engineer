terraform {

  required_version = ">= 1.5"

  required_providers {

    google = {
        source  = "hashicorp/google"
        version = ">= 5.20"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }

  }

}



#######################################################
#
# PROVIDERS
#
#######################################################

provider "google" {

  project = "devops-cert-labs"
  region  = "europe-west1"

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

resource "google_project_service" "artifactregistry" {

  service = "artifactregistry.googleapis.com"

  disable_on_destroy = false

}

resource "google_project_service" "cloudbuild" {

  service = "cloudbuild.googleapis.com"

  disable_on_destroy = false

}

resource "google_project_service" "iam" {

  service = "iam.googleapis.com"

  disable_on_destroy = false

}

resource "google_project_service" "compute" {

  service = "compute.googleapis.com"

  disable_on_destroy = false

}

#######################################################
#
# ARTIFACT REGISTRY
#
#######################################################

resource "google_artifact_registry_repository" "docker_repo" {

  depends_on = [
    google_project_service.artifactregistry
  ]

  repository_id = "cloudbuild-images"

  location = "europe-west1"

  format = "DOCKER"

  description = "Docker images built by Cloud Build"

}

#######################################################
#
# GKE CLUSTER
#
#######################################################

resource "google_container_cluster" "cluster" {

  depends_on = [
    google_project_service.container
  ]

  name = "cloudbuild-webhook-lab"

  location = "europe-west1-b"

  deletion_protection = false

  remove_default_node_pool = true

  initial_node_count = 1

}

#######################################################
#
# NODE POOL
#
#######################################################

resource "google_container_node_pool" "nodes" {

  name = "primary-pool"

  cluster = google_container_cluster.cluster.name

  location = google_container_cluster.cluster.location

  node_count = 1

  node_config {

    machine_type = "e2-small"

    disk_type = "pd-standard"

    disk_size_gb = 20

    preemptible = true

    oauth_scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

  }

}

#######################################################
#
# KUBERNETES AUTH
#
#######################################################

data "google_client_config" "current" {}

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
# CLOUD BUILD SERVICE ACCOUNT
#
#######################################################

resource "google_service_account" "cloudbuild_sa" {

  account_id = "cloudbuild-gke"

  display_name = "Cloud Build GKE Service Account"

}
#######################################################
#
# ENABLE GKE ACCESS FOR CLOUD BUILD
#
#######################################################

resource "google_project_iam_member" "cloudbuild_cluster_admin" {

  project = "devops-cert-labs"

  role = "roles/container.admin"

  member = "serviceAccount:${google_service_account.cloudbuild_sa.email}"

}

resource "google_project_iam_member" "cloudbuild_service_account_user" {

  project = "devops-cert-labs"

  role = "roles/iam.serviceAccountUser"

  member = "serviceAccount:${google_service_account.cloudbuild_sa.email}"

}

#######################################################
#
# WEBHOOK RECEIVER
#
#######################################################

resource "kubernetes_deployment" "webhook" {

  depends_on = [
    google_container_node_pool.nodes
  ]

  metadata {

    name = "webhook"

    namespace = kubernetes_namespace.production.metadata[0].name

    labels = {

      app = "webhook"

    }

  }

  spec {

    replicas = 1

    selector {

      match_labels = {

        app = "webhook"

      }

    }

    template {

      metadata {

        labels = {

          app = "webhook"

        }

      }

      spec {

        container {

          name = "webhook"

          image = "mendhak/http-https-echo:31"

          port {

            container_port = 8080

          }

          env {

            name = "HTTP_PORT"

            value = "8080"

          }

        }

      }

    }

  }

}

#######################################################
#
# WEBHOOK SERVICE
#
#######################################################
resource "kubernetes_service" "webhook" {

  metadata {

    name = "webhook"

    namespace = kubernetes_namespace.production.metadata[0].name

  }

  spec {

    selector = {
      app = "webhook"
    }

    port {
      port        = 8080
      target_port = 8080
    }

    type = "LoadBalancer"

  }

}

#######################################################
#
# CLOUD BUILD SERVICE ACCOUNT PERMISSIONS
#
#######################################################

resource "google_project_iam_member" "cloudbuild_logs" {

  project = "devops-cert-labs"

  role = "roles/logging.logWriter"

  member = "serviceAccount:${google_service_account.cloudbuild_sa.email}"

}

resource "google_project_iam_member" "cloudbuild_storage" {

  project = "devops-cert-labs"

  role = "roles/storage.admin"

  member = "serviceAccount:${google_service_account.cloudbuild_sa.email}"

}

resource "google_project_iam_member" "cloudbuild_artifact" {

  project = "devops-cert-labs"

  role = "roles/artifactregistry.writer"

  member = "serviceAccount:${google_service_account.cloudbuild_sa.email}"

}

#######################################################
#
# CLOUD BUILD TRIGGER
#
#######################################################

resource "google_cloudbuild_trigger" "build_pipeline" {
    substitutions = {

    _REGION      = "europe-west1"

    _REPOSITORY  = google_artifact_registry_repository.docker_repo.repository_id

    _IMAGE       = "webhook"

    _CLUSTER     = google_container_cluster.cluster.name

    _ZONE        = "europe-west1-b"

    _NAMESPACE   = kubernetes_namespace.production.metadata[0].name
    }

  name = "gke-build-deploy"

  description = "Build, push, deploy and notify webhook"

  location = "global"

  service_account = google_service_account.cloudbuild_sa.id

  filename = "cloudbuild.yaml"

  github {

    owner = "JavierGarAgu"

    name = "cloudbuild-webhook-lab"

    push {

      branch = "^main$"

    }

  }

}

resource "google_project_iam_member" "cloudbuild_artifact_reader" {

  project = "devops-cert-labs"

  role = "roles/artifactregistry.reader"

  member = "serviceAccount:${google_service_account.cloudbuild_sa.email}"

}

resource "google_project_iam_member" "cloudbuild_cluster_viewer" {

  project = "devops-cert-labs"

  role = "roles/container.clusterViewer"

  member = "serviceAccount:${google_service_account.cloudbuild_sa.email}"

}

#######################################################
#
# OUTPUTS
#
#######################################################
output "cluster_name" {
  value = google_container_cluster.cluster.name
}

output "artifact_registry_name" {
  value = google_artifact_registry_repository.docker_repo.repository_id
}

output "artifact_registry_url" {
  value = "europe-west1-docker.pkg.dev/devops-cert-labs/${google_artifact_registry_repository.docker_repo.repository_id}"
}

output "webhook_ip" {

  value = kubernetes_service.webhook.status[0].load_balancer[0].ingress[0].ip

}