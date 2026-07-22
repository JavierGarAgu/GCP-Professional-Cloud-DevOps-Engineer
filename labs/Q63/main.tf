terraform {

  required_version = ">= 1.5"


  required_providers {

    google = {

      source = "hashicorp/google"

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

  project = "devops-cert-labs-v3"

  region = "europe-west1"

}



####################################################
# ENABLE APIS
####################################################

#gcloud services enable appengine.googleapis.com logging.googleapis.com --project=devops-cert-labs-v3

####################################################
# APP ENGINE
####################################################


resource "google_app_engine_application" "app" {


  location_id = "europe-west"


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


  min_num_instances: 1


  max_num_instances: 2




readiness_check:


  path: "/health"


  check_interval_sec: 5


  timeout_sec: 4


  failure_threshold: 2


  success_threshold: 2




liveness_check:


  path: "/health"


  check_interval_sec: 30


  timeout_sec: 4


  failure_threshold: 4


  success_threshold: 2

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
google-cloud-error-reporting
google-cloud-logging
EOF


}




####################################################
# GENERATE main.py
####################################################


resource "local_file" "main_py" {


filename = "${path.module}/main.py"



content = <<EOF

from flask import Flask, jsonify

import logging

import google.cloud.logging

from google.cloud import error_reporting



app = Flask(__name__)



####################################################
# CLOUD LOGGING
####################################################


logging_client = google.cloud.logging.Client()

logging_client.setup_logging()



logger = logging.getLogger(__name__)



####################################################
# ERROR REPORTING CLIENT
####################################################


error_client = error_reporting.Client()



####################################################
# MAIN ERROR
####################################################


@app.route("/")

def home():


    try:


        raise Exception(

            "Trading engine connection failed: Market data unavailable"

        )



    except Exception:


        error_client.report_exception()



        logger.exception(

            "Trading application custom error"

        )



        return jsonify({


            "message":

            "Custom error reported to Cloud Error Reporting"


        }),500





####################################################
# HEALTH CHECK
####################################################


@app.route("/health")

def health():


    return jsonify({


        "status":

        "healthy"


    })





####################################################
# MANUAL ERROR TEST
####################################################


@app.route("/error")

def error():


    try:


        raise RuntimeError(

            "Order execution service unavailable"

        )


    except Exception:


        error_client.report_exception()


        logger.exception(

            "Manual generated application error"

        )


        return jsonify({


            "error":

            "Reported"


        }),500





if __name__ == "__main__":


    app.run(


        host="0.0.0.0",

        port=8080


    )


EOF


}



####################################################
# OUTPUTS
####################################################


output "application_url" {


  value = "https://${google_app_engine_application.app.default_hostname}"


}



output "next_steps" {


value = <<EOF


Infrastructure created.


Generated files:


- app.yaml

- main.py

- requirements.txt



Deploy application:


gcloud app deploy app.yaml



Test health:


curl https://${google_app_engine_application.app.default_hostname}/health



Generate custom Error Reporting event:


curl https://${google_app_engine_application.app.default_hostname}/



Check errors:


gcloud error-reporting events list



This lab reproduces the Professional Cloud DevOps Engineer question.


The correct answer is D because App Engine Flexible already integrates with Cloud Logging and Error Reporting.


The application uses the Error Reporting Python library to send custom exceptions with stack traces.


EOF


}