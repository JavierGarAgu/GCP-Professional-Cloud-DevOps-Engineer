terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

###############################################################################
# Provider
###############################################################################

provider "google" {
  project = "devops-cert-labs-v4"
  region  = "europe-west1"
}

###############################################################################
# Variables
###############################################################################

locals {
  project = "devops-cert-labs-v4"
  region  = "europe-west1"
  zone    = "europe-west1-b"
}

###############################################################################
# Service Account
###############################################################################

resource "google_service_account" "terraform_jenkins_sa" {

  account_id   = "terraform-jenkins-sa"
  display_name = "Terraform Jenkins Service Account"

}

###############################################################################
# IAM Roles
###############################################################################

# NOTE:
# For a real production environment, grant only the minimum required roles.
# Editor is used here only to keep the lab simple.

resource "google_project_iam_member" "editor" {

  project = local.project
  role    = "roles/editor"
  member  = "serviceAccount:${google_service_account.terraform_jenkins_sa.email}"

}

###############################################################################
# Firewall
###############################################################################

resource "google_compute_firewall" "jenkins" {

  name    = "allow-jenkins"
  network = "default"

  allow {

    protocol = "tcp"

    ports = [
      "22",
      "8080"
    ]

  }

  source_ranges = [
    "0.0.0.0/0"
  ]

}

###############################################################################
# Jenkins VM
###############################################################################

resource "google_compute_instance" "jenkins_vm" {

  name         = "terraform-jenkins"
  machine_type = "e2-medium"
  zone         = local.zone

  boot_disk {

    initialize_params {

      image = "debian-cloud/debian-12"

    }

  }

  network_interface {

    network = "default"

    access_config {}

  }

  ###########################################################################
  # This is the important part of the lab.
  #
  # Terraform will authenticate using the attached Service Account through
  # Application Default Credentials (ADC).
  ###########################################################################

  service_account {

    email = google_service_account.terraform_jenkins_sa.email

    scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

  }

  metadata_startup_script = <<-EOF
#!/bin/bash

###############################################################################
# Log everything
###############################################################################

exec > >(tee -a /var/log/startup-script.log | logger -t startup-script -s 2>/dev/console) 2>&1

set -euxo pipefail

echo "================================================================="
echo "Startup Script Started: $(date)"
echo "================================================================="

###############################################################################
# Update packages
###############################################################################

apt-get update

apt-get install -y \
    curl \
    wget \
    unzip \
    gnupg \
    lsb-release \
    software-properties-common \
    apt-transport-https \
    ca-certificates \
    openjdk-17-jre

##############################################################################
# Install Java 21 (Temurin)
##############################################################################

wget -qO - https://packages.adoptium.net/artifactory/api/gpg/key/public \
| gpg --dearmor \
-o /usr/share/keyrings/adoptium.gpg

echo "deb [signed-by=/usr/share/keyrings/adoptium.gpg] https://packages.adoptium.net/artifactory/deb bookworm main" \
> /etc/apt/sources.list.d/adoptium.list

apt-get update

apt-get install -y temurin-21-jre

java -version

##############################################################################
# Install Jenkins
##############################################################################

mkdir -p /etc/apt/keyrings

wget -O /etc/apt/keyrings/jenkins-keyring.asc \
https://pkg.jenkins.io/debian-stable/jenkins.io-2026.key

echo "deb [signed-by=/etc/apt/keyrings/jenkins-keyring.asc] \
https://pkg.jenkins.io/debian-stable binary/" \
> /etc/apt/sources.list.d/jenkins.list

apt-get update

apt-get install -y jenkins

systemctl enable jenkins
systemctl start jenkins

###############################################################################
# Install Terraform
###############################################################################

echo "Installing Terraform..."

wget -O- https://apt.releases.hashicorp.com/gpg \
| gpg --dearmor \
-o /usr/share/keyrings/hashicorp-archive-keyring.gpg

echo \
"deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" \
> /etc/apt/sources.list.d/hashicorp.list

apt-get update

apt-get install -y terraform

terraform version

###############################################################################
# Install Google Cloud CLI
###############################################################################

echo "Installing Google Cloud CLI..."

curl https://packages.cloud.google.com/apt/doc/apt-key.gpg \
| gpg --dearmor \
-o /usr/share/keyrings/cloud.google.gpg

echo \
"deb [signed-by=/usr/share/keyrings/cloud.google.gpg] https://packages.cloud.google.com/apt cloud-sdk main" \
> /etc/apt/sources.list.d/google-cloud-sdk.list

apt-get update

apt-get install -y google-cloud-cli

gcloud version

###############################################################################
# Verify ADC
###############################################################################

echo "Checking attached Service Account..."

curl \
-H "Metadata-Flavor: Google" \
http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/email

echo

###############################################################################
# Versions
###############################################################################

echo "Terraform:"
terraform version

echo

echo "gcloud:"
gcloud version

echo

echo "Java:"
java -version

echo

echo "Jenkins:"
systemctl status jenkins --no-pager

echo "================================================================="
echo "Startup Script Finished: $(date)"
echo "================================================================="

EOF

  labels = {

    purpose = "terraform-jenkins-auth-lab"

  }

}

###############################################################################
# Outputs
###############################################################################

output "vm_name" {

  value = google_compute_instance.jenkins_vm.name

}

output "external_ip" {

  value = google_compute_instance.jenkins_vm.network_interface[0].access_config[0].nat_ip

}

output "service_account_email" {

  value = google_service_account.terraform_jenkins_sa.email

}

output "jenkins_url" {

  value = "http://${google_compute_instance.jenkins_vm.network_interface[0].access_config[0].nat_ip}:8080"

}
