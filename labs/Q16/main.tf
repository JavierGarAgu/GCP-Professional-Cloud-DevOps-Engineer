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

locals {

  apis = [

    "compute.googleapis.com",
    "container.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "binaryauthorization.googleapis.com",
    "containeranalysis.googleapis.com",
    "cloudkms.googleapis.com",
    "iam.googleapis.com"

  ]

}

resource "google_project_service" "services" {

  for_each = toset(local.apis)

  service = each.key

  disable_on_destroy = false

}

#######################################################
#
# ARTIFACT REGISTRY
#
#######################################################

resource "google_artifact_registry_repository" "docker_repo" {

  depends_on = [

    google_project_service.services

  ]

  repository_id = "trusted-images"

  location = "europe-west1"

  format = "DOCKER"

  description = "Trusted images"

}

#######################################################
#
# CLOUD BUILD SERVICE ACCOUNT
#
#######################################################

resource "google_service_account" "cloudbuild_sa" {

  account_id   = "cloudbuild-binauthz"

  display_name = "Cloud Build Binary Authorization"

}

#######################################################
#
# GKE NODE SERVICE ACCOUNT
#
#######################################################

resource "google_service_account" "gke_node_sa" {

  account_id = "gke-node-sa"

  display_name = "GKE Node Service Account"

}

#######################################################
#
# KMS
#
#######################################################

resource "google_kms_key_ring" "binauthz" {

  depends_on = [

    google_project_service.services

  ]

  name = "binaryauth-keyring"

  location = "global"

}

resource "google_kms_crypto_key" "signing_key" {

  name = "binaryauth-key"

  key_ring = google_kms_key_ring.binauthz.id

  purpose = "ASYMMETRIC_SIGN"

  version_template {

    algorithm = "EC_SIGN_P256_SHA256"

    protection_level = "SOFTWARE"

  }

}

#######################################################
#
# IAM
#
#######################################################

resource "google_project_iam_member" "artifact_reader_nodes" {

  project = "devops-cert-labs"

  role = "roles/artifactregistry.reader"

  member = "serviceAccount:${google_service_account.gke_node_sa.email}"

}

resource "google_project_iam_member" "artifact_writer_cloudbuild" {

  project = "devops-cert-labs"

  role = "roles/artifactregistry.writer"

  member = "serviceAccount:${google_service_account.cloudbuild_sa.email}"

}

resource "google_project_iam_member" "artifact_reader_cloudbuild" {

  project = "devops-cert-labs"

  role = "roles/artifactregistry.reader"

  member = "serviceAccount:${google_service_account.cloudbuild_sa.email}"

}

resource "google_project_iam_member" "container_admin" {

  project = "devops-cert-labs"

  role = "roles/container.admin"

  member = "serviceAccount:${google_service_account.cloudbuild_sa.email}"

}

resource "google_project_iam_member" "logging_writer" {

  project = "devops-cert-labs"

  role = "roles/logging.logWriter"

  member = "serviceAccount:${google_service_account.cloudbuild_sa.email}"

}

resource "google_project_iam_member" "storage_admin" {

  project = "devops-cert-labs"

  role = "roles/storage.admin"

  member = "serviceAccount:${google_service_account.cloudbuild_sa.email}"

}

resource "google_kms_crypto_key_iam_member" "kms_signer" {

  crypto_key_id = google_kms_crypto_key.signing_key.id

  role = "roles/cloudkms.signerVerifier"

  member = "serviceAccount:${google_service_account.cloudbuild_sa.email}"

}

#######################################################
#
# GKE CLUSTER
#
#######################################################

resource "google_container_cluster" "cluster" {

  depends_on = [

    google_project_service.services

  ]

  name = "binaryauth-cluster"

  location = "europe-west1-b"

  deletion_protection = false

  remove_default_node_pool = true

  initial_node_count = 1

  release_channel {

    channel = "REGULAR"

  }

  workload_identity_config {

    workload_pool = "devops-cert-labs.svc.id.goog"

  }

  networking_mode = "VPC_NATIVE"

  binary_authorization {

    evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"

  }

}

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

  node_config {

    machine_type = "e2-medium"

    disk_size_gb = 30

    disk_type = "pd-standard"

    service_account = google_service_account.gke_node_sa.email

    oauth_scopes = [

      "https://www.googleapis.com/auth/cloud-platform"

    ]

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

resource "google_project_iam_member" "containeranalysis_attacher" {

  project = "devops-cert-labs"

  role = "roles/containeranalysis.notes.attacher"

  member = "serviceAccount:${google_service_account.cloudbuild_sa.email}"

}

resource "google_project_iam_member" "binauthz_attestor_verifier" {

  project = "devops-cert-labs"

  role = "roles/binaryauthorization.attestorsVerifier"

  member = "serviceAccount:${google_service_account.cloudbuild_sa.email}"

}
resource "google_project_iam_member" "containeranalysis_occurrences_creator" {

  project = "devops-cert-labs"

  role = "roles/containeranalysis.occurrences.editor"

  member = "serviceAccount:${google_service_account.cloudbuild_sa.email}"

}

resource "google_project_iam_member" "binauthz_attestor_editor" {

  project = "devops-cert-labs"

  role = "roles/binaryauthorization.attestorsEditor"

  member = "serviceAccount:${google_service_account.cloudbuild_sa.email}"

}

#######################################################
#
# CLOUD BUILD TRIGGER
#
#######################################################

resource "google_cloudbuild_trigger" "build_pipeline" {

  depends_on = [
    google_container_cluster.cluster,
    google_artifact_registry_repository.docker_repo,
    google_service_account.cloudbuild_sa
  ]

  name        = "binaryauth-build-deploy"
  description = "Build, sign and deploy application to GKE"

  location = "global"

  service_account = google_service_account.cloudbuild_sa.id

  filename = "cloudbuild.yaml"

  substitutions = {

    _REGION     = "europe-west1"
    _REPOSITORY = google_artifact_registry_repository.docker_repo.repository_id
    _IMAGE      = "webapp"
    _CLUSTER    = google_container_cluster.cluster.name
    _ZONE       = "europe-west1-b"
    _NAMESPACE  = kubernetes_namespace.production.metadata[0].name

  }

  github {

    owner = "JavierGarAgu"

    name = "Q16-cloudbuild-webhook-lab"

    push {

      branch = "^main$"

    }

  }

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

output "kms_key" {

  value = google_kms_crypto_key.signing_key.id

}