terraform {

  required_providers {

    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }

    local = {
      source = "hashicorp/local"
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
# VM UNDER REVIEW
####################################################

resource "google_compute_instance" "prr_lab" {

  name         = "production-readiness-review"
  machine_type = "e2-micro"

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

  tags = [
    "prr-lab"
  ]

  service_account {

    email = data.google_compute_default_service_account.default.email

    scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

  }

  metadata_startup_script = <<EOF
#!/bin/bash
set -eux

apt-get update

apt-get install -y python3 python3-pip

pip3 install flask

cat >/root/app.py <<PYTHON
from flask import Flask
import random
import time

app = Flask(__name__)

@app.route("/")
def home():

    time.sleep(2)

    if random.randint(1,10) <= 8:
        return "503 Service Unavailable",503

    return "OK",200

app.run(host="0.0.0.0",port=8080)
PYTHON

nohup python3 /root/app.py >/root/app.log 2>&1 &
EOF

}

####################################################
# FIREWALL
####################################################

resource "google_compute_firewall" "http" {

  name = "allow-prr-http"

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
    "prr-lab"
  ]

}

####################################################
# PRR REPORT
####################################################

resource "local_file" "prr_report" {

  filename = "${path.module}/production-readiness-review.txt"

  content = <<EOF
Production Readiness Review

Service Status:
FAILED

Target SLO:
99.9% Availability

Observed Reliability:
Approximately 20%

Recommended Improvements:

- Reduce error rate
- Improve application reliability
- Reduce response latency
- Add monitoring and alerting
- Repeat PRR before production handover

Decision:

Do NOT hand over the service.

Development team must implement the reliability improvements before SRE accepts ownership.

Correct Exam Answer:
C - Identify recommended reliability improvements to the service before handover.
EOF

}

####################################################
# OUTPUTS
####################################################

output "service_url" {

  value = "http://${google_compute_instance.prr_lab.network_interface[0].access_config[0].nat_ip}:8080"

}

output "prr_report" {

  value = local_file.prr_report.filename

}

output "correct_answer" {

  value = "Answer C"

}