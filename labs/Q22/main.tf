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
    "compute.googleapis.com"
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
# COMPUTE ENGINE
####################################################

resource "google_compute_instance" "incident_lab" {

  name         = "incident-management-lab"
  machine_type = "e2-micro"
  zone         = "europe-west1-b"

  depends_on = [
    google_project_service.services
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

  ####################################################
  # SERVICE ACCOUNT
  ####################################################

  service_account {

    email = data.google_compute_default_service_account.default.email

    scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

  }

  ####################################################
  # TAGS
  ####################################################

  tags = ["incident-lab"]

  ####################################################
  # STARTUP SCRIPT
  ####################################################

  metadata_startup_script = <<-SCRIPT
#!/bin/bash
set -euxo pipefail

exec >/var/log/startup.log 2>&1

apt-get update

DEBIAN_FRONTEND=noninteractive apt-get install -y \
python3 \
python3-pip \
python3-venv

mkdir -p /opt/incident-lab

python3 -m venv /opt/incident-lab/venv

/opt/incident-lab/venv/bin/pip install --upgrade pip

/opt/incident-lab/venv/bin/pip install Flask

cat >/opt/incident-lab/service.py <<'EOF'
from flask import Flask
import random
import time

app = Flask(__name__)

@app.route("/")
def index():

    time.sleep(2)

    if random.randint(1,10) <= 8:
        return "503 Service Unavailable", 503

    return "Service Healthy", 200

@app.route("/health")
def health():
    return "OK", 200

app.run(host="0.0.0.0", port=8080)
EOF

nohup /opt/incident-lab/venv/bin/python \
/opt/incident-lab/service.py \
>/var/log/service.log 2>&1 &
SCRIPT

}

####################################################
# FIREWALL
####################################################

resource "google_compute_firewall" "http" {

  name = "incident-lab-http"

  network = "default"

  allow {

    protocol = "tcp"
    ports = [
      "8080"
    ]

  }

  source_ranges = [
    "0.0.0.0/0"
  ]

  target_tags = [
    "incident-lab"
  ]

}

####################################################
# OUTPUTS
####################################################

output "external_ip" {

  value = google_compute_instance.incident_lab.network_interface[0].access_config[0].nat_ip

}

output "service_url" {

  value = "http://${google_compute_instance.incident_lab.network_interface[0].access_config[0].nat_ip}:8080"

}

output "healthcheck_url" {

  value = "http://${google_compute_instance.incident_lab.network_interface[0].access_config[0].nat_ip}:8080/health"

}