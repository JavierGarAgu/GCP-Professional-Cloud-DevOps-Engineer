terraform {

  required_version = ">= 1.5"

  required_providers {

    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.0"
    }

  }

}

provider "google" {

  project = "devops-cert-labs"
  region  = "europe-west1"

}

####################################################
# ENABLE APIS
####################################################

resource "google_project_service" "container" {

  service = "container.googleapis.com"

  disable_on_destroy = false

}

resource "google_project_service" "logging" {

  service = "logging.googleapis.com"

  disable_on_destroy = false

}

resource "google_project_service" "monitoring" {

  service = "monitoring.googleapis.com"

  disable_on_destroy = false

}

####################################################
# GKE CLUSTER
####################################################

resource "google_container_cluster" "cluster" {

  name     = "cache-miss-lab"
  location = "europe-west1-b"

  deletion_protection = false

  remove_default_node_pool = true

  initial_node_count = 1

  depends_on = [

    google_project_service.container

  ]

}

####################################################
# NODE POOL
####################################################

resource "google_container_node_pool" "node_pool" {

  name     = "primary-pool"

  cluster  = google_container_cluster.cluster.name

  location = google_container_cluster.cluster.location

  node_count = 1

  node_config {

    machine_type = "e2-small"

    disk_type = "pd-standard"

    disk_size_gb = 20

    preemptible = true

    oauth_scopes = [

      "https://www.googleapis.com/auth/cloud-platform"

    ]

  }

}

####################################################
# KUBERNETES AUTH
####################################################

data "google_client_config" "current" {}

provider "kubernetes" {

  host = "https://${google_container_cluster.cluster.endpoint}"

  token = data.google_client_config.current.access_token

  cluster_ca_certificate = base64decode(

    google_container_cluster.cluster.master_auth[0].cluster_ca_certificate

  )

}

####################################################
# NAMESPACE
####################################################

resource "kubernetes_namespace" "production" {

  metadata {

    name = "production"

  }

}

####################################################
# APPLICATION SOURCE
####################################################

resource "kubernetes_config_map" "cache_app" {

  metadata {

    name      = "cache-app"
    namespace = kubernetes_namespace.production.metadata[0].name

  }

  data = {

    "app.py" = <<EOF
from flask import Flask
import random
import logging

app = Flask(__name__)

logging.basicConfig(level=logging.INFO)

@app.route("/")
def home():

    if random.randint(1,3) == 1:
        print("CACHE_MISS", flush=True)

    return "Cache Demo"

app.run(host="0.0.0.0", port=8080)
EOF

    "requirements.txt" = <<EOF
flask
EOF

  }

}

####################################################
# DEPLOYMENT
####################################################

resource "kubernetes_deployment" "cache_app" {

  metadata {

    name      = "cache-app"
    namespace = kubernetes_namespace.production.metadata[0].name

    labels = {

      app = "cache-app"

    }

  }

  spec {

    replicas = 1

    selector {

      match_labels = {

        app = "cache-app"

      }

    }

    template {

      metadata {

        labels = {

          app = "cache-app"

        }

      }

      spec {

        container {

          name  = "cache-app"

          image = "python:3.12-slim"

          working_dir = "/app"

          command = [

            "sh",
            "-c"

          ]

          args = [

            "pip install --no-cache-dir -r /src/requirements.txt && python /src/app.py"

          ]

          port {

            container_port = 8080

          }

          volume_mount {

            name       = "application"
            mount_path = "/src"

          }

          volume_mount {

            name       = "runtime"
            mount_path = "/app"

          }

        }

        volume {

          name = "application"

          config_map {

            name = kubernetes_config_map.cache_app.metadata[0].name

          }

        }

        volume {

          name = "runtime"

          empty_dir {}

        }

      }

    }

  }

}

####################################################
# SERVICE
####################################################

resource "kubernetes_service" "cache_app" {

  metadata {

    name      = "cache-app"
    namespace = kubernetes_namespace.production.metadata[0].name

  }

  spec {

    selector = {

      app = "cache-app"

    }

    port {

      port        = 80
      target_port = 8080

    }

    type = "LoadBalancer"

  }

}

####################################################
# LOGS-BASED METRIC
####################################################

resource "google_logging_metric" "cache_miss" {

  name        = "cache_miss_count"
  description = "Counts CACHE_MISS log entries."

  filter = <<EOF
resource.type="k8s_container"
resource.labels.namespace_name="production"
textPayload:"CACHE_MISS"
EOF

  metric_descriptor {

    metric_kind = "DELTA"

    value_type = "INT64"

    display_name = "Cache Miss Count"

  }

}

####################################################
# MONITORING DASHBOARD
####################################################

resource "google_monitoring_dashboard" "cache_dashboard" {

  dashboard_json = jsonencode({

    displayName = "Cache Miss Dashboard"

    mosaicLayout = {

      columns = 12

      tiles = [

        {

          xPos   = 0
          yPos   = 0
          width  = 12
          height = 4

          widget = {

            title = "Cache Misses Over Time"

            xyChart = {

              dataSets = [

                {

                  plotType = "LINE"

                  timeSeriesQuery = {

                    timeSeriesFilter = {

                      filter = "metric.type=\"logging.googleapis.com/user/cache_miss_count\""

                    }

                  }

                }

              ]

            }

          }

        }

      ]

    }

  })

}

####################################################
# OUTPUTS
####################################################

output "application_ip" {

  value = kubernetes_service.cache_app.status[0].load_balancer[0].ingress[0].ip

}

output "application_url" {

  value = "http://${kubernetes_service.cache_app.status[0].load_balancer[0].ingress[0].ip}"

}