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

resource "google_project_service" "logging" {

  service = "logging.googleapis.com"

  disable_on_destroy = false

}

#######################################################
# PRODUCTION VPC
#######################################################

resource "google_compute_network" "production" {

  name = "production-vpc"

  auto_create_subnetworks = false

  depends_on = [
    google_project_service.compute
  ]

}

#######################################################
# FRONTEND SUBNET
#######################################################

resource "google_compute_subnetwork" "frontend" {

  name = "frontend-subnet"

  region = "europe-west1"

  network = google_compute_network.production.id

  ip_cidr_range = "10.10.1.0/24"

  private_ip_google_access = true

  log_config {

    aggregation_interval = "INTERVAL_5_SEC"

    flow_sampling = 1.0

    metadata = "INCLUDE_ALL_METADATA"

  }

}

#######################################################
# BACKEND SUBNET
#######################################################

resource "google_compute_subnetwork" "backend" {

  name = "backend-subnet"

  region = "europe-west1"

  network = google_compute_network.production.id

  ip_cidr_range = "10.10.2.0/24"

  private_ip_google_access = true

  log_config {

    aggregation_interval = "INTERVAL_5_SEC"

    flow_sampling = 1.0

    metadata = "INCLUDE_ALL_METADATA"

  }

}

#######################################################
# FIREWALL
#######################################################

resource "google_compute_firewall" "allow_ssh" {

  name = "allow-ssh"

  network = google_compute_network.production.name

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

resource "google_compute_firewall" "allow_icmp" {

  name = "allow-icmp"

  network = google_compute_network.production.name

  allow {

    protocol = "icmp"

  }

  source_ranges = [
    "10.10.0.0/16"
  ]

}

# resource "google_compute_firewall" "allow_http" {

#   name = "allow-http"

#   network = google_compute_network.production.name

#   allow {

#     protocol = "tcp"

#     ports = [
#       "80",
#       "8080"
#     ]

#   }

#   source_ranges = [
#     "10.10.0.0/16"
#   ]

# }
#######################################################
# SERVICE ACCOUNT
#######################################################

resource "google_service_account" "vm" {

  account_id   = "flowlogs-demo"
  display_name = "Flow Logs Demo VM"

}

#######################################################
# IAM
#######################################################

resource "google_project_iam_member" "logwriter" {

  project = "devops-cert-labs"

  role = "roles/logging.logWriter"

  member = "serviceAccount:${google_service_account.vm.email}"

}

resource "google_project_iam_member" "metricwriter" {

  project = "devops-cert-labs"

  role = "roles/monitoring.metricWriter"

  member = "serviceAccount:${google_service_account.vm.email}"

}

#######################################################
# FRONTEND VM
#######################################################

resource "google_compute_instance" "frontend" {

  name = "frontend"

  zone = "europe-west1-b"

  machine_type = "e2-small"

  tags = [
    "frontend"
  ]

  boot_disk {

    initialize_params {

      image = "debian-cloud/debian-12"

    }

  }

network_interface {

  subnetwork = google_compute_subnetwork.frontend.id

  network_ip = "10.10.1.10"

  access_config {}

}

  service_account {

    email = google_service_account.vm.email

    scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

  }

  metadata_startup_script = <<EOF
#!/bin/bash
set -euxo pipefail

exec > >(tee -a /var/log/startup.log) 2>&1

apt-get update

DEBIAN_FRONTEND=noninteractive apt-get install -y \
curl

cat >/usr/local/bin/traffic-generator.sh <<SCRIPT
#!/bin/bash

while true
do
    curl -s http://10.10.2.2:8080 >/dev/null || true
    ping -c 2 10.10.2.2 >/dev/null || true
    sleep 10
done
SCRIPT

chmod +x /usr/local/bin/traffic-generator.sh

nohup /usr/local/bin/traffic-generator.sh >/dev/null 2>&1 &
EOF

  depends_on = [

    google_project_iam_member.logwriter,

    google_project_iam_member.metricwriter

  ]

}

#######################################################
# BACKEND VM
#######################################################

resource "google_compute_instance" "backend" {

  name = "backend"

  zone = "europe-west1-b"

  machine_type = "e2-small"

  tags = [
    "backend"
  ]

  boot_disk {

    initialize_params {

      image = "debian-cloud/debian-12"

    }

  }

network_interface {

  subnetwork = google_compute_subnetwork.backend.id

  network_ip = "10.10.2.10"

  access_config {}

}

  service_account {

    email = google_service_account.vm.email

    scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

  }

  metadata_startup_script = <<EOF
#!/bin/bash
set -euxo pipefail

exec > >(tee -a /var/log/startup.log) 2>&1

apt-get update

DEBIAN_FRONTEND=noninteractive apt-get install -y \
python3

mkdir -p /opt/server

cat >/opt/server/server.py <<PYTHON
from http.server import HTTPServer, BaseHTTPRequestHandler

class Handler(BaseHTTPRequestHandler):

    def do_GET(self):
        self.send_response(200)
        self.end_headers()
        self.wfile.write(b"Backend OK")

HTTPServer(("0.0.0.0",8080),Handler).serve_forever()
PYTHON

cat >/etc/systemd/system/backend.service <<SERVICE
[Unit]
Description=Backend Demo Server
After=network.target

[Service]
ExecStart=/usr/bin/python3 /opt/server/server.py
Restart=always

[Install]
WantedBy=multi-user.target
SERVICE

systemctl daemon-reload

systemctl enable backend.service

systemctl restart backend.service
EOF

  depends_on = [

    google_project_iam_member.logwriter,

    google_project_iam_member.metricwriter

  ]

}
#######################################################
# OUTPUTS
#######################################################

output "frontend_external_ip" {

  description = "Frontend VM external IP"

  value = google_compute_instance.frontend.network_interface[0].access_config[0].nat_ip

}

output "backend_external_ip" {

  description = "Backend VM external IP"

  value = google_compute_instance.backend.network_interface[0].access_config[0].nat_ip

}

output "frontend_internal_ip" {

  description = "Frontend VM internal IP"

  value = google_compute_instance.frontend.network_interface[0].network_ip

}

output "backend_internal_ip" {

  description = "Backend VM internal IP"

  value = google_compute_instance.backend.network_interface[0].network_ip

}

output "frontend_subnet" {

  value = google_compute_subnetwork.frontend.name

}

output "backend_subnet" {

  value = google_compute_subnetwork.backend.name

}

#######################################################
# VERIFICATION
#######################################################
#
# terraform apply
#
# gcloud compute instances list
#
# gcloud compute ssh frontend --zone=europe-west1-b
#
# curl http://10.10.2.2:8080
#
# ping 10.10.2.2
#
# gcloud logging read \
# 'logName="projects/devops-cert-labs/logs/compute.googleapis.com%2Fvpc_flows"' \
# --limit=20
#
# gcloud logging read \
# 'resource.type="gce_subnetwork"' \
# --limit=20
#
#######################################################