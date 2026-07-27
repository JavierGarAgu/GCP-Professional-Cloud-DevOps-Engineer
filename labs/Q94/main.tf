terraform {

  required_version = ">= 1.5"

  required_providers {

    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }

  }

}


#######################################################
#
# PROVIDER
#
#######################################################

provider "google" {

  project = "devops-cert-labs-v3"
  region  = "europe-west1"

}



#######################################################
#
# DATA
#
#######################################################

data "google_project" "project" {

  project_id = "devops-cert-labs-v3"

}



#######################################################
#
# ENABLE APIS
#
#######################################################

locals {

  apis = [

    "container.googleapis.com",
    "gkehub.googleapis.com",
    "cloudbuild.googleapis.com",
    "iam.googleapis.com",
    "cloudresourcemanager.googleapis.com",
    "anthos.googleapis.com",
    "anthosconfigmanagement.googleapis.com"

  ]

}


resource "google_project_service" "apis" {

  for_each = toset(local.apis)

  service = each.key

  disable_on_destroy = false

}



#######################################################
#
# SERVICE ACCOUNT
#
#######################################################

resource "google_service_account" "config_sync" {

  account_id   = "config-sync-sa"
  display_name = "Config Sync Service Account"

}



#######################################################
#
# IAM FOR CLOUD BUILD
#
#######################################################

resource "google_project_iam_member" "cloudbuild_builder" {

  project = data.google_project.project.project_id

  role = "roles/cloudbuild.builds.builder"

  member = "serviceAccount:${google_service_account.config_sync.email}"

}


resource "google_project_iam_member" "logging_writer" {

  project = data.google_project.project.project_id

  role = "roles/logging.logWriter"

  member = "serviceAccount:${google_service_account.config_sync.email}"

}


resource "google_project_iam_member" "container_admin" {

  project = data.google_project.project.project_id

  role = "roles/container.admin"

  member = "serviceAccount:${google_service_account.config_sync.email}"

}


resource "google_project_iam_member" "viewer" {

  project = data.google_project.project.project_id

  role = "roles/viewer"

  member = "serviceAccount:${google_service_account.config_sync.email}"

}


resource "google_service_account_iam_member" "cloudbuild_use_sa" {


  service_account_id = google_service_account.config_sync.name

  role = "roles/iam.serviceAccountUser"

  member = "serviceAccount:${data.google_project.project.number}@cloudbuild.gserviceaccount.com"


}



#######################################################
#
# GKE CLUSTER
#
#######################################################

resource "google_container_cluster" "cluster" {


  depends_on = [
    google_project_service.apis
  ]


  name = "config-sync-cluster"


  location = "europe-west1-b"


  deletion_protection = false


  remove_default_node_pool = true

  initial_node_count = 1


  networking_mode = "VPC_NATIVE"


  network = "default"

  subnetwork = "default"



  workload_identity_config {

    workload_pool = "devops-cert-labs-v3.svc.id.goog"

  }


}



resource "google_container_node_pool" "primary" {


  cluster = google_container_cluster.cluster.name


  location = google_container_cluster.cluster.location


  name = "primary-pool"


  node_count = 1



  node_config {


    machine_type = "e2-medium"


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
# FLEET MEMBERSHIP
#
#######################################################

resource "google_gke_hub_membership" "cluster" {


  depends_on = [

    google_container_cluster.cluster

  ]


  membership_id = google_container_cluster.cluster.name


  location = "global"



  endpoint {


    gke_cluster {


      resource_link = "//container.googleapis.com/${google_container_cluster.cluster.id}"


    }


  }


}



#######################################################
#
# CONFIG MANAGEMENT FEATURE
#
#######################################################

resource "google_gke_hub_feature" "configmanagement" {


  depends_on = [

    google_project_service.apis

  ]


  name = "configmanagement"


  location = "global"


}



#######################################################
#
# CONFIG SYNC
#
#######################################################

resource "google_gke_hub_feature_membership" "config_sync" {


  depends_on = [

    google_gke_hub_membership.cluster,

    google_gke_hub_feature.configmanagement

  ]


  location = "global"


  feature = google_gke_hub_feature.configmanagement.name


  membership = google_gke_hub_membership.cluster.membership_id


  membership_location = "global"



  configmanagement {


    version = "1.24.3"



    config_sync {


      enabled = true



      git {


        sync_repo = "https://github.com/JavierGarAgu/Q94-GKE-CONFIG.git"


        sync_branch = "main"


        policy_dir = "/"


        secret_type = "none"


      }


    }


  }


}



#######################################################
#
# CLOUD BUILD TRIGGER
#
#######################################################

resource "google_cloudbuild_trigger" "config_sync" {


  depends_on = [

    google_project_iam_member.cloudbuild_builder

  ]



  name = "config-sync-trigger"


  description = "Deploy Config Sync manifests"



  location = "global"



  github {


    owner = "JavierGarAgu"


    name = "Q94-GKE-CONFIG"



    push {


      branch = "^main$"


    }


  }



  filename = "cloudbuild.yaml"



  service_account = google_service_account.config_sync.id



}



#######################################################
#
# OUTPUTS
#
#######################################################

output "cluster_name" {

  value = google_container_cluster.cluster.name

}



output "cluster_location" {

  value = google_container_cluster.cluster.location

}



output "service_account" {

  value = google_service_account.config_sync.email

}