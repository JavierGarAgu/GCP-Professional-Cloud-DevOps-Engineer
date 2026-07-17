terraform {

  required_version = ">= 1.5"

  required_providers {

    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }

    random = {
      source  = "hashicorp/random"
      version = "~> 3.7"
    }

  }

}

#################################################
# PROVIDER
#################################################

provider "google" {

  project = "devops-cert-labs"
  region  = "europe-west1"
  zone    = "europe-west1-b"

}

#################################################
# ENABLE APIS
#################################################

resource "google_project_service" "compute" {

  service = "compute.googleapis.com"

  disable_on_destroy = false

}

resource "google_project_service" "storage" {

  service = "storage.googleapis.com"

  disable_on_destroy = false

}

#################################################
# RANDOM SUFFIX
#################################################

resource "random_id" "suffix" {

  byte_length = 3

}

#################################################
# SERVICE ACCOUNT
#################################################

resource "google_service_account" "renderer" {

  account_id   = "spot-renderer"
  display_name = "Spot Renderer"

}

#################################################
# IAM
#################################################

resource "google_project_iam_member" "storage_admin" {

  project = "devops-cert-labs"

  role = "roles/storage.objectAdmin"

  member = "serviceAccount:${google_service_account.renderer.email}"

}

#################################################
# INPUT BUCKET
#################################################

resource "google_storage_bucket" "input" {

  name = "video-input-${random_id.suffix.hex}"

  location = "EU"

  uniform_bucket_level_access = true

  force_destroy = true

}

#################################################
# OUTPUT BUCKET
#################################################

resource "google_storage_bucket" "output" {

  name = "video-output-${random_id.suffix.hex}"

  location = "EU"

  uniform_bucket_level_access = true

  force_destroy = true

}

#################################################
# SAMPLE VIDEO
#################################################

resource "google_storage_bucket_object" "sample_video" {

  name = "sample.mp4"

  bucket = google_storage_bucket.input.name

  source = "${path.module}/sample.mp4"

}

#################################################
# FIREWALL
#################################################

resource "google_compute_firewall" "ssh" {

  name = "allow-ssh-renderer"

  network = "default"

  allow {

    protocol = "tcp"

    ports = ["22"]

  }

  source_ranges = [
    "0.0.0.0/0"
  ]

}

#################################################
# RANDOM STARTUP DELAY
#################################################

locals {

  input_bucket = google_storage_bucket.input.name

  output_bucket = google_storage_bucket.output.name

}

#################################################
# SPOT VM
#################################################

resource "google_compute_instance" "renderer" {

  name         = "spot-video-renderer"
  machine_type = "n1-standard-4"
  zone         = "europe-west1-b"

  tags = [
    "ssh"
  ]

  boot_disk {

    initialize_params {

      image = "ubuntu-os-cloud/ubuntu-2204-lts"

      size = 30

    }

  }

  network_interface {

    network = "default"

    access_config {}

  }

  #################################################
  # SPOT (PREEMPTIBLE) CONFIGURATION
  #################################################

  scheduling {

    preemptible       = true
    automatic_restart = false

  }

  service_account {

    email = google_service_account.renderer.email

    scopes = [
      "cloud-platform"
    ]

  }

  metadata_startup_script = <<EOF
#!/bin/bash
set -euxo pipefail

exec >/var/log/startup.log 2>&1

echo "==============================="
echo "VIDEO RENDERING LAB"
echo "==============================="

#################################################
# UPDATE SYSTEM
#################################################

apt-get update

#################################################
# INSTALL FFMPEG
#################################################

DEBIAN_FRONTEND=noninteractive apt-get install -y \
ffmpeg \
curl \
wget

#################################################
# VERIFY GOOGLE CLOUD SDK
#################################################

if ! command -v gsutil >/dev/null 2>&1; then
    echo "ERROR: gsutil is not installed."
    exit 1
fi

gsutil version

#################################################
# CREATE WORK DIRECTORY
#################################################

mkdir -p /opt/render

cd /opt/render

#################################################
# DOWNLOAD VIDEO
#################################################

echo "Downloading sample video..."

gsutil cp gs://${local.input_bucket}/sample.mp4 input.mp4

#################################################
# VERIFY DOWNLOAD
#################################################

ls -lh

#################################################
# RENDER VIDEO
#################################################

echo "Rendering video..."

ffmpeg \
-y \
-i input.mp4 \
-vf scale=1280:720 \
output.mp4

#################################################
# VERIFY OUTPUT
#################################################

ls -lh output.mp4

#################################################
# UPLOAD RESULT
#################################################

echo "Uploading rendered video..."

gsutil cp output.mp4 gs://${local.output_bucket}/output.mp4

#################################################
# VERIFY OUTPUT BUCKET
#################################################

echo "Listing output bucket..."

gsutil ls gs://${local.output_bucket}

#################################################
# FINISHED
#################################################

echo "=================================="
echo "VIDEO SUCCESSFULLY RENDERED"
echo "=================================="
echo "Input bucket : ${local.input_bucket}"
echo "Output bucket: ${local.output_bucket}"
echo "=================================="

EOF

  depends_on = [

    google_project_service.compute,

    google_project_service.storage,

    google_project_iam_member.storage_admin,

    google_storage_bucket.input,

    google_storage_bucket.output,

    google_storage_bucket_object.sample_video

  ]

}

#################################################
# OUTPUTS
#################################################

output "spot_vm_name" {

  description = "Spot VM name"

  value = google_compute_instance.renderer.name

}

output "external_ip" {

  description = "External IP"

  value = google_compute_instance.renderer.network_interface[0].access_config[0].nat_ip

}

output "input_bucket" {

  description = "Bucket containing the original video"

  value = google_storage_bucket.input.name

}

output "output_bucket" {

  description = "Bucket containing the rendered video"

  value = google_storage_bucket.output.name

}

output "ssh_command" {

  description = "SSH command"

  value = "gcloud compute ssh ${google_compute_instance.renderer.name} --zone=${google_compute_instance.renderer.zone}"

}
