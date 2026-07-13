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
    "cloudprofiler.googleapis.com"
  ])

  project = "devops-cert-labs"
  service = each.key

  disable_on_destroy = false

}

####################################################
# DEFAULT COMPUTE SERVICE ACCOUNT
####################################################

data "google_compute_default_service_account" "default" {}

####################################################
# CLOUD PROFILER AGENT ROLE
####################################################

resource "google_project_iam_member" "profiler_agent" {

  project = "devops-cert-labs"

  role = "roles/cloudprofiler.agent"

  member = "serviceAccount:${data.google_compute_default_service_account.default.email}"

}

####################################################
# COMPUTE ENGINE
####################################################

resource "google_compute_instance" "vm" {

  name         = "profiler-lab-vm"
  machine_type = "e2-micro"
  zone         = "europe-west1-b"

  depends_on = [
    google_project_service.services,
    google_project_iam_member.profiler_agent
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

  tags = ["profiler-lab"]

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

mkdir -p /opt/profiler

python3 -m venv /opt/profiler/venv

/opt/profiler/venv/bin/pip install --upgrade pip

/opt/profiler/venv/bin/pip install \
Flask \
google-cloud-profiler

cat >/opt/profiler/app.py <<'EOF'
import googlecloudprofiler
from flask import Flask

googlecloudprofiler.start(
    service="profiler-lab",
    service_version="v1"
)

app = Flask(__name__)

@app.route("/")
def index():

    total = 0

    for i in range(10000000):
        total += i

    return "Profiler Lab Running"

app.run(host="0.0.0.0", port=8080)
EOF

nohup /opt/profiler/venv/bin/python \
/opt/profiler/app.py \
>/var/log/profiler.log 2>&1 &
SCRIPT

}

####################################################
# FIREWALL
####################################################

resource "google_compute_firewall" "http" {

  name = "allow-http-profiler"

  network = "default"

  allow {

    protocol = "tcp"
    ports    = ["8080"]

  }

  source_ranges = ["0.0.0.0/0"]

  target_tags = ["profiler-lab"]

}

####################################################
# IAM FOR YOUR USER
####################################################

resource "google_project_iam_member" "viewer" {

  project = "devops-cert-labs"

  role = "roles/cloudprofiler.user"

  member = "user:javiergaragu03@gmail.com"

}

####################################################
# OUTPUTS
####################################################

output "vm_ip" {

  value = google_compute_instance.vm.network_interface[0].access_config[0].nat_ip

}

output "profiler_url" {

  value = "https://console.cloud.google.com/profiler?project=devops-cert-labs"

}