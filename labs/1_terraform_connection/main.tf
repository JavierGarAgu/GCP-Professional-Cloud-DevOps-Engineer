# https://registry.terraform.io/providers/hashicorp/google/latest/docs/guides/getting_started

provider "google" {
  project = "devops-cert-labs"
  region  = "us-central1"
  zone    = "us-central1-a"
}
data "google_project" "project-name" {
  project_id = "devops-cert-labs"
}

resource "google_compute_instance" "vm_instance" {
  project      = data.google_project.project-name.project_id
  name         = "terraform-instance"
  machine_type = "e2-micro"

  boot_disk {
    initialize_params {
      image = "debian-cloud/debian-11"
    }
  }

  network_interface {
    # A default network is created for all GCP projects
    network = "default"
    access_config {
    }
  }
}