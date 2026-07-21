terraform {

  required_version = ">= 1.5"

  required_providers {

    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }

    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }

  }

}

#######################################################
#
# PROVIDER
#
#######################################################

provider "google" {

  project = "devops-cert-labs-v2"

  region = "europe-west1"

  zone = "europe-west1-b"

}

#######################################################
#
# ENABLE REQUIRED APIs
#
#######################################################

locals {

  apis = [

    "compute.googleapis.com"

  ]

}

resource "google_project_service" "services" {

  for_each = toset(local.apis)

  service = each.key

  disable_on_destroy = false

}

#######################################################
#
# FIREWALL
#
#######################################################

resource "google_compute_firewall" "http" {

  name = "allow-http"

  network = "default"

  allow {

    protocol = "tcp"

    ports = [

      "8080"

    ]

  }

  source_ranges = [

    "0.0.0.0/0"

  ]

  target_tags = [

    "load-test"

  ]

}

#######################################################
#
# COMPUTE ENGINE
#
#######################################################

resource "google_compute_instance" "web" {

  depends_on = [

    google_project_service.services

  ]

  name = "load-test-lab"

  machine_type = "e2-micro"

  zone = "europe-west1-b"

  tags = [

    "load-test"

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

    email = "default"

    scopes = [

      "https://www.googleapis.com/auth/cloud-platform"

    ]

  }

  #######################################################
  #
  # STARTUP SCRIPT
  #
  #######################################################

  metadata_startup_script = <<-SCRIPT
#!/bin/bash
set -euxo pipefail

exec > >(tee -a /var/log/startup.log) 2>&1

export DEBIAN_FRONTEND=noninteractive

echo "========================================"
echo "Load Test Lab"
echo "Started at: $(date)"
echo "========================================"

#######################################################
#
# UPDATE SYSTEM
#
#######################################################

apt-get update

apt-get install -y \
python3 \
python3-pip \
python3-venv \
curl

#######################################################
#
# CREATE APPLICATION
#
#######################################################

mkdir -p /opt/load-test

cd /opt/load-test

#######################################################
#
# APP
#
#######################################################

cat > app.py <<'EOF'
from flask import Flask

app = Flask(__name__)

@app.route("/")
def home():

    total = 0

    for i in range(7000000):
        total += i

    return f"""
    <h1>Load Testing Lab</h1>
    <p>The application is running correctly.</p>
    <p>CPU workload: {total}</p>
    """

if __name__ == "__main__":
    app.run(host="0.0.0.0", port=8080)
EOF

#######################################################
#
# REQUIREMENTS
#
#######################################################

cat > requirements.txt <<'EOF'
Flask==3.0.3
gunicorn==23.0.0
EOF

#######################################################
#
# PYTHON ENVIRONMENT
#
#######################################################

python3 -m venv venv

source venv/bin/activate

pip install --upgrade pip

pip install -r requirements.txt

#######################################################
#
# START GUNICORN
#
#######################################################

nohup venv/bin/gunicorn \
    --bind 0.0.0.0:8080 \
    --workers 2 \
    app:app >/var/log/gunicorn.log 2>&1 &

#######################################################
#
# WAIT UNTIL WEB IS READY
#
#######################################################

echo "Waiting for Gunicorn..."

for i in {1..30}; do

    if curl -fs http://localhost:8080/ >/dev/null 2>&1; then

        echo ""
        echo "========================================"
        echo "Application is running."
        echo "========================================"

        exit 0

    fi

    sleep 2

done

echo ""
echo "========================================"
echo "Application failed to start."
echo "========================================"

echo ""
echo "Gunicorn log:"
cat /var/log/gunicorn.log

exit 1

SCRIPT

}
#######################################################
#
# LOAD TEST
#
#######################################################

resource "null_resource" "load_test" {

  depends_on = [

    google_compute_instance.web

  ]

  provisioner "local-exec" {

    interpreter = ["PowerShell", "-Command"]

    command = <<-EOT

      Write-Host ""
      Write-Host "========================================="
      Write-Host "Waiting for the application..."
      Write-Host "========================================="

      Start-Sleep -Seconds 90

      $IP = "${google_compute_instance.web.network_interface.0.access_config.0.nat_ip}"

      Write-Host ""
      Write-Host "Application URL:"
      Write-Host "http://$IP`:8080"
      Write-Host ""

      Write-Host "Waiting for HTTP endpoint..."

      do {

        try {

          Invoke-WebRequest `
            -Uri "http://$IP`:8080" `
            -UseBasicParsing `
            -TimeoutSec 5 | Out-Null

          $ready = $true

        }

        catch {

          Start-Sleep -Seconds 5

          $ready = $false

        }

      } until ($ready)

      Write-Host ""
      Write-Host "========================================="
      Write-Host "Starting Load Test"
      Write-Host "========================================="
      Write-Host ""

      .\hey.exe -n 100 -c 10 "http://$IP`:8080"

      Write-Host ""
      Write-Host "========================================="
      Write-Host "Load Test Finished"
      Write-Host "========================================="

    EOT

  }

}

#######################################################
#
# OUTPUTS
#
#######################################################

output "application_url" {

  description = "Application URL"

  value = "http://${google_compute_instance.web.network_interface.0.access_config.0.nat_ip}:8080"

}

output "instance_ip" {

  value = google_compute_instance.web.network_interface.0.access_config.0.nat_ip

}

output "exam_answer" {

  value = "Load test the application before planning scaling."

}
