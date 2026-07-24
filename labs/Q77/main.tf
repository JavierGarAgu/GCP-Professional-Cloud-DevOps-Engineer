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
# ENABLE REQUIRED APIS
#
#######################################################

locals {

  apis = [

    "compute.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com",
    "iam.googleapis.com",
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
# SERVICE ACCOUNT
#
#######################################################

resource "google_service_account" "logging_sa" {

  depends_on = [

    google_project_service.services

  ]

  account_id   = "logging-filter-sa"
  display_name = "Logging Filter Service Account"

}

#######################################################
#
# IAM
#
#######################################################

resource "google_project_iam_member" "logging_writer" {

  project = "devops-cert-labs-v3"

  role = "roles/logging.logWriter"

  member = "serviceAccount:${google_service_account.logging_sa.email}"

}

resource "google_project_iam_member" "monitoring_writer" {

  project = "devops-cert-labs-v3"

  role = "roles/monitoring.metricWriter"

  member = "serviceAccount:${google_service_account.logging_sa.email}"

}

#######################################################
#
# NETWORK
#
#######################################################

resource "google_compute_network" "logging_network" {

  depends_on = [

    google_project_service.services

  ]

  name                    = "logging-network"
  auto_create_subnetworks = false

}

#######################################################
#
# SUBNETWORK
#
#######################################################

resource "google_compute_subnetwork" "logging_subnet" {

  name          = "logging-subnet"
  region        = "europe-west1"
  network       = google_compute_network.logging_network.id
  ip_cidr_range = "10.20.0.0/24"

}

#######################################################
#
# FIREWALL SSH
#
#######################################################

resource "google_compute_firewall" "allow_ssh" {

  name = "allow-ssh"

  network = google_compute_network.logging_network.name

  allow {

    protocol = "tcp"

    ports = [

      "22"

    ]

  }

  source_ranges = [

    "0.0.0.0/0"

  ]

}

#######################################################
#
# LOGGING VM
#
#######################################################

resource "google_compute_instance" "logging_vm" {

  depends_on = [

    google_project_service.services

  ]

  name         = "logging-vm"
  zone         = "europe-west1-b"
  machine_type = "e2-micro"

  tags = [

    "ssh"

  ]

  labels = {

    application = "logging-demo"
    environment = "production"
    purpose     = "pii-filter"

  }

  boot_disk {

    initialize_params {

      image = "debian-cloud/debian-12"
      size  = 20
      type  = "pd-balanced"

    }

  }

  network_interface {

    subnetwork = google_compute_subnetwork.logging_subnet.id

    access_config {}

  }

  service_account {

    email = google_service_account.logging_sa.email

    scopes = [

      "https://www.googleapis.com/auth/cloud-platform"

    ]

  }

  metadata_startup_script = <<EOF
#!/bin/bash

apt-get update

apt-get install -y curl nano

mkdir -p /var/log/demo

cat > /var/log/demo/app.log <<EOL
{"user":"john","email":"john@example.com","phone":"600123456","credit_card":"4111111111111111","action":"login"}
EOL

EOF

}

#######################################################
#
# OUTPUTS
#
#######################################################

output "vm_name" {

  value = google_compute_instance.logging_vm.name

}

output "vm_external_ip" {

  value = google_compute_instance.logging_vm.network_interface[0].access_config[0].nat_ip

}

output "ssh_command" {

  value = "gcloud compute ssh logging-vm --zone europe-west1-b"

}

output "sample_log" {

  value = "/var/log/demo/app.log"

}