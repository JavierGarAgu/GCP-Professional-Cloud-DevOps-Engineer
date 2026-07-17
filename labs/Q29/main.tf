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
    "logging.googleapis.com",
    "monitoring.googleapis.com"
  ])

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
# COMPUTE ENGINE
####################################################

resource "google_compute_instance" "quality_sli_lab" {

  name         = "quality-sli-lab"
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

    "quality-sli"

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
set -euxo pipefail

exec >/var/log/startup.log 2>&1

echo "===== Installing packages ====="

apt-get update

DEBIAN_FRONTEND=noninteractive apt-get install -y \
python3 \
python3-pip \
python3-venv

####################################################
# CREATE PYTHON VENV
####################################################

mkdir -p /opt/quality-sli

python3 -m venv /opt/quality-sli/venv

/opt/quality-sli/venv/bin/pip install --upgrade pip

/opt/quality-sli/venv/bin/pip install Flask

####################################################
# CREATE APPLICATION
####################################################

cat >/opt/quality-sli/app.py <<'EOF'
from flask import Flask, jsonify
import random

app = Flask(__name__)

total_requests = 0
non_degraded = 0
degraded = 0


def weather():
    return random.randint(1,100) > 10


def stocks():
    return random.randint(1,100) > 15


def news():
    return random.randint(1,100) > 20


def sports():
    return random.randint(1,100) > 10


@app.route("/")
def homepage():

    global total_requests
    global non_degraded
    global degraded

    total_requests += 1

    widgets = {

        "weather": weather(),
        "stocks": stocks(),
        "news": news(),
        "sports": sports()

    }

    degraded_mode = not all(widgets.values())

    if degraded_mode:
        degraded += 1
    else:
        non_degraded += 1

    quality = round(
        (non_degraded / total_requests) * 100,
        2
    )

    return jsonify({

        "homepage_status":
            "DEGRADED" if degraded_mode else "NON_DEGRADED",

        "widgets": widgets,

        "quality_sli_percent": quality,

        "total_requests": total_requests,

        "non_degraded": non_degraded,

        "degraded": degraded

    })


@app.route("/metrics")
def metrics():

    if total_requests == 0:
        quality = 100
    else:
        quality = round(
            (non_degraded / total_requests) * 100,
            2
        )

    return jsonify({

        "total_requests": total_requests,

        "non_degraded_responses": non_degraded,

        "degraded_responses": degraded,

        "quality_sli_percent": quality

    })


@app.route("/reset")
def reset():

    global total_requests
    global non_degraded
    global degraded

    total_requests = 0
    non_degraded = 0
    degraded = 0

    return jsonify({

        "status": "Counters reset"

    })


app.run(

    host="0.0.0.0",

    port=8080

)
EOF

####################################################
# START APPLICATION
####################################################

nohup \
/opt/quality-sli/venv/bin/python \
/opt/quality-sli/app.py \
>/var/log/quality-sli.log 2>&1 &

sleep 5

echo "===== Flask Status ====="

ps aux | grep app.py || true

ss -tulpn | grep 8080 || true

echo "===== Startup Finished ====="

SCRIPT

}

####################################################
# FIREWALL
####################################################

resource "google_compute_firewall" "http" {

  name = "quality-sli-http"

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

    "quality-sli"

  ]

}

####################################################
# OUTPUTS
####################################################

output "application_url" {

  value = "http://${google_compute_instance.quality_sli_lab.network_interface[0].access_config[0].nat_ip}:8080"

}

output "metrics_url" {

  value = "http://${google_compute_instance.quality_sli_lab.network_interface[0].access_config[0].nat_ip}:8080/metrics"

}

output "reset_url" {

  value = "http://${google_compute_instance.quality_sli_lab.network_interface[0].access_config[0].nat_ip}:8080/reset"

}

output "correct_answer" {

  value = "Answer A - Quality SLI: ratio of non-degraded responses to total responses."

}
