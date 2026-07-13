terraform {

  required_providers {

    google = {
      source  = "hashicorp/google"
      version = ">= 5.20"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }

    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
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

  disable_on_destroy = true

}

resource "google_project_service" "artifactregistry" {

  service = "artifactregistry.googleapis.com"

  disable_on_destroy = true

}

#######################################################
# CLOUD BUILD -> BINARY AUTHORIZATION
#######################################################

resource "google_project_iam_member" "cloudbuild_binauthz_attestor_viewer" {

  project = "devops-cert-labs"

  role = "roles/binaryauthorization.attestorsViewer"

  member = "serviceAccount:${google_service_account.cloudbuild_sa.email}"

}

#######################################################
# CLOUD BUILD -> CONTAINER ANALYSIS
#######################################################

resource "google_project_iam_member" "cloudbuild_containeranalysis" {

  project = "devops-cert-labs"

  role = "roles/containeranalysis.notes.attacher"

  member = "serviceAccount:${google_service_account.cloudbuild_sa.email}"

}

#######################################################
# CLOUD BUILD -> KMS VIEWER
#######################################################

resource "google_project_iam_member" "cloudbuild_kms_viewer" {

  project = "devops-cert-labs"

  role = "roles/cloudkms.viewer"

  member = "serviceAccount:${google_service_account.cloudbuild_sa.email}"

}

data "google_project" "current" {}

resource "google_binary_authorization_attestor_iam_member" "binauthz_verifier" {

  attestor = google_binary_authorization_attestor.trusted.name

  role = "roles/binaryauthorization.attestorsVerifier"

  member = "serviceAccount:service-${data.google_project.current.number}@gcp-sa-binaryauthorization.iam.gserviceaccount.com"

}

resource "google_project_service" "cloudbuild" {

  service = "cloudbuild.googleapis.com"

  disable_on_destroy = true

}

resource "google_project_service" "iam" {

  service = "iam.googleapis.com"

  disable_on_destroy = true

}

resource "google_project_service" "compute" {

  service = "compute.googleapis.com"

  disable_on_destroy = true

}

#######################################################
#
# ARTIFACT REGISTRY
#
#######################################################

#######################################################
#
# GKE NODE SERVICE ACCOUNT
#
#######################################################

resource "google_service_account" "gke_node_sa" {
  account_id   = "gke-node-sa"
  display_name = "GKE Node Service Account"
}

resource "google_project_iam_member" "gke_node_artifact_reader" {
  project = "devops-cert-labs"
  role    = "roles/artifactregistry.reader"

  member = "serviceAccount:${google_service_account.gke_node_sa.email}"
}

resource "google_artifact_registry_repository" "docker_repo" {

  depends_on = [
    google_project_service.artifactregistry
  ]

  repository_id = "trusted-images"

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
    google_project_service.container,
    google_project_service.binaryauthorization
  ]

  name     = "binaryauth-cluster-v2"
  location = "europe-west1-b"

  deletion_protection     = false
  remove_default_node_pool = true
  initial_node_count      = 1

  binary_authorization {
    evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"
  }

}

#######################################################
#
# KMS
#
#######################################################

resource "google_kms_key_ring" "binauthz" {

  depends_on = [
    google_project_service.cloudkms
  ]

  name     = "binaryauth-keyring-v2"
  location = "global"

}

resource "google_kms_crypto_key" "signing_key" {

  name     = "binaryauth-key-v2"
  key_ring = google_kms_key_ring.binauthz.id

  purpose = "ASYMMETRIC_SIGN"

  version_template {

    algorithm        = "EC_SIGN_P256_SHA256"
    protection_level = "SOFTWARE"

  }

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

  depends_on = [
    google_project_iam_member.gke_node_artifact_reader
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

    _IMAGE = "webapp"

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

    name = "Q16-cloudbuild-webhook-lab"

    push {

      branch = "^main$"

    }

  }

}


resource "google_container_analysis_note" "trusted_note" {
  name = "trusted-cloudbuild-note-v2"

  attestation_authority {
    hint {
      human_readable_name = "Cloud Build Attestor"
    }
  }
}
resource "google_binary_authorization_attestor" "trusted" {

  depends_on = [
    null_resource.export_public_key
  ]

  name = "trusted-cloudbuild-v2"

  attestation_authority_note {

    note_reference = google_container_analysis_note.trusted_note.name

    public_keys {

      id = "//cloudkms.googleapis.com/v1/projects/devops-cert-labs/locations/global/keyRings/binaryauth-keyring-v2/cryptoKeys/binaryauth-key-v2/cryptoKeyVersions/1"

      pkix_public_key {

        public_key_pem = file("${path.module}/public_key.pem")
        signature_algorithm = "ECDSA_P256_SHA256"

      }

    }

  }

}

resource "google_binary_authorization_attestor_iam_member" "verifier" {

  attestor = google_binary_authorization_attestor.trusted.name

  role = "roles/binaryauthorization.attestorsVerifier"

  member = "serviceAccount:service-${data.google_project.current.number}@gcp-sa-binaryauthorization.iam.gserviceaccount.com"

}

resource "google_project_iam_member" "cloudbuild_binauthz_viewer" {

  project = "devops-cert-labs"

  role = "roles/binaryauthorization.attestorsViewer"

  member = "serviceAccount:${google_service_account.cloudbuild_sa.email}"

}

resource "google_kms_crypto_key_iam_member" "cloudbuild_signer" {

  crypto_key_id = google_kms_crypto_key.signing_key.id

  role = "roles/cloudkms.signerVerifier"

  member = "serviceAccount:${google_service_account.cloudbuild_sa.email}"

}

resource "null_resource" "export_public_key" {

  depends_on = [
    google_kms_crypto_key.signing_key
  ]

  provisioner "local-exec" {

    interpreter = ["PowerShell", "-Command"]

    command = "gcloud kms keys versions get-public-key 1 --project=devops-cert-labs --location=global --keyring=binaryauth-keyring-v2 --key=binaryauth-key-v2 --output-file=\"${path.module}\\public_key.pem\""

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

resource "google_project_service" "binaryauthorization" {

  service = "binaryauthorization.googleapis.com"

  disable_on_destroy = true

}

resource "google_project_service" "containeranalysis" {

  service = "containeranalysis.googleapis.com"

  disable_on_destroy = true

}

resource "google_project_service" "cloudkms" {

  service = "cloudkms.googleapis.com"

  disable_on_destroy = true

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