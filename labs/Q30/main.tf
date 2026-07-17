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
# ENABLE APIS
####################################################

resource "google_project_service" "services" {

  for_each = toset([

    "compute.googleapis.com",
    "logging.googleapis.com",
    "monitoring.googleapis.com"

  ])


  service = each.key

  disable_on_destroy = false

}



####################################################
# SERVICE ACCOUNT
####################################################

data "google_compute_default_service_account" "default" {}



resource "google_project_iam_member" "metric_writer" {

  project = "devops-cert-labs"

  role = "roles/monitoring.metricWriter"

  member = "serviceAccount:${data.google_compute_default_service_account.default.email}"

}



####################################################
# BACKEND SIMULATING GKE APPLICATION
####################################################


resource "google_compute_instance" "backend" {


  name = "gke-backend-simulator"


  machine_type = "e2-micro"


  zone = "europe-west1-b"



  depends_on = [

    google_project_service.services

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



  tags = [

    "backend"

  ]



  service_account {


    email = data.google_compute_default_service_account.default.email


    scopes = [

      "https://www.googleapis.com/auth/cloud-platform"

    ]

  }



  metadata_startup_script = <<SCRIPT

#!/bin/bash

set -euxo pipefail

exec > >(tee /var/log/backend-startup.log) 2>&1


echo "Installing dependencies"


apt-get update

apt-get install -y \
python3 \
python3-pip \
python3-venv



mkdir -p /opt/backend



python3 -m venv /opt/backend/venv



/opt/backend/venv/bin/pip install --upgrade pip



/opt/backend/venv/bin/pip install flask



cat > /opt/backend/app.py <<PY


from flask import Flask, jsonify
import time


app = Flask(__name__)


healthy = True



@app.route("/")

def index():

    if not healthy:

        return jsonify({
            "status":"FAILED"
        }),500


    return jsonify({

        "service":"GKE backend simulator",

        "status":"healthy",

        "timestamp":time.time()

    })



@app.route("/health")

def health():

    return "OK",200



@app.route("/fail")

def fail():

    global healthy

    healthy=False

    return "Backend failed"



@app.route("/recover")

def recover():

    global healthy

    healthy=True

    return "Backend recovered"



app.run(
    host="0.0.0.0",
    port=8080
)

PY



cat >/etc/systemd/system/backend.service <<EOF

[Unit]

Description=Backend Flask Service

After=network.target



[Service]

WorkingDirectory=/opt/backend

ExecStart=/opt/backend/venv/bin/python /opt/backend/app.py

Restart=always

User=root



[Install]

WantedBy=multi-user.target

EOF



systemctl daemon-reload

systemctl enable backend

systemctl restart backend



echo "BACKEND READY"


SCRIPT


}



resource "google_compute_firewall" "backend" {


  name = "allow-backend"



  network = "default"



  allow {

    protocol = "tcp"

    ports = ["8080"]

  }



  source_ranges = [

    "0.0.0.0/0"

  ]



  target_tags = [

    "backend"

  ]


}




####################################################
# THIRD PARTY CDN SIMULATION
####################################################


resource "google_compute_instance" "cdn" {


  name = "third-party-cdn"



  machine_type = "e2-micro"



  zone = "europe-west1-b"



  depends_on = [

    google_compute_instance.backend

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



  tags = [

    "cdn"

  ]



  service_account {


    email = data.google_compute_default_service_account.default.email



    scopes = [

      "https://www.googleapis.com/auth/cloud-platform"

    ]


  }



  metadata_startup_script = <<SCRIPT

#!/bin/bash

set -euxo pipefail

exec > >(tee /var/log/cdn-startup.log) 2>&1



apt-get update


apt-get install -y \
python3 \
python3-pip \
python3-venv



mkdir -p /opt/cdn



python3 -m venv /opt/cdn/venv



/opt/cdn/venv/bin/pip install --upgrade pip


/opt/cdn/venv/bin/pip install flask requests



cat > /opt/cdn/app.py <<PY


from flask import Flask,jsonify

import requests



app = Flask(__name__)



enabled=True



BACKEND = "http://${google_compute_instance.backend.network_interface[0].network_ip}:8080"

@app.route("/")

def proxy():

    global enabled


    if not enabled:

        return jsonify({

            "cdn":"DOWN"

        }),503



    try:

        response=requests.get(

            BACKEND,

            timeout=5

        )


        return response.text,response.status_code



    except Exception as e:


        return jsonify({

            "error":str(e)

        }),500





@app.route("/cdn/fail")

def fail():

    global enabled

    enabled=False

    return "CDN disabled"





@app.route("/cdn/recover")

def recover():

    global enabled

    enabled=True

    return "CDN recovered"





@app.route("/cdn/status")

def status():

    return jsonify({

        "enabled":enabled

    })





app.run(

    host="0.0.0.0",

    port=80

)

PY



cat >/etc/systemd/system/cdn.service <<EOF

[Unit]

Description=CDN Simulator

After=network.target



[Service]

WorkingDirectory=/opt/cdn

ExecStart=/opt/cdn/venv/bin/python /opt/cdn/app.py

Restart=always

User=root



[Install]

WantedBy=multi-user.target

EOF



systemctl daemon-reload

systemctl enable cdn

systemctl restart cdn



echo "CDN READY"



SCRIPT


}



resource "google_compute_firewall" "cdn" {


  name = "allow-cdn"



  network = "default"



  allow {


    protocol = "tcp"


    ports = ["80"]


  }



  source_ranges = [

    "0.0.0.0/0"

  ]



  target_tags = [

    "cdn"

  ]


}

####################################################
# SYNTHETIC CLIENT
#
# Simulates real user traffic
# Measures availability from outside CDN
####################################################


resource "google_compute_instance" "synthetic_client" {


  name = "synthetic-monitoring-client"


  machine_type = "e2-micro"


  zone = "europe-west1-b"



  depends_on = [

    google_compute_instance.cdn

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



  tags = [

    "synthetic"

  ]



  service_account {


    email = data.google_compute_default_service_account.default.email


    scopes = [

      "https://www.googleapis.com/auth/cloud-platform"

    ]

  }





  metadata_startup_script = <<SCRIPT

#!/bin/bash

set -euxo pipefail

exec > >(tee /var/log/synthetic-startup.log) 2>&1

echo "===== Installing packages ====="

apt-get update

DEBIAN_FRONTEND=noninteractive apt-get install -y \
python3 \
python3-pip \
python3-venv

mkdir -p /opt/synthetic

python3 -m venv /opt/synthetic/venv

/opt/synthetic/venv/bin/pip install --upgrade pip

/opt/synthetic/venv/bin/pip install Flask requests

cat >/opt/synthetic/monitor.py <<PY
from flask import Flask, jsonify
import requests
import threading
import time

app = Flask(__name__)

CDN_URL = "http://${google_compute_instance.cdn.network_interface[0].access_config[0].nat_ip}"

total_requests = 0
successful_requests = 0
failed_requests = 0


def check_request():

    global total_requests
    global successful_requests
    global failed_requests

    total_requests += 1

    try:

        response = requests.get(
            CDN_URL,
            timeout=5
        )

        if response.status_code == 200:
            successful_requests += 1
        else:
            failed_requests += 1

    except Exception as e:

        print(e)

        failed_requests += 1


def monitor():

    while True:

        check_request()

        time.sleep(30)


def availability_sli():

    if total_requests == 0:
        return 100

    return round(
        (successful_requests / total_requests) * 100,
        2
    )


@app.route("/metrics")
def metrics():

    return jsonify({

        "requests": total_requests,

        "success": successful_requests,

        "failed": failed_requests,

        "availability_sli": availability_sli()

    })


@app.route("/check")
def check():

    check_request()

    return jsonify({

        "requests": total_requests,

        "success": successful_requests,

        "failed": failed_requests,

        "availability_sli": availability_sli()

    })


@app.route("/reset")
def reset():

    global total_requests
    global successful_requests
    global failed_requests

    total_requests = 0
    successful_requests = 0
    failed_requests = 0

    return jsonify({

        "status": "reset"

    })


threading.Thread(
    target=monitor,
    daemon=True
).start()


app.run(
    host="0.0.0.0",
    port=5000
)
PY

cat >/etc/systemd/system/synthetic.service <<EOF
[Unit]
Description=Synthetic Monitoring Client
After=network.target

[Service]
WorkingDirectory=/opt/synthetic
ExecStart=/opt/synthetic/venv/bin/python /opt/synthetic/monitor.py
Restart=always
User=root

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload

systemctl enable synthetic

systemctl restart synthetic

echo "===== Synthetic Client Ready ====="

systemctl status synthetic --no-pager || true

ss -tulpn | grep 5000 || true



SCRIPT


}




####################################################
# SYNTHETIC FIREWALL
####################################################


resource "google_compute_firewall" "synthetic" {


  name = "allow-synthetic-monitor"



  network = "default"



  allow {


    protocol = "tcp"


    ports = [

      "5000"

    ]


  }



  source_ranges = [

    "0.0.0.0/0"

  ]



  target_tags = [

    "synthetic"

  ]


}





####################################################
# CUSTOM MONITORING PERMISSION
####################################################


resource "google_project_iam_member" "monitoring_writer" {


  project = "devops-cert-labs"



  role = "roles/monitoring.metricWriter"



  member = "serviceAccount:${data.google_compute_default_service_account.default.email}"


}





####################################################
# OUTPUTS
####################################################


output "cdn_url" {


  value = "http://${google_compute_instance.cdn.network_interface[0].access_config[0].nat_ip}"

}



output "cdn_fail" {


  value = "curl http://${google_compute_instance.cdn.network_interface[0].access_config[0].nat_ip}/cdn/fail"

}



output "cdn_recover" {


  value = "curl http://${google_compute_instance.cdn.network_interface[0].access_config[0].nat_ip}/cdn/recover"

}



output "cdn_status" {


  value = "curl http://${google_compute_instance.cdn.network_interface[0].access_config[0].nat_ip}/cdn/status"

}



output "backend_url" {


  value = "http://${google_compute_instance.backend.network_interface[0].access_config[0].nat_ip}:8080"

}



output "synthetic_metrics" {


  value = "http://${google_compute_instance.synthetic_client.network_interface[0].access_config[0].nat_ip}:5000/metrics"

}



output "correct_exam_answer" {


  value = "B and E - Client instrumentation and Synthetic monitoring detect failures before CDN or Load Balancer."

}
