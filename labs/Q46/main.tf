terraform {

  required_version = ">= 1.5"

  required_providers {

    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }

  }

}

############################################################
#
# PROVIDER
#
############################################################

provider "google" {

  project = "devops-cert-labs"
  region  = "europe-west1"
  zone    = "europe-west1-b"

}

############################################################
#
# ENABLE REQUIRED APIS
#
############################################################

resource "google_project_service" "services" {

  for_each = toset([

    "compute.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com"

  ])

  service = each.key

  disable_on_destroy = false

}

############################################################
#
# DEFAULT SERVICE ACCOUNT
#
############################################################

data "google_compute_default_service_account" "default" {}

############################################################
#
# FIREWALL
#
############################################################

resource "google_compute_firewall" "http" {

  name = "monitoring-http"

  network = "default"

  allow {

    protocol = "tcp"

    ports = ["80"]

  }

  source_ranges = [

    "0.0.0.0/0"

  ]

  target_tags = [

    "monitoring-lab"

  ]

}

############################################################
#
# COMPUTE ENGINE INSTANCE
#
############################################################

resource "google_compute_instance" "web" {

  depends_on = [

    google_project_service.services

  ]

  name = "monitoring-web"

  machine_type = "e2-small"

  tags = [

    "monitoring-lab"

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

  service_account {

    email = data.google_compute_default_service_account.default.email

    scopes = [

      "https://www.googleapis.com/auth/cloud-platform"

    ]

  }

  metadata_startup_script = <<SCRIPT
#!/bin/bash

apt-get update

apt-get install -y nginx stress

echo "<h1>Monitoring SMS Notification Lab</h1>" >/var/www/html/index.html

systemctl enable nginx
systemctl restart nginx
SCRIPT

}

############################################################
#
# SMS NOTIFICATION CHANNEL
#
############################################################

resource "google_monitoring_notification_channel" "sms" {

  display_name = "On Call Engineer"

  type = "sms"

  labels = {

    number = "++34xxxxxxxxx"

  }

}

############################################################
#
# CPU ALERT POLICY
#
############################################################

resource "google_monitoring_alert_policy" "high_cpu" {

  display_name = "Critical CPU Usage"

  combiner = "OR"

  notification_channels = [

    google_monitoring_notification_channel.sms.id

  ]

  conditions {

    display_name = "CPU utilization > 80%"

    condition_threshold {

      filter = <<FILTER
metric.type="compute.googleapis.com/instance/cpu/utilization"
resource.type="gce_instance"
FILTER

      duration = "120s"

      comparison = "COMPARISON_GT"

      threshold_value = 0.80

      trigger {

        count = 1

      }

      aggregations {

        alignment_period = "60s"

        per_series_aligner = "ALIGN_MEAN"

      }

    }

  }

  alert_strategy {

    auto_close = "1800s"

  }

  documentation {

    content = <<DOC
Critical alert.

CPU utilization has exceeded 80%.

The notification is sent through the SMS notification channel configured in Cloud Monitoring.
DOC

    mime_type = "text/markdown"

  }

}

############################################################
#
# OUTPUTS
#
############################################################

output "vm_name" {

  value = google_compute_instance.web.name

}

output "notification_channel" {

  value = google_monitoring_notification_channel.sms.display_name

}

output "alert_policy" {

  value = google_monitoring_alert_policy.high_cpu.display_name

}

output "exam_answer" {

  value = "Answer C"

}

output "why" {

  value = "Cloud Monitoring provides native SMS notification channels. Team members register their phone numbers, verify them, and the SMS channel can then be attached directly to alerting policies."

}