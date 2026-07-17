terraform {

  required_version = ">= 1.5"

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

  region = "europe-west1"

  zone = "europe-west1-b"

}

####################################################
# ENABLE APIS
####################################################

resource "google_project_service" "services" {

  for_each = toset([

    "compute.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com"

  ])

  service = each.key

  disable_on_destroy = false

}

####################################################
# DEFAULT SERVICE ACCOUNT
####################################################

data "google_compute_default_service_account" "default" {}

####################################################
# INSTANCE TEMPLATE
####################################################

resource "google_compute_instance_template" "production_template" {

  name_prefix = "capacity-template-"

  machine_type = "n2-standard-16"

  tags = [
    "capacity-lab"
  ]

  disk {

    auto_delete = true

    boot = true

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

  metadata_startup_script = <<SCRIPT
#!/bin/bash

apt-get update

apt-get install -y nginx

echo "<h1>Production Capacity Planning Lab</h1>" >/var/www/html/index.html

systemctl enable nginx

systemctl restart nginx
SCRIPT

}

####################################################
# HEALTH CHECK
####################################################

resource "google_compute_health_check" "http" {

  name = "capacity-health-check"

  check_interval_sec = 10

  timeout_sec = 5

  healthy_threshold = 2

  unhealthy_threshold = 2

  http_health_check {

    port = 80

    request_path = "/"

  }

}

####################################################
# REGIONAL MANAGED INSTANCE GROUP
####################################################

resource "google_compute_region_instance_group_manager" "production" {

  name = "production-mig"

  region = "europe-west1"

  base_instance_name = "production"

  target_size = 2

  version {

    instance_template = google_compute_instance_template.production_template.id

  }

  auto_healing_policies {

    health_check = google_compute_health_check.http.id

    initial_delay_sec = 60

  }

  depends_on = [

    google_project_service.services

  ]

}

####################################################
# AUTOSCALER
####################################################

resource "google_compute_region_autoscaler" "autoscaler" {

  name = "production-autoscaler"

  region = "europe-west1"

  target = google_compute_region_instance_group_manager.production.id

  autoscaling_policy {

    min_replicas = 2

    max_replicas = 10

    cooldown_period = 60

    cpu_utilization {

      target = 0.70

    }

  }

}

####################################################
# FIREWALL
####################################################

resource "google_compute_firewall" "http" {

  name = "capacity-http"

  network = "default"

  target_tags = [
    "capacity-lab"
  ]

  source_ranges = [
    "0.0.0.0/0"
  ]

  allow {

    protocol = "tcp"

    ports = [
      "80"
    ]

  }

}

####################################################
# OUTPUTS
####################################################

output "managed_instance_group" {

  value = google_compute_region_instance_group_manager.production.name

}

output "autoscaler" {

  value = google_compute_region_autoscaler.autoscaler.name

}

output "machine_type" {

  value = "n2-standard-16"

}

output "exam_answer" {

  value = "Answer C"

}

output "why" {

  value = "Large machine types consume many CPUs and other resources. Before deploying a regional Managed Instance Group with autoscaling, you must verify that every target region has enough Compute Engine quota available. Otherwise the autoscaler cannot create new instances during traffic spikes."

}

output "capacity_planning" {

  value = "Capacity planning includes validating regional quotas for CPUs, disks, IP addresses and other Compute Engine resources."

}