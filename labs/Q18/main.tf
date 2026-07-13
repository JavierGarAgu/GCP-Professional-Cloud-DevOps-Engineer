terraform {

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

  region = "europe-west1"

  zone = "europe-west1-b"

}



####################################################
# DEVELOPMENT ENVIRONMENT
####################################################

resource "google_compute_instance" "development" {


  name = "development-environment"


  machine_type = "e2-medium"


  zone = "europe-west1-b"



  labels = {

    environment = "development"

    access = "developers"

  }



  boot_disk {

    initialize_params {

      image = "debian-cloud/debian-12"

      size = 20

    }

  }



  network_interface {

    network = "default"


    access_config {}

  }



  metadata = {

    environment = "development"

    purpose = "application-development"

  }


}



####################################################
# TEST ENVIRONMENT
####################################################

resource "google_compute_instance" "testing" {


  name = "testing-environment"


  machine_type = "e2-medium"


  zone = "europe-west1-b"



  labels = {

    environment = "testing"

    access = "testers"

  }



  boot_disk {

    initialize_params {

      image = "debian-cloud/debian-12"

      size = 20

    }

  }



  network_interface {

    network = "default"


    access_config {}

  }



  metadata = {

    environment = "testing"

    purpose = "load-testing-and-experiments"

  }


}



####################################################
# OUTPUTS
####################################################


output "development_vm" {

  value = google_compute_instance.development.name

}



output "testing_vm" {

  value = google_compute_instance.testing.name

}