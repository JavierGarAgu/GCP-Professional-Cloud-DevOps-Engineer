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

  region  = "europe-west1"

  zone    = "europe-west1-b"

}

####################################################
# ENABLE REQUIRED APIS
####################################################

resource "google_project_service" "services" {

  for_each = toset([

    "compute.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com"

  ])

  service = each.key

  disable_on_destroy = false

}

####################################################
# DEFAULT SERVICE ACCOUNT
####################################################

data "google_compute_default_service_account" "default" {}

####################################################
# VM INSTANCE
####################################################

resource "google_compute_instance" "incident_lab" {

  name         = "incident-response-lab"

  machine_type = "e2-medium"

  tags = [
    "incident-lab"
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

cat <<EOF >/var/www/html/index.html
<h1>Customer Production Service</h1>
<p>Incident Response Laboratory</p>
EOF

systemctl enable nginx
systemctl restart nginx

logger "Production service started."

SCRIPT

  depends_on = [
    google_project_service.services
  ]

}

####################################################
# FIREWALL
####################################################

resource "google_compute_firewall" "http" {

  name = "incident-http"

  network = "default"

  target_tags = [
    "incident-lab"
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
# UPTIME CHECK
####################################################

resource "google_monitoring_uptime_check_config" "website" {

  display_name = "incident-response-check"

  timeout = "10s"

  period = "60s"

  monitored_resource {

    type = "uptime_url"

    labels = {

      host = google_compute_instance.incident_lab.network_interface[0].access_config[0].nat_ip

    }

  }

  http_check {

    port = 80

    path = "/"

    use_ssl = false

  }

}

####################################################
# CPU ALERT
####################################################

resource "google_monitoring_alert_policy" "cpu_alert" {

  display_name = "High CPU Incident"

  combiner = "OR"

  conditions {

    display_name = "CPU Utilization"

    condition_threshold {

      comparison = "COMPARISON_GT"

      duration = "60s"

      threshold_value = 0.80

      filter = <<EOF
metric.type="compute.googleapis.com/instance/cpu/utilization"
resource.type="gce_instance"
EOF

      aggregations {

        alignment_period = "60s"

        per_series_aligner = "ALIGN_MEAN"

      }

    }

  }

}

####################################################
# OUTPUTS
####################################################

output "vm_name" {

  value = google_compute_instance.incident_lab.name

}

output "external_ip" {

  value = google_compute_instance.incident_lab.network_interface[0].access_config[0].nat_ip

}

output "incident_url" {

  value = "http://${google_compute_instance.incident_lab.network_interface[0].access_config[0].nat_ip}"

}

output "exam_answer" {

  value = "Answer C and D"

}

output "communications_lead" {

  value = "Responsible for keeping stakeholders informed while the Incident Commander focuses on coordinating the technical response."

}

output "customer_impact_assessor" {

  value = "Responsible for evaluating how many users are affected, which services are impacted and how severe the business impact is."

}

output "incident_commander" {

  value = "The Incident Commander delegates communication and customer impact assessment to stay focused on managing the incident."

}