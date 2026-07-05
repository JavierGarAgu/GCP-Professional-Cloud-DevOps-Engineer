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

}

#
# VM
#

resource "google_compute_instance" "sre_lab" {

  name         = "sre-lab"
  machine_type = "e2-micro"
  zone         = "europe-west1-b"

  tags = [
    "http-server"
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

    scopes = [
      "cloud-platform"
    ]

  }

  metadata = {

    enable-oslogin = "TRUE"

  }

  metadata_startup_script = file("${path.module}/startup.sh")

}

#
# FIREWALL
#

resource "google_compute_firewall" "http" {

  name    = "allow-http"
  network = "default"

  allow {

    protocol = "tcp"
    ports = [
      "80"
    ]

  }

  source_ranges = [
    "0.0.0.0/0"
  ]

  target_tags = [
    "http-server"
  ]

}

output "application_url" {

  value = "http://${google_compute_instance.sre_lab.network_interface[0].access_config[0].nat_ip}"

}