
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


