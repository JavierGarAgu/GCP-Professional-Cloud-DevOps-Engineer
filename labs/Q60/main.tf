terraform {

  required_version = ">= 1.5"

  required_providers {

    google = {

      source  = "hashicorp/google"
      version = "~> 5.0"

    }

    random = {

      source = "hashicorp/random"

    }

    local = {

      source = "hashicorp/local"

    }

  }

}

####################################################
# PROVIDER
####################################################

provider "google" {

  project = "devops-cert-labs-v2"
  region  = "europe-west1"

}

####################################################
# ENABLE REQUIRED APIS
####################################################

resource "google_project_service" "services" {

  for_each = toset([

    "appengine.googleapis.com",
    "storage.googleapis.com"

  ])

  service = each.key

  disable_on_destroy = false

}

####################################################
# APP ENGINE
####################################################

# IMPORT THIS RESOURCE IF APP ENGINE ALREADY EXISTS
#
# terraform import google_app_engine_application.app devops-cert-labs-v2
#

resource "google_app_engine_application" "app" {

  location_id = "europe-west"

  depends_on = [

    google_project_service.services

  ]

}

####################################################
# RANDOM SUFFIX
####################################################

resource "random_id" "bucket" {

  byte_length = 4

}

####################################################
# CLOUD STORAGE
####################################################

resource "google_storage_bucket" "images" {

  name = "appengine-idle-lab-${random_id.bucket.hex}"

  location = "EU"

  uniform_bucket_level_access = true

  force_destroy = true

  depends_on = [

    google_project_service.services

  ]

}

####################################################
# GENERATE app.yaml
####################################################

resource "local_file" "app_yaml" {

  filename = "${path.module}/app.yaml"

  content = <<EOF
runtime: python311

entrypoint: gunicorn -b :$${PORT} main:app

automatic_scaling:

  min_idle_instances: 0

  max_idle_instances: 1

  min_pending_latency: automatic

  max_pending_latency: automatic
EOF

}

####################################################
# GENERATE requirements.txt
####################################################

resource "local_file" "requirements" {

  filename = "${path.module}/requirements.txt"

  content = <<EOF
Flask
gunicorn
google-cloud-storage
EOF

}
####################################################
# GENERATE main.py
####################################################

resource "local_file" "main_py" {

  filename = "${path.module}/main.py"

  content = <<EOF
from flask import Flask, jsonify
import time
import random
import os

app = Flask(__name__)

####################################################
# SIMULATE COLD START
####################################################

cold_start = True

####################################################
# ROOT
####################################################

@app.route("/")
def home():

    global cold_start

    start = time.time()

    if cold_start:

        # Simulate a cold start
        time.sleep(5)

        cold_start = False

        cold = True

    else:

        time.sleep(random.uniform(0.05, 0.15))

        cold = False

    latency = round((time.time() - start) * 1000, 2)

    return jsonify({

        "message": "App Engine Idle Instances Lab",

        "latency_ms": latency,

        "cold_start": cold,

        "pid": os.getpid()

    })

####################################################
# RESET
####################################################

@app.route("/reset")
def reset():

    global cold_start

    cold_start = True

    return jsonify({

        "status": "Cold start reset"

    })

####################################################
# HEALTH
####################################################

@app.route("/health")
def health():

    return jsonify({

        "status": "healthy"

    })

####################################################
# METRICS
####################################################

@app.route("/metrics")
def metrics():

    return jsonify({

        "idle_instances": "Configure min_idle_instances in app.yaml",

        "exercise": "Compare latency before and after increasing min_idle_instances"

    })

####################################################
# START
####################################################

if __name__ == "__main__":

    app.run(

        host="0.0.0.0",

        port=int(os.environ.get("PORT", 8080))

    )

EOF

}

####################################################
# OUTPUTS
####################################################

output "application_url" {

  value = "https://${google_app_engine_application.app.default_hostname}"

}

output "bucket_name" {

  value = google_storage_bucket.images.name

}

output "next_steps" {

  value = <<EOF

Infrastructure successfully created.

Deploy the application:

gcloud app deploy app.yaml

Open:

https://${google_app_engine_application.app.default_hostname}

Health endpoint:

https://${google_app_engine_application.app.default_hostname}/health

Metrics endpoint:

https://${google_app_engine_application.app.default_hostname}/metrics

Reset cold start:

https://${google_app_engine_application.app.default_hostname}/reset

Load test:

hey -n 500 -c 50 https://${google_app_engine_application.app.default_hostname}

Now edit app.yaml.

Change:

min_idle_instances: 0

to

min_idle_instances: 2

Deploy again:

gcloud app deploy app.yaml

Repeat the load test.

Expected result:

The first deployment with zero idle instances produces more cold starts after traffic spikes.

Keeping idle instances warm reduces latency because App Engine already has running instances ready to serve requests.

This reproduces the correct answer to the Professional Cloud DevOps Engineer exam question.

EOF

}
