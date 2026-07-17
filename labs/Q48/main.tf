terraform {

  required_version = ">= 1.5"

  required_providers {

    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.38"
    }

  }

}

#######################################################
#
# PROVIDER
#
#######################################################

provider "google" {

  project = "devops-cert-labs"

  region = "europe-west1"

}

#######################################################
#
# REQUIRED APIS
#
#######################################################

locals {

  apis = [

    "container.googleapis.com",
    "monitoring.googleapis.com"

  ]

}

resource "google_project_service" "services" {

  for_each = toset(local.apis)

  service = each.value

  disable_on_destroy = false

}

#######################################################
#
# GKE CLUSTER
#
#######################################################

resource "google_container_cluster" "cluster" {

  depends_on = [

    google_project_service.services

  ]

  name = "openmetrics-lab"

  location = "europe-west1-b"

  deletion_protection = false

  remove_default_node_pool = true

  initial_node_count = 1

  networking_mode = "VPC_NATIVE"

  release_channel {

    channel = "REGULAR"

  }

  monitoring_config {

    managed_prometheus {

      enabled = true

    }

  }

}

#######################################################
#
# NODE POOL
#
#######################################################

resource "google_container_node_pool" "nodes" {

  name = "primary-pool"

  cluster = google_container_cluster.cluster.name

  location = google_container_cluster.cluster.location

  node_count = 1

  node_config {

    machine_type = "e2-small"

    disk_size_gb = 20

    oauth_scopes = [

      "https://www.googleapis.com/auth/cloud-platform"

    ]

  }

}

#######################################################
#
# KUBERNETES AUTH
#
#######################################################

data "google_client_config" "current" {}

provider "kubernetes" {

  host = "https://${google_container_cluster.cluster.endpoint}"

  token = data.google_client_config.current.access_token

  cluster_ca_certificate = base64decode(

    google_container_cluster.cluster.master_auth[0].cluster_ca_certificate

  )

}

#######################################################
#
# NAMESPACE
#
#######################################################

resource "kubernetes_namespace" "production" {

  metadata {

    name = "production"

  }

}
#######################################################
#
# NODE.JS APPLICATION (OpenMetrics)
#
#######################################################

resource "kubernetes_config_map" "node_app" {

  metadata {

    name = "node-app"

    namespace = kubernetes_namespace.production.metadata[0].name

  }

  data = {

    ####################################################################
    # index.js
    ####################################################################

    "index.js" = <<EOF

const express = require("express");
const client = require("prom-client");

const app = express();

const register = new client.Registry();

client.collectDefaultMetrics({

    register

});

const httpLatency = new client.Histogram({

    name: "http_request_duration_ms",

    help: "HTTP request latency",

    buckets: [

        10,
        25,
        50,
        100,
        250,
        500,
        1000

    ]

});

register.registerMetric(httpLatency);

let requests = 0;

app.get("/", async(req,res)=>{

    const end = httpLatency.startTimer();

    const delay = Math.floor(

        Math.random()*400

    );

    await new Promise(resolve=>setTimeout(resolve,delay));

    requests++;

    end();

    res.send(

        "Request " +

        requests +

        " latency " +

        delay +

        " ms"

    );

});

app.get("/metrics",async(req,res)=>{

    res.set(

        "Content-Type",

        register.contentType

    );

    res.end(

        await register.metrics()

    );

});

app.listen(

    8080,

    ()=>{

        console.log(

            "Application started"

        );

    }

);

EOF

    ####################################################################
    # package.json
    ####################################################################

    "package.json" = <<EOF

{

  "name":"openmetrics-demo",

  "version":"1.0.0",

  "dependencies":{

    "express":"^4.19.2",

    "prom-client":"^15.1.3"

  }

}

EOF

  }

}

#######################################################
#
# APPLICATION DEPLOYMENT
#
#######################################################
resource "kubernetes_deployment" "node" {

  metadata {
    name      = "node-app"
    namespace = kubernetes_namespace.production.metadata[0].name
  }

  spec {

    replicas = 1

    selector {
      match_labels = {
        app = "node"
      }
    }

    template {

      metadata {
        labels = {
          app = "node"
        }
      }

      spec {

        container {

          name  = "node"
          image = "node:22-alpine"

          working_dir = "/app"

          command = [
            "sh",
            "-c"
          ]

          args = [
            "cp /src/* /app/ && npm install && node index.js"
          ]

          port {
            name           = "http"
            container_port = 8080
          }

          volume_mount {
            name       = "source"
            mount_path = "/src"
          }

          volume_mount {
            name       = "runtime"
            mount_path = "/app"
          }

        }

        volume {
          name = "source"

          config_map {
            name = kubernetes_config_map.node_app.metadata[0].name
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

#######################################################
#
# APPLICATION SERVICE
#
#######################################################

resource "kubernetes_service" "node" {

  metadata {

    name = "node-app"

    namespace = kubernetes_namespace.production.metadata[0].name

    labels = {

      app = "node"

    }

  }

  spec {

    selector = {

      app = "node"

    }

    port {

      name        = "http"

      port        = 8080

      target_port = 8080

    }

    type = "LoadBalancer"

  }

}

#IAM

#######################################################
#
# IAM PERMISSIONS FOR MANAGED PROMETHEUS
#
#######################################################

data "google_compute_default_service_account" "default" {}


resource "google_project_iam_member" "gke_monitoring_metric_writer" {

  project = "devops-cert-labs"

  role = "roles/monitoring.metricWriter"

  member = "serviceAccount:${data.google_compute_default_service_account.default.email}"

}


resource "google_project_iam_member" "gke_monitoring_viewer" {

  project = "devops-cert-labs"

  role = "roles/monitoring.viewer"

  member = "serviceAccount:${data.google_compute_default_service_account.default.email}"

}

#######################################################
#
# OUTPUTS
#
#######################################################

output "load_balancer_ip" {

  value = kubernetes_service.node.status[0].load_balancer[0].ingress[0].ip

}

output "application_url" {

  value = "http://${kubernetes_service.node.status[0].load_balancer[0].ingress[0].ip}:8080"

}

output "metrics_url" {

  value = "http://${kubernetes_service.node.status[0].load_balancer[0].ingress[0].ip}:8080/metrics"

}

output "metrics_explorer_metric" {

  value = "prometheus.googleapis.com/http_request_duration_ms"

}