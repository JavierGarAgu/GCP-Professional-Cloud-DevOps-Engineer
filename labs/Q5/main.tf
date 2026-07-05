terraform {

  required_providers {

    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }

  }

}

provider "google" {

  project = "devops-cert-labs"
  region  = "europe-west1"

}

#
# NETWORK
#

resource "google_compute_network" "network" {

  name                    = "logging-network"
  auto_create_subnetworks = true

}

#
# FIREWALL
#

resource "google_compute_firewall" "ssh" {

  name    = "allow-ssh"
  network = google_compute_network.network.name

  allow {

    protocol = "tcp"

    ports = ["22"]

  }

  source_ranges = ["0.0.0.0/0"]

}

#
# SERVICE ACCOUNT
#

resource "google_service_account" "vm" {

  account_id   = "logging-vm"
  display_name = "Logging VM"

}

#
# IAM
#

resource "google_project_iam_member" "logging_writer" {

  project = "devops-cert-labs"

  role = "roles/logging.logWriter"

  member = "serviceAccount:${google_service_account.vm.email}"

}

#
# VM
#

resource "google_compute_instance" "logging_vm" {

  name = "logging-vm"

  machine_type = "e2-micro"

  zone = "europe-west1-b"

  tags = ["ssh"]

  boot_disk {

    initialize_params {

      image = "debian-cloud/debian-12"

    }

  }

  network_interface {

    network = google_compute_network.network.id

    access_config {}

  }

  service_account {

    email = google_service_account.vm.email

    scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

  }

  metadata_startup_script = <<EOF
#!/bin/bash
set -e

apt-get update

apt-get install -y curl

curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh

bash add-google-cloud-ops-agent-repo.sh --also-install

systemctl enable google-cloud-ops-agent
systemctl restart google-cloud-ops-agent

logger "Application started"
logger "Testing Stackdriver Logging"
logger "Cloud Ops Agent installed"

EOF

}