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

resource "google_project_service" "logging" {

  service = "logging.googleapis.com"

  disable_on_destroy = false

}

resource "google_project_service" "compute" {

  service = "compute.googleapis.com"

  disable_on_destroy = false

}

resource "google_project_service" "storage" {

  service = "storage.googleapis.com"

  disable_on_destroy = false

}

#######################################################
# STORAGE BUCKET (Export Destination)
#######################################################

resource "google_storage_bucket" "logs_bucket" {

  name                        = "devops-cert-export-logs-demo"
  location                    = "EU"
 uniform_bucket_level_access = true
  force_destroy               = true

}

#######################################################
# SERVICE ACCOUNT FOR VM
#######################################################

resource "google_service_account" "vm_sa" {

  account_id   = "logging-export-demo"
  display_name = "Logging Export Demo VM"

}

#######################################################
# IAM FOR VM
#######################################################

resource "google_project_iam_member" "log_writer" {

  project = "devops-cert-labs"

  role = "roles/logging.logWriter"

  member = "serviceAccount:${google_service_account.vm_sa.email}"

}

resource "google_project_iam_member" "metric_writer" {

  project = "devops-cert-labs"

  role = "roles/monitoring.metricWriter"

  member = "serviceAccount:${google_service_account.vm_sa.email}"

}

#######################################################
# DEMO USER
#######################################################

resource "google_service_account" "logging_admin" {

  account_id   = "logging-config-user"
  display_name = "Logging Config User"

}

#######################################################
# CORRECT ANSWER
#######################################################

resource "google_project_iam_member" "logging_config_writer" {

  project = "devops-cert-labs"

  role = "roles/logging.configWriter"

  member = "serviceAccount:${google_service_account.logging_admin.email}"

}

#######################################################
# VM
#######################################################

resource "google_compute_instance" "logging_demo" {

  name         = "logging-export-demo"
  machine_type = "e2-small"
  zone         = "europe-west1-b"

  boot_disk {

    initialize_params {

      image = "debian-cloud/debian-12"

    }

  }

  network_interface {

    network = "default"

    access_config {}

  }

  service_account {

    email = google_service_account.vm_sa.email

    scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

  }

  metadata_startup_script = <<EOF
#!/bin/bash
set -eux

apt-get update
apt-get install -y curl

curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh
bash add-google-cloud-ops-agent-repo.sh --also-install

cat >/etc/google-cloud-ops-agent/config.yaml <<CONFIG
logging:
  receivers:
    app:
      type: files
      include_paths:
        - /var/log/application.log

  service:
    pipelines:
      app_pipeline:
        receivers:
          - app
CONFIG

touch /var/log/application.log
chmod 666 /var/log/application.log

systemctl restart google-cloud-ops-agent

cat >/usr/local/bin/logger.sh <<SCRIPT
#!/bin/bash

while true
do
    echo "\$(date) INFO Application running" >> /var/log/application.log
    sleep 5
done
SCRIPT

chmod +x /usr/local/bin/logger.sh
nohup /usr/local/bin/logger.sh >/dev/null 2>&1 &
EOF

  depends_on = [

    google_project_service.compute,
    google_project_service.logging,
    google_project_iam_member.log_writer

  ]

}

#######################################################
# LOG EXPORT
#######################################################

resource "google_logging_project_sink" "logs_export" {

  name = "application-export"

  destination = "storage.googleapis.com/${google_storage_bucket.logs_bucket.name}"

  unique_writer_identity = true

  filter = <<EOF
resource.type="gce_instance"
EOF

}

#######################################################
# ALLOW THE SINK TO WRITE
#######################################################

resource "google_storage_bucket_iam_member" "sink_permission" {

  bucket = google_storage_bucket.logs_bucket.name

  role = "roles/storage.objectCreator"

  member = google_logging_project_sink.logs_export.writer_identity

}

#######################################################
# OUTPUTS
#######################################################

output "bucket_name" {

  value = google_storage_bucket.logs_bucket.name

}

output "sink_name" {

  value = google_logging_project_sink.logs_export.name

}

output "logging_config_service_account" {

  value = google_service_account.logging_admin.email

}

output "vm_external_ip" {

  value = google_compute_instance.logging_demo.network_interface[0].access_config[0].nat_ip

}