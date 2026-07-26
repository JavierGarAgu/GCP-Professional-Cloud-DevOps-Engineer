terraform {

  required_version = ">= 1.5"

  required_providers {

    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }

  }

}

provider "google" {

  project = "devops-cert-labs-v3"
  region  = "europe-west1"

}

#################################################
# ENABLE REQUIRED APIS
#################################################

resource "google_project_service" "services" {

  for_each = toset([
    "logging.googleapis.com",
    "pubsub.googleapis.com",
    "compute.googleapis.com"
  ])

  project = "devops-cert-labs-v3"
  service = each.key

  disable_on_destroy = false

}

#################################################
# PUB/SUB TOPIC
#################################################

resource "google_pubsub_topic" "security_logs" {

  depends_on = [
    google_project_service.services
  ]

  name = "security-logs-topic"

}

#################################################
# PUB/SUB SUBSCRIPTION
#################################################

resource "google_pubsub_subscription" "security_logs" {

  depends_on = [
    google_pubsub_topic.security_logs
  ]

  name  = "security-logs-sub"
  topic = google_pubsub_topic.security_logs.name

}

#################################################
# LOGGING SINK
#################################################

resource "google_logging_project_sink" "security_sink" {

  depends_on = [
    google_pubsub_topic.security_logs
  ]

  name = "project-security-sink"

  destination = "pubsub.googleapis.com/${google_pubsub_topic.security_logs.id}"

}

#################################################
# ALLOW LOGGING TO PUBLISH TO PUB/SUB
#################################################

resource "google_pubsub_topic_iam_member" "logging_publisher" {

  topic = google_pubsub_topic.security_logs.name

  role = "roles/pubsub.publisher"

  member = google_logging_project_sink.security_sink.writer_identity

}

#################################################
# TEST VM
#################################################

resource "google_compute_instance" "vm" {

  depends_on = [
    google_pubsub_topic_iam_member.logging_publisher
  ]

  name         = "logging-test-vm"
  machine_type = "e2-micro"
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

  metadata_startup_script = <<-EOF
#!/bin/bash

logger "Logging Lab Started"

while true
do
    logger "Generating Cloud Logging entry"
    sleep 30
done
EOF

  service_account {

    scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

  }

}