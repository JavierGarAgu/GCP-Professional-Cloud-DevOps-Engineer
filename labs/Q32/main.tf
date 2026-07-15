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
# INSTANCE TEMPLATE
####################################################

resource "google_compute_instance_template" "web_template" {

  name_prefix = "mig-lab-template-"

  machine_type = "e2-micro"

  tags = [

    "mig-lab"

  ]

  disk {

    auto_delete = true
    boot         = true

    source_image = "debian-cloud/debian-12"

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

####################################################
# STARTUP SCRIPT
####################################################

metadata_startup_script = <<SCRIPT
#!/bin/bash

set -euxo pipefail

exec >/var/log/startup.log 2>&1

echo "===== Updating packages ====="

apt-get update

DEBIAN_FRONTEND=noninteractive apt-get install -y \
python3 \
python3-pip \
python3-venv

####################################################
# CREATE PYTHON ENVIRONMENT
####################################################

mkdir -p /opt/mig-lab

python3 -m venv /opt/mig-lab/venv

/opt/mig-lab/venv/bin/pip install --upgrade pip

/opt/mig-lab/venv/bin/pip install Flask

####################################################
# CREATE APPLICATION
####################################################

cat >/opt/mig-lab/app.py <<'EOF'
from flask import Flask

app = Flask(__name__)

@app.route("/")
def index():

    return """
    <h2>Managed Instance Group Lab</h2>

    <p>Server is running correctly.</p>

    <p>If this VM crashes, the Managed Instance Group
    will automatically recreate it.</p>
    """

@app.route("/health")
def health():

    return "OK", 200

app.run(

    host="0.0.0.0",

    port=8080

)

EOF

####################################################
# START APPLICATION
####################################################

nohup \
/opt/mig-lab/venv/bin/python \
/opt/mig-lab/app.py \
>/var/log/flask.log 2>&1 &

sleep 5

echo "===== Flask Status ====="

ps aux | grep app.py || true

ss -tulpn | grep 8080 || true

echo "===== Startup Finished ====="

SCRIPT

}
####################################################
# HEALTH CHECK
####################################################

resource "google_compute_health_check" "http_health_check" {

  name = "mig-http-health-check"

  check_interval_sec  = 10
  timeout_sec         = 5

  healthy_threshold   = 2
  unhealthy_threshold = 2

  http_health_check {

    port = 8080

    request_path = "/health"

  }

}

####################################################
# MANAGED INSTANCE GROUP
####################################################

resource "google_compute_region_instance_group_manager" "mig" {

  name = "production-mig"

  region = "europe-west1"

  base_instance_name = "production"

  target_size = 1

  version {

    instance_template = google_compute_instance_template.web_template.id

  }

  ##################################################
  # AUTOHEALING
  ##################################################

  auto_healing_policies {

    health_check = google_compute_health_check.http_health_check.id

    initial_delay_sec = 60

  }

  depends_on = [

    google_project_service.services,

    google_project_iam_member.metric_writer,

    google_project_iam_member.log_writer

  ]

}

####################################################
# FIREWALL
####################################################

resource "google_compute_firewall" "allow_http" {

  name = "mig-lab-http"

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

    "mig-lab"

  ]

}



####################################################
# OUTPUTS
####################################################

output "managed_instance_group" {

  value = google_compute_region_instance_group_manager.mig.name

}

output "health_check" {

  value = google_compute_health_check.http_health_check.name

}

output "instance_group" {

  value = google_compute_region_instance_group_manager.mig.instance_group

}

output "instance_ip" {
  value = google_compute_region_instance_group_manager.mig.instance_group
}

output "correct_exam_answer" {

  value = "Answer B - Use a Managed Instance Group with one instance and Health Checks."

}

output "why" {

  value = "The Managed Instance Group automatically recreates unhealthy instances, eliminating manual recovery and reducing operational toil."

}

