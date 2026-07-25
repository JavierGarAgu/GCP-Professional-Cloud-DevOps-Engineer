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
#
# GOOGLE PROVIDER
#
#######################################################

provider "google" {

  project = "devops-cert-labs-v3"

  region = "europe-west1"

}

#######################################################
#
# ENABLE REQUIRED APIS
#
#######################################################

locals {

  apis = [

    "compute.googleapis.com",

    "bigquery.googleapis.com",

    "cloudbilling.googleapis.com",

    "billingbudgets.googleapis.com",

    "serviceusage.googleapis.com",

    "iam.googleapis.com"

  ]

}

resource "google_project_service" "services" {

  for_each = toset(local.apis)

  service = each.key

  disable_on_destroy = false

}

#######################################################
#
# BIGQUERY DATASET
#
#######################################################

resource "google_bigquery_dataset" "billing_export" {

  depends_on = [

    google_project_service.services

  ]

  dataset_id = "billing_export"

  friendly_name = "Billing Export Dataset"

  description = "Dataset used for Cloud Billing export"

  location = "EU"

  delete_contents_on_destroy = true

}

#######################################################
#
# SERVICE ACCOUNT
#
#######################################################

resource "google_service_account" "billing_analysis" {

  depends_on = [

    google_project_service.services

  ]

  account_id = "billing-analysis-sa"

  display_name = "Billing Analysis Service Account"

}

#######################################################
#
# IAM
#
#######################################################

resource "google_project_iam_member" "bigquery_admin" {

  project = "devops-cert-labs-v3"

  role = "roles/bigquery.admin"

  member = "serviceAccount:${google_service_account.billing_analysis.email}"

}

resource "google_project_iam_member" "bigquery_job_user" {

  project = "devops-cert-labs-v3"

  role = "roles/bigquery.jobUser"

  member = "serviceAccount:${google_service_account.billing_analysis.email}"

}

resource "google_project_iam_member" "compute_viewer" {

  project = "devops-cert-labs-v3"

  role = "roles/compute.viewer"

  member = "serviceAccount:${google_service_account.billing_analysis.email}"

}

#######################################################
#
# NETWORK
#
#######################################################

resource "google_compute_network" "billing_network" {

  depends_on = [

    google_project_service.services

  ]

  name = "billing-network"

  auto_create_subnetworks = false

}

#######################################################
#
# SUBNETWORK
#
#######################################################

resource "google_compute_subnetwork" "billing_subnet" {

  name = "billing-subnet"

  region = "europe-west1"

  network = google_compute_network.billing_network.id

  ip_cidr_range = "10.10.0.0/24"

}

#######################################################
#
# FIREWALL
#
#######################################################

resource "google_compute_firewall" "allow_ssh" {

  name = "allow-ssh"

  network = google_compute_network.billing_network.name

  allow {

    protocol = "tcp"

    ports = [

      "22"

    ]

  }

  source_ranges = [

    "0.0.0.0/0"

  ]

}
#######################################################
#
# PAYMENTS VM
#
#######################################################

resource "google_compute_instance" "payments" {

  depends_on = [

    google_project_service.services

  ]

  name = "payments-vm"

  zone = "europe-west1-b"

  machine_type = "e2-micro"

  tags = [

    "ssh"

  ]

  labels = {

    system = "payments"

    environment = "production"

    team = "finance"

  }

  boot_disk {

    initialize_params {

      image = "debian-cloud/debian-12"

      size = 20

      type = "pd-balanced"

    }

  }

  network_interface {

    subnetwork = google_compute_subnetwork.billing_subnet.id

    access_config {}

  }

  service_account {

    email = google_service_account.billing_analysis.email

    scopes = [

      "https://www.googleapis.com/auth/cloud-platform"

    ]

  }

  metadata_startup_script = <<EOF
#!/bin/bash

apt-get update

apt-get install -y stress-ng

stress-ng --cpu 2 --timeout 300

EOF

}

#######################################################
#
# INVENTORY VM
#
#######################################################

resource "google_compute_instance" "inventory" {

  depends_on = [

    google_project_service.services

  ]

  name = "inventory-vm"

  zone = "europe-west1-b"

  machine_type = "e2-micro"

  tags = [

    "ssh"

  ]

  labels = {

    system = "inventory"

    environment = "production"

    team = "warehouse"

  }

  boot_disk {

    initialize_params {

      image = "debian-cloud/debian-12"

      size = 20

      type = "pd-balanced"

    }

  }

  network_interface {

    subnetwork = google_compute_subnetwork.billing_subnet.id

    access_config {}

  }

  service_account {

    email = google_service_account.billing_analysis.email

    scopes = [

      "https://www.googleapis.com/auth/cloud-platform"

    ]

  }

  metadata_startup_script = <<EOF
#!/bin/bash

apt-get update

apt-get install -y stress-ng

stress-ng --cpu 2 --timeout 300

EOF

}

#######################################################
#
# FRONTEND VM
#
#######################################################

resource "google_compute_instance" "frontend" {

  depends_on = [

    google_project_service.services

  ]

  name = "frontend-vm"

  zone = "europe-west1-b"

  machine_type = "e2-micro"

  tags = [

    "ssh"

  ]

  labels = {

    system = "frontend"

    environment = "production"

    team = "web"

  }

  boot_disk {

    initialize_params {

      image = "debian-cloud/debian-12"

      size = 20

      type = "pd-balanced"

    }

  }

  network_interface {

    subnetwork = google_compute_subnetwork.billing_subnet.id

    access_config {}

  }

  service_account {

    email = google_service_account.billing_analysis.email

    scopes = [

      "https://www.googleapis.com/auth/cloud-platform"

    ]

  }

  metadata_startup_script = <<EOF
#!/bin/bash

apt-get update

apt-get install -y stress-ng

stress-ng --cpu 2 --timeout 300

EOF

}

#######################################################
#
# OUTPUTS
#
#######################################################

output "billing_dataset" {

  description = "BigQuery dataset for Billing Export"

  value = google_bigquery_dataset.billing_export.dataset_id

}

output "payments_vm" {

  value = google_compute_instance.payments.name

}

output "inventory_vm" {

  value = google_compute_instance.inventory.name

}

output "frontend_vm" {

  value = google_compute_instance.frontend.name

}

output "payments_labels" {

  value = google_compute_instance.payments.labels

}

output "inventory_labels" {

  value = google_compute_instance.inventory.labels

}

output "frontend_labels" {

  value = google_compute_instance.frontend.labels

}

output "bigquery_console" {

  value = "https://console.cloud.google.com/bigquery?project=devops-cert-labs-v3"

}
