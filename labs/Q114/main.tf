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

  project = "devops-cert-labs-v4"

  region = "europe-west1"

  zone = "europe-west1-b"

}

####################################################
# ENABLE COMPUTE API
####################################################

resource "google_project_service" "compute" {

  service = "compute.googleapis.com"

  disable_on_destroy = false

}

####################################################
# DEFAULT SERVICE ACCOUNT
####################################################

data "google_compute_default_service_account" "default" {}

####################################################
# FIREWALL
####################################################

resource "google_compute_firewall" "ssh" {

  name = "terraform-mig-lab-ssh"

  network = "default"

  allow {

    protocol = "tcp"

    ports = ["22"]

  }

  source_ranges = ["0.0.0.0/0"]

}

####################################################
# INSTANCE TEMPLATE
####################################################

resource "google_compute_instance_template" "web" {

  depends_on = [
    google_project_service.compute
  ]

  name_prefix = "terraform-lifecycle-"

  #
  # Change this later:
  #
  # e2-micro
  # e2-small
  #

  machine_type = "e2-small"

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

    email = data.google_compute_default_service_account.default.email

    scopes = [

      "https://www.googleapis.com/auth/cloud-platform"

    ]

  }

  metadata_startup_script = <<EOF
#!/bin/bash

apt-get update

apt-get install -y nginx

systemctl enable nginx

systemctl start nginx
EOF

  #
  # FIRST RUN:
  #
  # Leave commented.
  #
  # SECOND RUN:
  #
  # Uncomment lifecycle and run apply again.
  #


  lifecycle {

    create_before_destroy = true

  }


}

####################################################
# MANAGED INSTANCE GROUP
####################################################

resource "google_compute_region_instance_group_manager" "web" {

  name = "terraform-lifecycle-mig"

  region = "europe-west1"

  base_instance_name = "web"

  target_size = 1

  version {

    instance_template = google_compute_instance_template.web.id

  }

  named_port {

    name = "http"

    port = 80

  }

}

####################################################
# AUTO HEALING
####################################################

resource "google_compute_health_check" "http" {

  name = "terraform-lifecycle-health"

  http_health_check {

    port = 80

  }

}

####################################################
# OUTPUTS
####################################################

output "instance_template" {

  value = google_compute_instance_template.web.name

}

output "managed_instance_group" {

  value = google_compute_region_instance_group_manager.web.name

}

output "exercise" {

  value = "Change machine_type from e2-micro to e2-small. Then enable create_before_destroy and run terraform apply again."

}
