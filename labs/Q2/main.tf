terraform {

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = "devops-cert-labs"
  region  = "europe-west1"
  zone    = "europe-west1-b"
}

resource "google_compute_instance" "vm" {
  name         = "monitoring-lab-vm"
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

  tags = ["monitoring-lab"]

  metadata_startup_script = <<-EOT
#!/bin/bash
apt-get update
apt-get install -y stress-ng
while true; do
  stress-ng --cpu 1 --timeout 30s
  sleep 30
done
EOT
}

resource "google_monitoring_dashboard" "cpu_dashboard" {
  dashboard_json = <<EOF
{
  "displayName": "CPU Dashboard",
  "gridLayout": {
    "columns": 1,
    "widgets": [
      {
        "title": "CPU Utilization",
        "xyChart": {
          "dataSets": [
            {
              "plotType": "LINE",
              "timeSeriesQuery": {
                "timeSeriesFilter": {
                  "filter": "metric.type=\"compute.googleapis.com/instance/cpu/utilization\"",
                  "aggregation": {
                    "alignmentPeriod": "60s",
                    "perSeriesAligner": "ALIGN_MEAN"
                  }
                }
              }
            }
          ],
          "timeshiftDuration": "0s",
          "yAxis": {
            "label": "CPU",
            "scale": "LINEAR"
          }
        }
      }
    ]
  }
}
EOF
}
resource "google_project_iam_member" "monitoring_viewer" {
  project = "devops-cert-labs"
  role    = "roles/monitoring.viewer"
  member  = "user:javiergaragu03@gmail.com"
}

output "dashboard_resource_name" {
  value = google_monitoring_dashboard.cpu_dashboard.id
}

output "dashboard_url" {
  value = "https://console.cloud.google.com/monitoring/dashboards/custom/${element(reverse(split("/", google_monitoring_dashboard.cpu_dashboard.id)), 0)}?project=devops-cert-labs"
}
