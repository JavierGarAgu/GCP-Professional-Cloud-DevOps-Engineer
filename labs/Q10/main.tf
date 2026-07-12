terraform {

  required_providers {

    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }

  }

}

####################################################
# PROVIDER
####################################################

provider "google" {

  project = "devops-cert-labs"
  region  = "europe-west1"

}

####################################################
# NETWORK
####################################################

resource "google_compute_network" "network" {

  name                    = "logging-network"
  auto_create_subnetworks = true

}

####################################################
# FIREWALL
####################################################

resource "google_compute_firewall" "ssh" {

  name    = "allow-ssh"
  network = google_compute_network.network.name

  allow {

    protocol = "tcp"

    ports = ["22"]

  }

  source_ranges = ["0.0.0.0/0"]

}

####################################################
# VM SERVICE ACCOUNT
####################################################

resource "google_service_account" "vm" {

  account_id   = "logging-vm"
  display_name = "Logging VM"

}

####################################################
# DEVELOPER SERVICE ACCOUNT
####################################################

resource "google_service_account" "developer" {

  account_id   = "logging-developer"
  display_name = "Developer"

}

####################################################
# IAM
####################################################

resource "google_project_iam_member" "logging_writer" {

  project = "devops-cert-labs"

  role = "roles/logging.logWriter"

  member = "serviceAccount:${google_service_account.vm.email}"

}

resource "google_project_iam_member" "logs_viewer" {

  project = "devops-cert-labs"

  role = "roles/logging.viewer"

  member = "serviceAccount:${google_service_account.developer.email}"

}

####################################################
# VM
####################################################

resource "google_compute_instance" "logging_vm" {

  name = "logging-vm"

  machine_type = "e2-micro"

  zone = "europe-west1-b"

  tags = ["ssh"]

  boot_disk {

    initialize_params {

      image = "projects/debian-cloud/global/images/family/debian-12"

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

metadata_startup_script = <<-EOF
#!/usr/bin/env bash

set -euxo pipefail

exec > >(tee /var/log/startup-script.log | logger -t startup-script) 2>&1

echo "======================================="
echo "STARTUP SCRIPT STARTED"
echo "======================================="

export DEBIAN_FRONTEND=noninteractive

apt-get update

apt-get install -y \
  curl \
  ca-certificates

cd /tmp

curl -fsSLO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh

bash add-google-cloud-ops-agent-repo.sh --also-install

sleep 20

systemctl status google-cloud-ops-agent --no-pager || true

logger "Application started"
logger "Testing Stackdriver Logging"
logger "Cloud Ops Agent installed"

echo "======================================="
echo "STARTUP SCRIPT FINISHED"
echo "======================================="
EOF

}

####################################################
# OUTPUTS
####################################################

output "vm_name" {

  value = google_compute_instance.logging_vm.name

}

output "developer_service_account" {

  value = google_service_account.developer.email

}

# terraform destroy -auto-approve && terraform apply -auto-approve