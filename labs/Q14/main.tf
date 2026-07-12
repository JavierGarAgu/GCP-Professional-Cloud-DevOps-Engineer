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

#######################################################
#
# PROVIDER
#
#######################################################

provider "google" {

  project = "devops-cert-labs"
  region  = "europe-west1"

}

#######################################################
#
# ENABLE REQUIRED APIS
#
#######################################################

resource "google_project_service" "compute" {

  service = "compute.googleapis.com"

  disable_on_destroy = false

}

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

resource "google_project_service" "run" {

  service = "run.googleapis.com"

  disable_on_destroy = false

}

resource "google_project_service" "pubsub" {

  service = "pubsub.googleapis.com"

  disable_on_destroy = false

}

resource "google_project_service" "iam" {

  service = "iam.googleapis.com"

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

  repository_id = "deployment-images"

  location = "europe-west1"

  format = "DOCKER"

  description = "Images built by Cloud Build"

}

#######################################################
#
# GKE NODE SERVICE ACCOUNT
#
#######################################################

resource "google_service_account" "gke_node_sa" {

  account_id   = "gke-node-sa"

  display_name = "GKE Node Service Account"

}

resource "google_project_iam_member" "artifact_reader" {

  project = "devops-cert-labs"

  role = "roles/artifactregistry.reader"

  member = "serviceAccount:${google_service_account.gke_node_sa.email}"

}

#######################################################
#
# GKE CLUSTER
#
#######################################################

#######################################################
#
# GKE CLUSTER
#
#######################################################

resource "google_container_cluster" "cluster" {

  depends_on = [
    google_project_service.container
  ]

  name = "event-driven-gke"

  location = "europe-west1-b"

  deletion_protection = false

  remove_default_node_pool = true

  initial_node_count = 1


  release_channel {

    channel = "REGULAR"

  }


  networking_mode = "VPC_NATIVE"


  workload_identity_config {

    workload_pool = "devops-cert-labs.svc.id.goog"

  }


  addons_config {

    horizontal_pod_autoscaling {

      disabled = false

    }


    http_load_balancing {

      disabled = false

    }

  }


  maintenance_policy {

    recurring_window {

      start_time = "2026-07-12T02:00:00Z"

      end_time   = "2026-07-12T06:00:00Z"

      recurrence = "FREQ=WEEKLY;BYDAY=SA"

    }

  }


  resource_labels = {

    environment = "lab"

    managed_by  = "terraform"

    purpose     = "event-driven-deployment"

  }

}
#######################################################
#
# NODE POOL
#
#######################################################

#######################################################
#
# NODE POOL
#
#######################################################

resource "google_container_node_pool" "primary_pool" {

  name = "primary-pool"


  cluster = google_container_cluster.cluster.name


  location = google_container_cluster.cluster.location


  node_count = 2


  management {

    auto_repair  = true

    auto_upgrade = true

  }


  upgrade_settings {

    max_surge       = 1

    max_unavailable = 0

  }


  node_config {


    machine_type = "e2-medium"


    disk_type = "pd-standard"


    disk_size_gb = 30


    service_account = google_service_account.gke_node_sa.email


    oauth_scopes = [

      "https://www.googleapis.com/auth/cloud-platform"

    ]


    labels = {

      workload = "webapp"

      env      = "production"

    }


    shielded_instance_config {

      enable_secure_boot = true

      enable_integrity_monitoring = true

    }


    workload_metadata_config {

      mode = "GKE_METADATA"

    }


  }

}

#######################################################
#
# KUBERNETES PROVIDER
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
# PUB/SUB
#
#######################################################

resource "google_pubsub_topic" "deployment_topic" {

  depends_on = [
    google_project_service.pubsub
  ]

  name = "deployment-events"

}

#######################################################
#
# DEPLOYMENT SERVICE ACCOUNT
#
#######################################################

resource "google_service_account" "deployment_sa" {

  account_id   = "deployment-service"

  display_name = "Cloud Run Deployment Service"

}

#######################################################
#
# DEPLOYMENT SERVICE IAM
#
#######################################################

resource "google_project_iam_member" "deployment_container_admin" {

  project = "devops-cert-labs"

  role = "roles/container.admin"

  member = "serviceAccount:${google_service_account.deployment_sa.email}"

}

resource "google_project_iam_member" "deployment_cluster_viewer" {

  project = "devops-cert-labs"

  role = "roles/container.clusterViewer"

  member = "serviceAccount:${google_service_account.deployment_sa.email}"

}

resource "google_project_iam_member" "deployment_artifact_reader" {

  project = "devops-cert-labs"

  role = "roles/artifactregistry.reader"

  member = "serviceAccount:${google_service_account.deployment_sa.email}"

}

resource "google_project_iam_member" "deployment_log_writer" {

  project = "devops-cert-labs"

  role = "roles/logging.logWriter"

  member = "serviceAccount:${google_service_account.deployment_sa.email}"

}

#######################################################
#
# CLOUD RUN DEPLOYMENT SERVICE
#
#######################################################

resource "google_cloud_run_v2_service" "deployment_service" {

  depends_on = [
    google_project_service.run
  ]

  name     = "deployment-service"

  location = "europe-west1"

  ingress = "INGRESS_TRAFFIC_ALL"

  template {

    service_account = google_service_account.deployment_sa.email

    containers {

      image = "us-docker.pkg.dev/cloudrun/container/hello"

      ports {

        container_port = 8080

      }

      env {

        name = "PROJECT_ID"
        value = "devops-cert-labs"

      }

      env {

        name = "CLUSTER"

        value = google_container_cluster.cluster.name

      }

      env {

        name = "ZONE"

        value = "europe-west1-b"

      }

      env {

        name = "NAMESPACE"

        value = kubernetes_namespace.production.metadata[0].name

      }

      env {

        name = "DEPLOYMENT"

        value = "webapp"

      }

    }

  }

}

#######################################################
#
# PROJECT INFO
#
#######################################################

data "google_project" "project" {

  project_id = "devops-cert-labs"

}

#######################################################
#
# PUBSUB -> CLOUD RUN
#
#######################################################

resource "google_cloud_run_service_iam_member" "pubsub_invoker" {

  location = google_cloud_run_v2_service.deployment_service.location

  service = google_cloud_run_v2_service.deployment_service.name

  role = "roles/run.invoker"

  member = "serviceAccount:service-${data.google_project.project.number}@gcp-sa-pubsub.iam.gserviceaccount.com"

}

resource "google_pubsub_subscription" "deployment_subscription" {

  name = "deployment-subscription"

  topic = google_pubsub_topic.deployment_topic.name

  ack_deadline_seconds = 30

  push_config {

    push_endpoint = google_cloud_run_v2_service.deployment_service.uri

    oidc_token {

      service_account_email = google_service_account.deployment_sa.email

    }

  }

}
#######################################################
#
# CLOUD BUILD SERVICE ACCOUNT
#
#######################################################

resource "google_service_account" "cloudbuild_sa" {

  account_id   = "cloudbuild-deployer"

  display_name = "Cloud Build Service Account"

}

#######################################################
#
# CLOUD BUILD IAM
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

resource "google_project_iam_member" "cloudbuild_pubsub" {

  project = "devops-cert-labs"

  role = "roles/pubsub.publisher"

  member = "serviceAccount:${google_service_account.cloudbuild_sa.email}"

}

#######################################################
#
# CLOUD BUILD TRIGGER
#
#######################################################

resource "google_cloudbuild_trigger" "deployment_pipeline" {

  depends_on = [
    google_project_service.cloudbuild
  ]

  name = "event-driven-deployment"

  description = "Build image and publish deployment event"

  location = "global"

  service_account = google_service_account.cloudbuild_sa.id

  filename = "cloudbuild.yaml"

  substitutions = {

    _REGION      = "europe-west1"

    _REPOSITORY  = google_artifact_registry_repository.docker_repo.repository_id

    _IMAGE       = "webapp"

    _TOPIC       = google_pubsub_topic.deployment_topic.name

    _CLUSTER     = google_container_cluster.cluster.name

    _ZONE        = "europe-west1-b"

    _NAMESPACE   = kubernetes_namespace.production.metadata[0].name

  }

  github {

    owner = "JavierGarAgu"

    name  = "Q14-cloudbuild-webhook-lab"

    push {

      branch = "^main$"

    }

  }

}

resource "google_project_iam_member" "cloudbuild_container_admin" {

  project = "devops-cert-labs"

  role = "roles/container.admin"

  member = "serviceAccount:${google_service_account.cloudbuild_sa.email}"

}

resource "google_project_iam_member" "cloudbuild_service_account_user" {

  project = "devops-cert-labs"

  role = "roles/iam.serviceAccountUser"

  member = "serviceAccount:${google_service_account.cloudbuild_sa.email}"

}

resource "google_project_iam_member" "cloudbuild_artifact_writer" {

  project = "devops-cert-labs"

  role = "roles/artifactregistry.writer"

  member = "serviceAccount:${google_service_account.cloudbuild_sa.email}"

}

resource "google_project_iam_member" "cloudbuild_artifact_reader" {

  project = "devops-cert-labs"

  role = "roles/artifactregistry.reader"

  member = "serviceAccount:${google_service_account.cloudbuild_sa.email}"

}

resource "google_project_iam_member" "cloudbuild_pubsub_publisher" {

  project = "devops-cert-labs"

  role = "roles/pubsub.publisher"

  member = "serviceAccount:${google_service_account.cloudbuild_sa.email}"

}

resource "google_project_iam_member" "cloudbuild_logging_writer" {

  project = "devops-cert-labs"

  role = "roles/logging.logWriter"

  member = "serviceAccount:${google_service_account.cloudbuild_sa.email}"

}

resource "google_project_iam_member" "cloudbuild_storage_admin" {

  project = "devops-cert-labs"

  role = "roles/storage.admin"

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

output "artifact_registry" {

  value = google_artifact_registry_repository.docker_repo.repository_id

}

output "pubsub_topic" {

  value = google_pubsub_topic.deployment_topic.name

}

output "cloud_run_url" {

  value = google_cloud_run_v2_service.deployment_service.uri

}