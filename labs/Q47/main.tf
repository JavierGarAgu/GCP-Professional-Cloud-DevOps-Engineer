terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }
  }
}

provider "google" {

  project = "devops-cert-labs"
  region  = "europe-west1"
  zone    = "europe-west1-b"

}

#########################
# APIs
#########################

resource "google_project_service" "monitoring" {
  service = "monitoring.googleapis.com"

  disable_on_destroy = false
}

#########################
# SERVICE ACCOUNT
#########################

resource "google_service_account" "vm" {
  account_id   = "monitoring-lab"
  display_name = "Monitoring Lab"
}

resource "google_project_iam_member" "metric_writer" {
  project = "devops-cert-labs"
  role    = "roles/monitoring.metricWriter"
  member  = "serviceAccount:${google_service_account.vm.email}"
}

#########################
# VM
#########################

resource "google_compute_instance" "lab" {

  name         = "monitoring-lab"
  machine_type = "e2-micro"
  zone         = "europe-west1-b"

  boot_disk {
    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }
  }

  network_interface {
    network = "default"

    access_config {}
  }

  service_account {
    email  = google_service_account.vm.email
    scopes = ["cloud-platform"]
  }

  metadata_startup_script = <<EOF
#!/bin/bash
set -euxo pipefail

exec >/var/log/startup.log 2>&1


#########################################
# SYSTEM PACKAGES
#########################################

apt-get update

apt-get install -y \
    python3-pip \
    python3-venv


#########################################
# PYTHON VIRTUAL ENVIRONMENT
#########################################

mkdir -p /opt/http-latency

python3 -m venv /opt/http-latency/venv


source /opt/http-latency/venv/bin/activate


pip install --upgrade pip

pip install --upgrade google-cloud-monitoring



#########################################
# PYTHON SCRIPT
#########################################

cat >/opt/http-latency/http_latency_metric.py <<'PYTHON'


import time
import random


from google.cloud import monitoring_v3


from google.api import metric_pb2
from google.api import distribution_pb2

from google.protobuf import timestamp_pb2



PROJECT_ID = "devops-cert-labs"



client = monitoring_v3.MetricServiceClient()


project_name = f"projects/{PROJECT_ID}"



####################################################
# CREATE METRIC DESCRIPTOR
####################################################


descriptor = metric_pb2.MetricDescriptor()


descriptor.type = (
    "custom.googleapis.com/http_latency"
)


descriptor.metric_kind = (
    metric_pb2.MetricDescriptor.GAUGE
)


descriptor.value_type = (
    metric_pb2.MetricDescriptor.DISTRIBUTION
)


descriptor.description = (
    "HTTP latency distribution metric"
)



try:

    client.create_metric_descriptor(

        name=project_name,

        metric_descriptor=descriptor

    )

    print("Metric created")


except Exception as e:

    print("Metric already exists")

    print(e)



####################################################
# CREATE DISTRIBUTION SAMPLE
####################################################


series = monitoring_v3.types.TimeSeries()



series.metric.type = (
    "custom.googleapis.com/http_latency"
)



series.resource.type = "global"



distribution = distribution_pb2.Distribution()



latencies = [

    random.uniform(10,50),
    random.uniform(50,100),
    random.uniform(100,200),
    random.uniform(200,500),
    random.uniform(500,800)

]



distribution.count = len(latencies)


distribution.mean = (
    sum(latencies) / len(latencies)
)


distribution.sum_of_squared_deviation = sum(

    (value - distribution.mean) ** 2

    for value in latencies

)



distribution.bucket_options.explicit_buckets.bounds.extend([

    50,
    100,
    200,
    500,
    1000

])



distribution.bucket_counts.extend([

    sum(value <= 50 for value in latencies),

    sum(50 < value <= 100 for value in latencies),

    sum(100 < value <= 200 for value in latencies),

    sum(200 < value <= 500 for value in latencies),

    sum(value > 500 for value in latencies)

])



####################################################
# WRITE METRIC
####################################################

now = time.time()

seconds = int(now)
nanos = int((now - seconds) * 1_000_000_000)

point = monitoring_v3.types.Point()

point.interval = monitoring_v3.types.TimeInterval(
    end_time={
        "seconds": seconds,
        "nanos": nanos,
    }
)

point.value.distribution_value.CopyFrom(distribution)

series.points.append(point)



client.create_time_series(

    name=project_name,

    time_series=[series]

)



print(
    "Latency distribution metric written successfully"
)



PYTHON



#########################################
# RUN SCRIPT INSIDE VENV
#########################################

/opt/http-latency/venv/bin/python \
    /opt/http-latency/http_latency_metric.py

EOF

  depends_on = [
    google_project_service.monitoring,
    google_project_iam_member.metric_writer
  ]
}

resource "google_project_iam_member" "monitoring_viewer" {
  project = "devops-cert-labs"
  role    = "roles/monitoring.viewer"
  member  = "serviceAccount:${google_service_account.vm.email}"
}

output "instance_ip" {
  value = google_compute_instance.lab.network_interface[0].access_config[0].nat_ip
}
