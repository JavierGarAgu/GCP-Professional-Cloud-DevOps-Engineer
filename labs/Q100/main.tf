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
# COMPUTE ENGINE VM
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

  metadata_startup_script = <<-EOF
#!/bin/bash

apt-get update
apt-get install -y nginx

cat > /var/www/html/index.html <<HTML
<!DOCTYPE html>
<html>
<head>
    <title>Firewall Logging Lab</title>
</head>
<body>
    <h1>Google Cloud DevOps Engineer Lab</h1>
    <p>Firewall Rule Logging enabled.</p>
    <p>If you can see this page, the firewall rule allowed your connection.</p>
</body>
</html>
HTML

systemctl enable nginx
systemctl restart nginx
EOF

}

#
# FIREWALL RULE
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

  #
  # Firewall Rules Logging
  #

  log_config {

    metadata = "INCLUDE_ALL_METADATA"

  }

}

#
# OUTPUT
#

output "application_url" {

  value = "http://${google_compute_instance.sre_lab.network_interface[0].access_config[0].nat_ip}"

}