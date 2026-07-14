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
# ENABLE REQUIRED APIS
####################################################

resource "google_project_service" "services" {

  for_each = toset([
    "compute.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com"
  ])

  project = "devops-cert-labs"
  service = each.key

  disable_on_destroy = false

}

####################################################
# DEFAULT SERVICE ACCOUNT
####################################################

data "google_compute_default_service_account" "default" {}

####################################################
# IAM
####################################################

resource "google_project_iam_member" "metric_writer" {

  project = "devops-cert-labs"

  role = "roles/monitoring.metricWriter"

  member = "serviceAccount:${data.google_compute_default_service_account.default.email}"

}

resource "google_project_iam_member" "log_writer" {

  project = "devops-cert-labs"

  role = "roles/logging.logWriter"

  member = "serviceAccount:${data.google_compute_default_service_account.default.email}"

}

####################################################
# VM
####################################################

resource "google_compute_instance" "production_vm" {

  name         = "production-server"
  machine_type = "e2-micro"

  zone = "europe-west1-b"

  depends_on = [
    google_project_service.services,
    google_project_iam_member.metric_writer,
    google_project_iam_member.log_writer
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

  tags = [
    "monitoring-lab"
  ]

  service_account {

    email = data.google_compute_default_service_account.default.email

    scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

  }

  ####################################################
  # STARTUP SCRIPT
  ####################################################

  metadata_startup_script = <<-SCRIPT
#!/bin/bash
set -eux

exec >/var/log/startup.log 2>&1

apt-get update

apt-get install -y curl stress-ng

curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh

bash add-google-cloud-ops-agent-repo.sh --also-install

systemctl enable google-cloud-ops-agent

systemctl restart google-cloud-ops-agent

####################################################
# Simulate CPU load forever
####################################################

nohup stress-ng \
--cpu 1 \
--cpu-load 70 \
--timeout 365d \
>/var/log/stress.log 2>&1 &
SCRIPT

}

####################################################
# FIREWALL
####################################################

resource "google_compute_firewall" "ssh" {

  name = "allow-ssh-monitoring"

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
# OUTPUTS
####################################################

output "external_ip" {

  value = google_compute_instance.production_vm.network_interface[0].access_config[0].nat_ip

}

output "ssh_command" {

  value = "gcloud compute ssh production-server --zone=europe-west1-b"

}

output "monitoring_url" {

  value = "https://console.cloud.google.com/monitoring?project=devops-cert-labs"

}

output "metrics_explorer" {

  value = "https://console.cloud.google.com/monitoring/metrics-explorer?project=devops-cert-labs"

}

output "logs_explorer" {

  value = "https://console.cloud.google.com/logs/query?project=devops-cert-labs"

}