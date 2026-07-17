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

resource "google_project_service" "storage" {

  service = "storage.googleapis.com"

  disable_on_destroy = false

}

#######################################################
# STORAGE BUCKET
#######################################################

resource "google_storage_bucket" "pii_bucket" {

  name                        = "devops-cert-pii-logs-demo"
  location                    = "EU"
  force_destroy               = true
  uniform_bucket_level_access = true

}

#######################################################
# SERVICE ACCOUNT
#######################################################

resource "google_service_account" "vm" {

  account_id   = "logging-demo"
  display_name = "Logging Demo VM"

}

#######################################################
# IAM
#######################################################

resource "google_project_iam_member" "metricwriter" {

  project = "devops-cert-labs"

  role = "roles/monitoring.metricWriter"

  member = "serviceAccount:${google_service_account.vm.email}"

}

resource "google_project_iam_member" "logwriter" {

  project = "devops-cert-labs"

  role = "roles/logging.logWriter"

  member = "serviceAccount:${google_service_account.vm.email}"

}
#######################################################
# VM
#######################################################

resource "google_compute_instance" "vm" {

  name         = "logging-demo"
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

    email = google_service_account.vm.email

    scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

  }

  metadata_startup_script = <<EOF
#!/bin/bash
set -euxo pipefail

exec > >(tee -a /var/log/startup.log) 2>&1

echo "===== STARTUP ====="

apt-get update

DEBIAN_FRONTEND=noninteractive apt-get install -y \
    curl

echo "Installing Google Cloud Ops Agent..."

curl -sSO https://dl.google.com/cloudagents/add-google-cloud-ops-agent-repo.sh

bash add-google-cloud-ops-agent-repo.sh --also-install

sleep 10

echo "Configuring Ops Agent..."

cat >/etc/google-cloud-ops-agent/config.yaml <<CONFIG
logging:
  receivers:
    application:
      type: files
      include_paths:
        - /var/log/application.log

  service:
    pipelines:
      application_pipeline:
        receivers:
          - application
CONFIG

touch /var/log/application.log
chmod 666 /var/log/application.log

systemctl enable google-cloud-ops-agent
systemctl restart google-cloud-ops-agent

cat >/usr/local/bin/log-generator.sh <<SCRIPT
#!/bin/bash

while true
do
    echo "\$(date) INFO Application running normally" >> /var/log/application.log

    if [ \$((RANDOM % 3)) -eq 0 ]; then
        echo "\$(date) INFO userinfo email=user@example.com" >> /var/log/application.log
    fi

    sleep 5
done
SCRIPT

chmod +x /usr/local/bin/log-generator.sh

nohup /usr/local/bin/log-generator.sh >/dev/null 2>&1 &

echo "Startup completed successfully"

logger "Ops Agent installation completed"

EOF

  depends_on = [

    google_project_service.compute,
    google_project_service.logging,
    google_project_service.storage,

    google_project_iam_member.logwriter,

    google_storage_bucket_iam_member.sink_writer

  ]

}
#######################################################
# LOG SINK
#######################################################

resource "google_logging_project_sink" "pii_sink" {

  name = "pii-storage"

  destination = "storage.googleapis.com/${google_storage_bucket.pii_bucket.name}"

  unique_writer_identity = true

  filter = <<EOF
textPayload:"userinfo"
EOF

  depends_on = [
    google_storage_bucket.pii_bucket
  ]

}

#######################################################
# PERMISSION FOR SINK
#######################################################

resource "google_storage_bucket_iam_member" "sink_writer" {

  bucket = google_storage_bucket.pii_bucket.name

  role = "roles/storage.objectCreator"

  member = google_logging_project_sink.pii_sink.writer_identity

}

#######################################################
# LOG EXCLUSION
#######################################################

resource "google_logging_project_exclusion" "exclude_pii" {

  name = "exclude-userinfo"

  description = "Exclude PII logs from Cloud Logging"

  filter = <<EOF
textPayload:"userinfo"
EOF

}

#######################################################
# OUTPUTS
#######################################################

output "vm_ip" {

  value = google_compute_instance.vm.network_interface[0].access_config[0].nat_ip

}

output "bucket" {

  value = google_storage_bucket.pii_bucket.name

}

output "sink_name" {

  value = google_logging_project_sink.pii_sink.name

}