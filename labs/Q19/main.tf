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
    "appengine.googleapis.com",
    "monitoring.googleapis.com",
    "cloudbuild.googleapis.com",
    "artifactregistry.googleapis.com"
  ])

  project = "devops-cert-labs"
  service = each.key

  disable_on_destroy = false

}

####################################################
# APP ENGINE APPLICATION
####################################################

resource "google_app_engine_application" "app" {

  project     = "devops-cert-labs"
  location_id = "europe-west"

  depends_on = [
    google_project_service.services
  ]

}

####################################################
# DEFAULT SERVICE ACCOUNT
####################################################

data "google_compute_default_service_account" "default" {}

####################################################
# IAM
####################################################

resource "google_project_iam_member" "editor" {

  project = "devops-cert-labs"

  role = "roles/editor"

  member = "serviceAccount:${data.google_compute_default_service_account.default.email}"

}

resource "google_project_iam_member" "appengine_admin" {

  project = "devops-cert-labs"

  role = "roles/appengine.appAdmin"

  member = "serviceAccount:${data.google_compute_default_service_account.default.email}"

}

resource "google_project_iam_member" "storage_admin" {

  project = "devops-cert-labs"

  role = "roles/storage.admin"

  member = "serviceAccount:${data.google_compute_default_service_account.default.email}"

}
####################################################
# COMPUTE ENGINE
####################################################

resource "google_compute_instance" "appengine_lab" {

  name         = "appengine-monitoring-lab"
  machine_type = "e2-micro"
  zone         = "europe-west1-b"

  depends_on = [
    google_project_service.services,
    google_app_engine_application.app,
    google_project_iam_member.editor,
    google_project_iam_member.appengine_admin,
    google_project_iam_member.storage_admin
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

  tags = [
    "appengine-lab"
  ]

  ####################################################
  # STARTUP SCRIPT
  ####################################################

  metadata_startup_script = <<-SCRIPT
#!/bin/bash
set -euxo pipefail

exec > >(tee -a /var/log/initial-script.log) 2>&1

export DEBIAN_FRONTEND=noninteractive

echo "========================================"
echo "App Engine Monitoring Lab Startup"
echo "Started at: $(date)"
echo "========================================"

####################################################
# INSTALL DEPENDENCIES
####################################################

apt-get update

apt-get install -y \
python3 \
python3-pip \
curl

####################################################
# VERIFY GCLOUD
####################################################

if ! command -v gcloud >/dev/null 2>&1; then
    echo "ERROR: gcloud CLI not found."
    exit 1
fi

echo "gcloud found."

gcloud version

####################################################
# CREATE PROJECT DIRECTORY
####################################################

mkdir -p /opt/appengine-lab

cd /opt/appengine-lab

####################################################
# CREATE app.py
####################################################

cat > app.py <<'EOF'
from flask import Flask

app = Flask(__name__)

@app.route("/")
def home():

    total = 0

    for i in range(5000000):
        total += i

    return """
    <h1>App Engine Monitoring Lab</h1>
    <p>The application is running correctly.</p>
    <p>This endpoint generates CPU load to simulate requests.</p>
    """

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
EOF

####################################################
# CREATE requirements.txt
####################################################

cat > requirements.txt <<'EOF'
Flask==3.0.3
gunicorn==23.0.0
EOF

####################################################
# CREATE app.yaml
####################################################

cat > app.yaml <<'EOF'
runtime: python

env: flex

entrypoint: gunicorn -b :$PORT app:app

runtime_config:
  operating_system: "ubuntu24"

automatic_scaling:
  min_num_instances: 1
  max_num_instances: 2

resources:
  cpu: 1
  memory_gb: 1
  disk_size_gb: 10
EOF

####################################################
# CONFIGURE GCLOUD
####################################################

gcloud auth list

gcloud config set project devops-cert-labs

####################################################
# WAIT FOR APP ENGINE
####################################################

echo "Waiting for App Engine..."

sleep 30

####################################################
# DEPLOY APPLICATION
####################################################

gcloud app deploy app.yaml \
  --quiet \
  --verbosity=info

echo "========================================"
echo "Deployment finished successfully"
echo "Finished at: $(date)"
echo "========================================"

SCRIPT

}

resource "google_project_iam_member" "appspot_storage_admin" {

  project = "devops-cert-labs"

  role = "roles/storage.admin"

  member = "serviceAccount:devops-cert-labs@appspot.gserviceaccount.com"

}

####################################################
# APP ENGINE SERVICE ACCOUNT PERMISSIONS
####################################################

resource "google_project_iam_member" "appengine_artifact_reader" {

  project = "devops-cert-labs"

  role = "roles/artifactregistry.reader"

  member = "serviceAccount:devops-cert-labs@appspot.gserviceaccount.com"

}


resource "google_project_iam_member" "appengine_artifact_writer" {

  project = "devops-cert-labs"

  role = "roles/artifactregistry.writer"

  member = "serviceAccount:devops-cert-labs@appspot.gserviceaccount.com"

}


resource "google_project_iam_member" "appengine_cloudbuild_builder" {

  project = "devops-cert-labs"

  role = "roles/cloudbuild.builds.builder"

  member = "serviceAccount:devops-cert-labs@appspot.gserviceaccount.com"

}

####################################################
# OUTPUTS
####################################################

output "app_engine_url" {

  description = "App Engine application URL"

  value = "https://devops-cert-labs.ew.r.appspot.com"

}

output "monitoring_console" {

  description = "Cloud Monitoring"

  value = "https://console.cloud.google.com/monitoring?project=devops-cert-labs"

}

output "metrics_explorer" {

  description = "Metric to verify"

  value = "flex/connections/current"

}

output "exam_answer" {

  value = "Correct metric: flex/connections/current"

}