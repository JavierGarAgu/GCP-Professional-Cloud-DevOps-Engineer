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

