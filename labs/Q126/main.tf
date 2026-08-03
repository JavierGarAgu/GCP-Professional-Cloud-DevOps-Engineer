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

  project = "devops-cert-labs-v4"
  region  = "europe-west1"

}


resource "google_compute_instance" "oversized_vm" {

  name         = "oversized-vm"
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

    apt update
    apt install -y stress-ng

    echo "VM ready for Compute Engine Recommender lab"

  EOF


  labels = {

    purpose = "machine-type-recommender-lab"

  }

}
