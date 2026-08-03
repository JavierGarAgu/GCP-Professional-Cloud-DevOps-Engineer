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

  project = "devops-cert-labs-v4"
  region  = "europe-west1"
  zone    = "europe-west1-b"

}

####################################################
# ENABLE APIS
####################################################

resource "google_project_service" "compute" {

  service = "compute.googleapis.com"

}

resource "google_project_service" "logging" {

  service = "logging.googleapis.com"

}

resource "google_project_service" "monitoring" {

  service = "monitoring.googleapis.com"

}

####################################################
# DEFAULT SERVICE ACCOUNT
####################################################

data "google_compute_default_service_account" "default" {}

####################################################
# FIREWALL
####################################################

resource "google_compute_firewall" "http" {

  name = "allow-http"

  network = "default"

  allow {

    protocol = "tcp"

    ports = ["80"]

  }

  source_ranges = ["0.0.0.0/0"]

}

####################################################
# INSTANCE TEMPLATE
####################################################

resource "google_compute_instance_template" "web" {

  name_prefix = "web-template-"

  machine_type = "e2-micro"

  disk {

    source_image = "debian-cloud/debian-12"

    auto_delete = true

    boot = true

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

set -e

apt-get update

apt-get install -y nginx curl

#
# Install Google Cloud Ops Agent
#

curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh

bash add-google-cloud-ops-agent-repo.sh --also-install

#
# Configure Ops Agent to collect Nginx access logs
#

cat > /etc/google-cloud-ops-agent/config.yaml <<CONFIG
logging:
  receivers:
    nginx_access:
      type: files
      include_paths:
        - /var/log/nginx/access.log

  service:
    pipelines:
      nginx_pipeline:
        receivers: [nginx_access]
CONFIG

#
# Restart Ops Agent
#

systemctl restart google-cloud-ops-agent

#
# Start Nginx
#

systemctl enable nginx

systemctl restart nginx

EOF

}

####################################################
# INSTANCE GROUP
####################################################

resource "google_compute_region_instance_group_manager" "mig" {

  name = "web-mig"

  region = "europe-west1"

  version {

    instance_template = google_compute_instance_template.web.id

  }

  base_instance_name = "web"

  target_size = 2

}

####################################################
# OUTPUTS
####################################################

output "instance_group" {

  value = google_compute_region_instance_group_manager.mig.name

}

output "lab_goal" {

  value = "Create a logs-based metric filtering requests from a specific client IP."

}
