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
  zone    = "europe-west1-b"

}

####################################################
# ENABLE COMPUTE API
####################################################

resource "google_project_service" "compute" {

  project = "devops-cert-labs"
  service = "compute.googleapis.com"

  disable_on_destroy = false

}

####################################################
# DEFAULT SERVICE ACCOUNT
####################################################

data "google_compute_default_service_account" "default" {}

####################################################
# FIREWALL
####################################################

resource "google_compute_firewall" "ssh" {

  name = "allow-ssh"

  network = "default"

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

####################################################
# STABLE WORKLOAD
####################################################

resource "google_compute_instance" "production" {

  count = 3

  name         = "business-workload-${count.index + 1}"
  machine_type = "e2-standard-2"

  zone = "europe-west1-b"

  depends_on = [
    google_project_service.compute
  ]

  boot_disk {

    initialize_params {

      image = "debian-cloud/debian-12"

    }

  }

  network_interface {

    network = "default"

    access_config {}

  }

  service_account {

    email = data.google_compute_default_service_account.default.email

    scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

  }

  metadata_startup_script = <<EOF
#!/bin/bash

apt-get update

apt-get install -y stress-ng

echo "Starting long-term business workload..."

nohup stress-ng \
--cpu 2 \
--cpu-load 60 \
--timeout 365d \
>/var/log/stress.log 2>&1 &
EOF

}

####################################################
# OUTPUTS
####################################################

output "vm_names" {

  value = google_compute_instance.production[*].name

}

output "recommendation" {

  value = "Purchase a 1-year or 3-year Committed Use Discount for these Compute Engine instances."

}

output "billing_console" {

  value = "https://console.cloud.google.com/billing"

}