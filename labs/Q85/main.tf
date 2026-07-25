terraform {

  required_version = ">= 1.5"

  required_providers {

    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }

    time = {
      source  = "hashicorp/time"
      version = "~> 0.11"
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

#################################################
# LOGGING WRITER
#################################################

resource "google_project_iam_member" "logging_writer" {

  project = "devops-cert-labs-v3"

  role = "roles/logging.logWriter"

  member = "serviceAccount:273988622001-compute@developer.gserviceaccount.com"

}

#################################################
# MONITORING METRIC WRITER
#################################################

resource "google_project_iam_member" "monitoring_metric_writer" {

  project = "devops-cert-labs-v3"

  role = "roles/monitoring.metricWriter"

  member = "serviceAccount:273988622001-compute@developer.gserviceaccount.com"

}

resource "google_project_service" "services" {

  for_each = toset([
    "compute.googleapis.com",
    "osconfig.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com"
  ])

  project = "devops-cert-labs-v3"
  service = each.key

  disable_on_destroy = false

}

#################################################
# WAIT FOR API PROPAGATION
#################################################

resource "time_sleep" "wait_after_apis" {

  depends_on = [
    google_project_service.services
  ]

  create_duration = "60s"

}

#################################################
# CREATE OPS AGENT POLICY
#################################################

resource "null_resource" "ops_agent_policy" {

  depends_on = [
    time_sleep.wait_after_apis
  ]

  provisioner "local-exec" {

    interpreter = [
      "PowerShell",
      "-Command"
    ]

    command = "gcloud beta compute instances ops-agents policies create ops-agents-policy --project=devops-cert-labs-v3 --zones=europe-west1-b --group-labels=\"ops-agent=true\" --os-types=\"short-name=debian,version=12\" --agent-rules=\"type=ops-agent,enable-autoupgrade=true\""

  }

}

#################################################
# WAIT FOR POLICY PROPAGATION
#################################################

resource "time_sleep" "wait_after_policy" {

  depends_on = [
    null_resource.ops_agent_policy
  ]

  create_duration = "30s"

}

#################################################
# TEST VM
#################################################

resource "google_compute_instance" "vm" {

  depends_on = [
    time_sleep.wait_after_policy
  ]

  name         = "ops-agent-vm"
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

  labels = {

    ops-agent = "true"

  }

  metadata = {

    enable-osconfig = "TRUE"

  }

  service_account {

    scopes = [
      "https://www.googleapis.com/auth/cloud-platform"
    ]

  }

}