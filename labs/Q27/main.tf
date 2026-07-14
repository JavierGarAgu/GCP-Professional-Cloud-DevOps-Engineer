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
# ENABLE APIS
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

resource "google_compute_instance" "canary_lab" {

  name         = "canary-release-lab"
  machine_type = "e2-micro"

  zone = "europe-west1-b"

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

  tags = [
    "canary-lab"
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

metadata_startup_script = <<SCRIPT
#!/bin/bash
set -eux

exec >/var/log/startup.log 2>&1

apt-get update

DEBIAN_FRONTEND=noninteractive apt-get install -y \
python3 \
python3-pip \
python3-venv

mkdir -p /opt/canary

python3 -m venv /opt/canary/venv

/opt/canary/venv/bin/pip install --upgrade pip

/opt/canary/venv/bin/pip install Flask

cat >/opt/canary/app.py <<'PYTHON'
from flask import Flask
import random
import time

app = Flask(__name__)

use_canary = True

@app.route("/")
def home():
    global use_canary

    if use_canary:
        time.sleep(2)

        if random.randint(1,10) <= 7:
            return "500 Internal Server Error (Canary)", 500

        return "Canary OK", 200

    return "Stable Version", 200

@app.route("/rollback")
def rollback():
    global use_canary
    use_canary = False
    return "Rollback completed. Stable version active.", 200

@app.route("/status")
def status():

    if use_canary:
        return "Current deployment: CANARY", 200

    return "Current deployment: STABLE", 200

app.run(host="0.0.0.0", port=8080)
PYTHON

nohup /opt/canary/venv/bin/python \
/opt/canary/app.py \
>/var/log/canary.log 2>&1 &
SCRIPT

}

####################################################
# FIREWALL
####################################################

resource "google_compute_firewall" "http" {

  name = "allow-canary-http"

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
    "canary-lab"
  ]

}

####################################################
# OUTPUTS
####################################################

output "application_url" {

  value = "http://${google_compute_instance.canary_lab.network_interface[0].access_config[0].nat_ip}:8080"

}

output "status_url" {

  value = "http://${google_compute_instance.canary_lab.network_interface[0].access_config[0].nat_ip}:8080/status"

}

output "rollback_url" {

  value = "http://${google_compute_instance.canary_lab.network_interface[0].access_config[0].nat_ip}:8080/rollback"

}

output "correct_answer" {

  value = "Answer A - Roll back the experimental canary release."

}