#######################################################
# TERRAFORM
#######################################################

terraform {

  required_version = ">= 1.5"

  required_providers {

    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }

  }

}

#######################################################
# PROVIDER
#######################################################

provider "google" {

  project = "devops-cert-labs"
  region  = "europe-west1"
  zone    = "europe-west1-b"

}

#######################################################
# ENABLE APIS
#######################################################

resource "google_project_service" "compute" {

  service = "compute.googleapis.com"

  disable_on_destroy = false

}

#######################################################
# SERVICE ACCOUNT
#######################################################

resource "google_service_account" "api" {

  account_id   = "regional-api"
  display_name = "Regional API Service Account"

}

#######################################################
# IAM
#######################################################

resource "google_project_iam_member" "logwriter" {

  project = "devops-cert-labs"

  role = "roles/logging.logWriter"

  member = "serviceAccount:${google_service_account.api.email}"

}

resource "google_project_iam_member" "metricwriter" {

  project = "devops-cert-labs"

  role = "roles/monitoring.metricWriter"

  member = "serviceAccount:${google_service_account.api.email}"

}

#######################################################
# FIREWALL
#######################################################

resource "google_compute_firewall" "http" {

  name = "allow-http-api"

  network = "default"

  allow {

    protocol = "tcp"

    ports = [
      "5000"
    ]

  }

  source_ranges = [
    "0.0.0.0/0"
  ]

  target_tags = [
    "api-server"
  ]

  depends_on = [
    google_project_service.compute
  ]

}

resource "google_compute_firewall" "health_checks" {

  name = "allow-google-health-checks"

  network = "default"

  allow {

    protocol = "tcp"

    ports = [
      "5000"
    ]

  }

  source_ranges = [
    "35.191.0.0/16",
    "130.211.0.0/22"
  ]

  target_tags = [
    "api-server"
  ]

}

#######################################################
# INSTANCE TEMPLATE
#######################################################

resource "google_compute_instance_template" "api" {

  name_prefix = "regional-api-"

  machine_type = "e2-small"

  tags = [
    "api-server"
  ]

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

    email = google_service_account.api.email

    scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

  }

  metadata_startup_script = <<EOF
#!/bin/bash
set -euxo pipefail

exec > >(tee -a /var/log/startup.log) 2>&1

echo "========== STARTUP SCRIPT =========="

apt-get update

DEBIAN_FRONTEND=noninteractive apt-get install -y \
    python3 \
    python3-venv

#######################################################
# CREATE APPLICATION
#######################################################

mkdir -p /opt/api

cat >/opt/api/app.py <<'PYTHON'
from flask import Flask
import socket

app = Flask(__name__)

hostname = socket.gethostname()

# Simulate increasing memory usage
memory = []

@app.route("/")
def index():

    memory.append("X" * 100000)

    return {
        "hostname": hostname,
        "status": "healthy"
    }

@app.route("/health")
def health():
    return "OK", 200

app.run(
    host="0.0.0.0",
    port=5000
)
PYTHON

#######################################################
# PYTHON VIRTUAL ENVIRONMENT
#######################################################

python3 -m venv /opt/api/venv

source /opt/api/venv/bin/activate

pip install --upgrade pip

pip install flask

deactivate

#######################################################
# SYSTEMD SERVICE
#######################################################

cat >/etc/systemd/system/api.service <<'SERVICE'
[Unit]
Description=Demo API
After=network.target

[Service]
Type=simple
WorkingDirectory=/opt/api
ExecStart=/opt/api/venv/bin/python /opt/api/app.py
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload

systemctl enable api.service

systemctl restart api.service

sleep 5

systemctl status api.service --no-pager || true

echo "========== STARTUP FINISHED =========="
EOF

  depends_on = [

    google_project_service.compute,

    google_project_iam_member.logwriter,

    google_project_iam_member.metricwriter

  ]

}

#######################################################
# GLOBAL IP
#######################################################

resource "google_compute_global_address" "api" {

  name = "api-load-balancer-ip"

}
#######################################################
# HEALTH CHECK
#######################################################

resource "google_compute_health_check" "api" {

  name = "api-health-check"

  check_interval_sec = 5
  timeout_sec        = 5

  healthy_threshold   = 2
  unhealthy_threshold = 2

  http_health_check {

    port         = 5000
    request_path = "/health"

  }

}

#######################################################
# MANAGED INSTANCE GROUP
# europe-west1-b
#######################################################

resource "google_compute_instance_group_manager" "api_b" {

  name = "api-mig-b"

  zone = "europe-west1-b"

  base_instance_name = "api-b"

  version {

    instance_template = google_compute_instance_template.api.id

  }

  target_size = 1

  named_port {

    name = "http"
    port = 5000

  }

  auto_healing_policies {

    health_check      = google_compute_health_check.api.id
    initial_delay_sec = 60

  }

}

#######################################################
# MANAGED INSTANCE GROUP
# europe-west1-c
#######################################################

resource "google_compute_instance_group_manager" "api_c" {

  name = "api-mig-c"

  zone = "europe-west1-c"

  base_instance_name = "api-c"

  version {

    instance_template = google_compute_instance_template.api.id

  }

  target_size = 1

  named_port {

    name = "http"
    port = 5000

  }

  auto_healing_policies {

    health_check      = google_compute_health_check.api.id
    initial_delay_sec = 60

  }

}
#######################################################
# BACKEND SERVICE
#######################################################

resource "google_compute_backend_service" "api" {

  name = "api-backend"

  protocol = "HTTP"

  port_name = "http"

  load_balancing_scheme = "EXTERNAL"

  timeout_sec = 30

  session_affinity = "NONE"

  health_checks = [
    google_compute_health_check.api.id
  ]

  backend {

    group = google_compute_instance_group_manager.api_b.instance_group

  }

  backend {

    group = google_compute_instance_group_manager.api_c.instance_group

  }

}

#######################################################
# AUTOSCALER
# europe-west1-b
#######################################################

resource "google_compute_autoscaler" "api_b" {

  name = "api-autoscaler-b"

  zone = "europe-west1-b"

  target = google_compute_instance_group_manager.api_b.id

  autoscaling_policy {

    min_replicas = 1

    max_replicas = 3

    cooldown_period = 60

    cpu_utilization {

      target = 0.60

    }

  }

}

#######################################################
# AUTOSCALER
# europe-west1-c
#######################################################

resource "google_compute_autoscaler" "api_c" {

  name = "api-autoscaler-c"

  zone = "europe-west1-c"

  target = google_compute_instance_group_manager.api_c.id

  autoscaling_policy {

    min_replicas = 1

    max_replicas = 3

    cooldown_period = 60

    cpu_utilization {

      target = 0.60

    }

  }

}

#######################################################
# URL MAP
#######################################################

resource "google_compute_url_map" "api" {

  name = "api-url-map"

  default_service = google_compute_backend_service.api.id

}

#######################################################
# HTTP PROXY
#######################################################

resource "google_compute_target_http_proxy" "api" {

  name = "api-http-proxy"

  url_map = google_compute_url_map.api.id

}

#######################################################
# GLOBAL FORWARDING RULE
#######################################################

resource "google_compute_global_forwarding_rule" "api" {

  name = "api-forwarding-rule"

  target = google_compute_target_http_proxy.api.id

  port_range = "80"

  ip_address = google_compute_global_address.api.address

}

#######################################################
# OUTPUTS
#######################################################

output "load_balancer_ip" {

  description = "External IP of the HTTP Load Balancer"

  value = google_compute_global_forwarding_rule.api.ip_address

}

output "application_url" {

  description = "Application URL"

  value = "http://${google_compute_global_forwarding_rule.api.ip_address}"

}

output "mig_zone_b" {

  description = "Managed Instance Group in europe-west1-b"

  value = google_compute_instance_group_manager.api_b.name

}

output "mig_zone_c" {

  description = "Managed Instance Group in europe-west1-c"

  value = google_compute_instance_group_manager.api_c.name

}

output "backend_service" {

  value = google_compute_backend_service.api.name

}

output "health_check" {

  value = google_compute_health_check.api.name

}

#######################################################
# VERIFICATION
#######################################################
#
# terraform apply
#
# List the Managed Instance Groups:
#
# gcloud compute instance-groups managed list
#
# List the VM instances:
#
# gcloud compute instances list
#
# Get the Load Balancer IP:
#
# terraform output load_balancer_ip
#
# Test the application:
#
# curl http://<LOAD_BALANCER_IP>
#
# Run the curl command multiple times. The "hostname"
# field should alternate between the two instances,
# proving that the HTTP Load Balancer is distributing
# traffic across both zones.
#
#######################################################
