terraform {

  required_version = ">= 1.5"

  required_providers {

    google = {

      source  = "hashicorp/google"
      version = "~> 5.0"

    }


    null = {

      source  = "hashicorp/null"
      version = "~> 3.2"

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
# ENABLE APIS
#
#######################################################

locals {

  apis = [

    "compute.googleapis.com",
    "container.googleapis.com",
    "artifactregistry.googleapis.com",
    "binaryauthorization.googleapis.com"

  ]

}

#######################################################
#
# ARTIFACT WRITER FOR IMAGE PUSH
#
#######################################################

resource "google_project_iam_member" "artifact_writer" {


  project = "devops-cert-labs"


  role = "roles/artifactregistry.writer"


  member = "serviceAccount:${google_service_account.gke_nodes.email}"


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

resource "google_artifact_registry_repository" "trusted_images" {


  depends_on = [

    google_project_service.services

  ]


  location = "europe-west1"


  repository_id = "trusted-images"


  description = "Central trusted container images repository"


  format = "DOCKER"


}



#######################################################
#
# GKE NODE SERVICE ACCOUNT
#
#######################################################

resource "google_service_account" "gke_nodes" {


  account_id = "gke-node-sa"


  display_name = "GKE nodes service account"


}



#######################################################
#
# ARTIFACT READER PERMISSION
#
#######################################################

resource "google_project_iam_member" "artifact_reader" {


  project = "devops-cert-labs"


  role = "roles/artifactregistry.reader"


  member = "serviceAccount:${google_service_account.gke_nodes.email}"


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


  name = "trusted-images-cluster"


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



    service_account = google_service_account.gke_nodes.email



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
# CLOUD BUILD SERVICE ACCOUNT
#
#######################################################

resource "google_service_account" "cloudbuild_sa" {

  account_id = "binary-auth-cloudbuild"

  display_name = "Cloud Build Binary Authorization Lab"

}



#######################################################
#
# CLOUD BUILD IAM
#
#######################################################

resource "google_project_iam_member" "cloudbuild_artifact_writer" {


  project = "devops-cert-labs"


  role = "roles/artifactregistry.writer"


  member = "serviceAccount:${google_service_account.cloudbuild_sa.email}"


}



resource "google_project_iam_member" "cloudbuild_container_admin" {


  project = "devops-cert-labs"


  role = "roles/container.admin"


  member = "serviceAccount:${google_service_account.cloudbuild_sa.email}"


}



resource "google_project_iam_member" "cloudbuild_logging" {


  project = "devops-cert-labs"


  role = "roles/logging.logWriter"


  member = "serviceAccount:${google_service_account.cloudbuild_sa.email}"


}



#######################################################
#
# CLOUD BUILD TRIGGER
#
#######################################################

resource "google_cloudbuild_trigger" "binary_auth_trigger" {


  depends_on = [

    google_container_cluster.cluster,

    google_artifact_registry_repository.trusted_images,

    google_service_account.cloudbuild_sa

  ]



  name = "binary-auth-deploy-trigger"



  description = "Build trusted image and test Binary Authorization"



  location = "global"



  service_account = google_service_account.cloudbuild_sa.id



  filename = "cloudbuild.yaml"



  substitutions = {


    _REGION = "europe-west1"


    _REPOSITORY = google_artifact_registry_repository.trusted_images.repository_id


    _IMAGE = "webapp"


    _CLUSTER = google_container_cluster.cluster.name


    _ZONE = "europe-west1-b"


    _NAMESPACE = "default"


  }



  github {


    owner = "JavierGarAgu"


    name = "Q43-BINARY-AUTH"



    push {


      branch = "^main$"


    }


  }


}

#######################################################
#
# BINARY AUTHORIZATION POLICY
#
#######################################################

resource "null_resource" "binary_authorization_policy" {


  depends_on = [

    google_container_cluster.cluster,

    google_artifact_registry_repository.trusted_images

  ]


  provisioner "local-exec" {


    interpreter = [

      "PowerShell",

      "-Command"

    ]


    command = <<EOT


@"

globalPolicyEvaluationMode: ENABLE


defaultAdmissionRule:

  enforcementMode: ENFORCED_BLOCK_AND_AUDIT_LOG

  evaluationMode: ALWAYS_DENY


admissionWhitelistPatterns:

- namePattern: europe-west1-docker.pkg.dev/devops-cert-labs/trusted-images/**


"@ | Out-File policy.yaml -Encoding utf8



gcloud container binauthz policy import policy.yaml


EOT


  }


}


#######################################################
#
# OUTPUTS
#
#######################################################

output "cloudbuild_trigger" {

  value = google_cloudbuild_trigger.binary_auth_trigger.name

}

output "cluster_name" {


  value = google_container_cluster.cluster.name


}



output "artifact_registry" {


  value = google_artifact_registry_repository.trusted_images.name


}



output "trusted_image_pattern" {


  value = "${google_artifact_registry_repository.trusted_images.location}-docker.pkg.dev/devops-cert-labs/${google_artifact_registry_repository.trusted_images.repository_id}/*"


}

output "trusted_image" {


  value = "europe-west1-docker.pkg.dev/devops-cert-labs/trusted-images/webapp:v1"


}
