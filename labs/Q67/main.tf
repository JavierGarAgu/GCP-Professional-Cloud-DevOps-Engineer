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
# GOOGLE PROVIDER
#
#######################################################

provider "google" {

  project = "devops-cert-labs-v3"

  region = "europe-west1"

}

#######################################################
#
# ENABLE APIS
#
#######################################################

locals {

  services = [

    "compute.googleapis.com",
    "artifactregistry.googleapis.com",
    "cloudbuild.googleapis.com",
    "iam.googleapis.com",
    "logging.googleapis.com"

  ]

}


resource "google_project_service" "services" {

  for_each = toset(local.services)

  service = each.key

  disable_on_destroy = false

}


#######################################################
#
# ARTIFACT REGISTRY EUROPE
#
#######################################################

resource "google_artifact_registry_repository" "europe" {

  depends_on = [

    google_project_service.services

  ]

  repository_id = "performance-europe"

  location = "europe-west1"

  format = "DOCKER"

  description = "European image registry performance test"

}


#######################################################
#
# ARTIFACT REGISTRY USA
#
#######################################################

resource "google_artifact_registry_repository" "usa" {

  depends_on = [

    google_project_service.services

  ]

  repository_id = "performance-usa"

  location = "us-west1"

  format = "DOCKER"

  description = "USA image registry performance test"

}


#######################################################
#
# CLOUD BUILD SERVICE ACCOUNT
#
#######################################################

resource "google_service_account" "cloudbuild" {

  account_id = "performance-cloudbuild"

  display_name = "Performance Lab Cloud Build"

}


#######################################################
#
# COMPUTE ENGINE SERVICE ACCOUNT
#
#######################################################

resource "google_service_account" "compute" {

  account_id = "performance-compute"

  display_name = "Performance Benchmark VM"

}


#######################################################
#
# ARTIFACT REGISTRY PERMISSIONS
#
#######################################################

resource "google_project_iam_member" "compute_artifact_reader" {

  project = "devops-cert-labs-v3"

  role = "roles/artifactregistry.reader"

  member = "serviceAccount:${google_service_account.compute.email}"

}


resource "google_project_iam_member" "cloudbuild_writer" {

  project = "devops-cert-labs-v3"

  role = "roles/artifactregistry.writer"

  member = "serviceAccount:${google_service_account.cloudbuild.email}"

}


resource "google_project_iam_member" "cloudbuild_logging" {

  project = "devops-cert-labs-v3"

  role = "roles/logging.logWriter"

  member = "serviceAccount:${google_service_account.cloudbuild.email}"

}


#######################################################
#
# COMPUTE ENGINE BENCHMARK VM
#
#######################################################

resource "google_compute_instance" "benchmark" {


  depends_on = [

    google_project_service.services

  ]


  name = "registry-performance-test"


  zone = "europe-west1-b"


  machine_type = "e2-medium"


  boot_disk {

    initialize_params {

      image = "debian-cloud/debian-12"

      size = 30

    }

  }


  network_interface {

    network = "default"


    access_config {}

  }


  service_account {


    email = google_service_account.compute.email


    scopes = [

      "cloud-platform"

    ]

  }


  metadata_startup_script = <<EOF

#!/bin/bash


apt-get update


apt-get install -y docker.io google-cloud-cli


systemctl enable docker

systemctl start docker


docker --version


echo "Benchmark VM ready" > /var/log/registry-test.log


EOF


}
#######################################################
#
# CLOUD BUILD PERMISSIONS
#
#######################################################

resource "google_project_iam_member" "cloudbuild_service_account_user" {

  project = "devops-cert-labs-v3"

  role = "roles/iam.serviceAccountUser"

  member = "serviceAccount:${google_service_account.cloudbuild.email}"

}


resource "google_project_iam_member" "cloudbuild_compute_viewer" {

  project = "devops-cert-labs-v3"

  role = "roles/compute.viewer"

  member = "serviceAccount:${google_service_account.cloudbuild.email}"

}


#######################################################
#
# CLOUD BUILD TRIGGER
#
#######################################################

resource "google_cloudbuild_trigger" "registry_test" {


  depends_on = [

    google_artifact_registry_repository.europe,
    google_artifact_registry_repository.usa,
    google_service_account.cloudbuild

  ]


  name = "Q67-latency-test"


  description = "Build image and push to EU and US registries"


  location = "global"


  service_account = google_service_account.cloudbuild.id


  filename = "cloudbuild.yaml"



  substitutions = {


    _PROJECT = "devops-cert-labs-v3"


    _EU_REGION = "europe-west1"


    _US_REGION = "us-west1"


    _EU_REPOSITORY = google_artifact_registry_repository.europe.repository_id


    _US_REPOSITORY = google_artifact_registry_repository.usa.repository_id


    _IMAGE = "performance-test"



  }



  github {


    owner = "JavierGarAgu"


    name = "Q67-latency-test"



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

output "benchmark_vm" {


  value = google_compute_instance.benchmark.name


}


output "europe_registry" {


  value = google_artifact_registry_repository.europe.id


}


output "usa_registry" {


  value = google_artifact_registry_repository.usa.id


}


output "cloudbuild_trigger" {


  value = google_cloudbuild_trigger.registry_test.name


}