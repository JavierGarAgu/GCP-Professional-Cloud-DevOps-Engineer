terraform {

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

#
# Enable APIs
#

resource "google_project_service" "compute" {

  service = "compute.googleapis.com"

}

resource "google_project_service" "networkmanagement" {

  service = "networkmanagement.googleapis.com"

}

#
# VPC A
#

resource "google_compute_network" "vpc_a" {

  name                    = "vpc-a"

  auto_create_subnetworks = false

}

resource "google_compute_subnetwork" "subnet_a" {

  name          = "subnet-a"

  region        = "europe-west1"

  network       = google_compute_network.vpc_a.id

  ip_cidr_range = "10.10.1.0/24"

}

#
# Firewall A
#

resource "google_compute_firewall" "ssh_a" {

  name = "allow-ssh-a"

  network = google_compute_network.vpc_a.name

  allow {

    protocol = "tcp"

    ports = ["22"]

  }

  source_ranges = ["0.0.0.0/0"]

}

#
# VM A
#

resource "google_compute_instance" "vm_a" {

  depends_on = [

    google_project_service.compute

  ]

  name = "vm-a"

  zone = "europe-west1-b"

  machine_type = "e2-micro"

  boot_disk {

    initialize_params {

      image = "debian-cloud/debian-12"

    }

  }

  network_interface {

    subnetwork = google_compute_subnetwork.subnet_a.id

    access_config {}

  }

}

#
# VPC B
#

resource "google_compute_network" "vpc_b" {

  name                    = "vpc-b"

  auto_create_subnetworks = false

}

resource "google_compute_subnetwork" "subnet_b" {

  name          = "subnet-b"

  region        = "europe-west1"

  network       = google_compute_network.vpc_b.id

  ip_cidr_range = "10.20.1.0/24"

}

#
# Firewall B
#

resource "google_compute_firewall" "ssh_b" {

  name = "allow-ssh-b"

  network = google_compute_network.vpc_b.name

  allow {

    protocol = "tcp"

    ports = ["22"]

  }

  source_ranges = ["0.0.0.0/0"]

}

#
# VM B
#

resource "google_compute_instance" "vm_b" {

  depends_on = [

    google_project_service.compute

  ]

  name = "vm-b"

  zone = "europe-west1-b"

  machine_type = "e2-micro"

  boot_disk {

    initialize_params {

      image = "debian-cloud/debian-12"

    }

  }

  network_interface {

    subnetwork = google_compute_subnetwork.subnet_b.id

    access_config {}

  }

}

output "vm_a_internal_ip" {

  value = google_compute_instance.vm_a.network_interface[0].network_ip

}

output "vm_b_internal_ip" {

  value = google_compute_instance.vm_b.network_interface[0].network_ip

}