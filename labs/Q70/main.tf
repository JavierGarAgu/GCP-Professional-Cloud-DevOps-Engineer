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

  region  = "europe-west1"

}

#######################################################
#
# ENABLE REQUIRED APIS
#
#######################################################

locals {

  apis = [

    "container.googleapis.com",

    "compute.googleapis.com",

    "iam.googleapis.com",

    "monitoring.googleapis.com",

    "logging.googleapis.com",

    "serviceusage.googleapis.com"

  ]

}

resource "google_project_service" "services" {

  for_each = toset(local.apis)

  service = each.key

  disable_on_destroy = false

}

#######################################################
#
# NETWORK
#
#######################################################

resource "google_compute_network" "gke_network" {

  depends_on = [

    google_project_service.services

  ]

  name = "gke-global-network"

  auto_create_subnetworks = false

}

#######################################################
#
# EUROPE SUBNET
#
#######################################################

resource "google_compute_subnetwork" "europe" {

  name = "europe-subnet"

  region = "europe-west1"

  network = google_compute_network.gke_network.id

  ip_cidr_range = "10.10.0.0/24"

}

#######################################################
#
# USA SUBNET
#
#######################################################

resource "google_compute_subnetwork" "usa" {

  name = "usa-subnet"

  region = "us-central1"

  network = google_compute_network.gke_network.id

  ip_cidr_range = "10.20.0.0/24"

}

#######################################################
#
# FIREWALL
#
#######################################################

resource "google_compute_firewall" "allow_internal" {

  name = "allow-internal"

  network = google_compute_network.gke_network.name

  allow {

    protocol = "tcp"

  }

  allow {

    protocol = "udp"

  }

  allow {

    protocol = "icmp"

  }

  source_ranges = [

    "10.10.0.0/24",

    "10.20.0.0/24"

  ]

}

#######################################################
#
# SERVICE ACCOUNT
#
#######################################################

resource "google_service_account" "gke_nodes" {

  depends_on = [

    google_project_service.services

  ]

  account_id = "gke-node-sa"

  display_name = "GKE Node Service Account"

}

#######################################################
#
# IAM
#
#######################################################

resource "google_project_iam_member" "logging" {

  project = "devops-cert-labs-v3"

  role = "roles/logging.logWriter"

  member = "serviceAccount:${google_service_account.gke_nodes.email}"

}

resource "google_project_iam_member" "monitoring" {

  project = "devops-cert-labs-v3"

  role = "roles/monitoring.metricWriter"

  member = "serviceAccount:${google_service_account.gke_nodes.email}"

}

resource "google_project_iam_member" "artifactregistry" {

  project = "devops-cert-labs-v3"

  role = "roles/artifactregistry.reader"

  member = "serviceAccount:${google_service_account.gke_nodes.email}"

}
#######################################################
#
# EUROPE GKE CLUSTER
#
#######################################################

resource "google_container_cluster" "europe" {

  depends_on = [

    google_project_service.services

  ]

  name = "game-cluster-europe"

  location = "europe-west1-b"

  network = google_compute_network.gke_network.id

  subnetwork = google_compute_subnetwork.europe.id

  deletion_protection = false

  remove_default_node_pool = true

  initial_node_count = 1

  logging_service = "logging.googleapis.com/kubernetes"

  monitoring_service = "monitoring.googleapis.com/kubernetes"

}

#######################################################
#
# EUROPE NODE POOL
#
#######################################################

resource "google_container_node_pool" "europe_nodes" {

  name = "primary-pool"

  location = "europe-west1-b"

  cluster = google_container_cluster.europe.name

  node_count = 2

  node_config {

    machine_type = "e2-medium"

    service_account = google_service_account.gke_nodes.email

    oauth_scopes = [

      "https://www.googleapis.com/auth/cloud-platform"

    ]

    labels = {

      region = "europe"

      environment = "production"

    }

  }

}

#######################################################
#
# USA GKE CLUSTER
#
#######################################################

resource "google_container_cluster" "usa" {

  depends_on = [

    google_project_service.services

  ]

  name = "game-cluster-usa"

  location = "us-central1-a"

  network = google_compute_network.gke_network.id

  subnetwork = google_compute_subnetwork.usa.id

  deletion_protection = false

  remove_default_node_pool = true

  initial_node_count = 1

  logging_service = "logging.googleapis.com/kubernetes"

  monitoring_service = "monitoring.googleapis.com/kubernetes"

}

#######################################################
#
# USA NODE POOL
#
#######################################################

resource "google_container_node_pool" "usa_nodes" {

  name = "primary-pool"

  location = "us-central1-a"

  cluster = google_container_cluster.usa.name

  node_count = 2

  node_config {

    machine_type = "e2-medium"

    service_account = google_service_account.gke_nodes.email

    oauth_scopes = [

      "https://www.googleapis.com/auth/cloud-platform"

    ]

    labels = {

      region = "usa"

      environment = "production"

    }

  }

}

#######################################################
#
# OUTPUTS
#
#######################################################

output "europe_cluster" {

  value = google_container_cluster.europe.name

}

output "usa_cluster" {

  value = google_container_cluster.usa.name

}

output "europe_endpoint" {

  value = google_container_cluster.europe.endpoint

}

output "usa_endpoint" {

  value = google_container_cluster.usa.endpoint

}

output "service_account" {

  value = google_service_account.gke_nodes.email

}