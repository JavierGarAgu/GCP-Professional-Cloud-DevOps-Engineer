terraform {

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

####################################################
# PROVIDER
####################################################

provider "google" {

  project = "devops-cert-labs"

  region = "europe-west1"

}

####################################################
# ENABLE REQUIRED APIS
####################################################

resource "google_project_service" "services" {

  for_each = toset([

    "container.googleapis.com",
    "monitoring.googleapis.com",
    "logging.googleapis.com"

  ])

  service = each.key

  disable_on_destroy = false

}

####################################################
# GKE CLUSTER
####################################################

resource "google_container_cluster" "cluster" {

  name = "otel-metrics-lab"

  location = "europe-west1-b"

  deletion_protection = false

  remove_default_node_pool = true

  initial_node_count = 1

  depends_on = [

    google_project_service.services

  ]

}

####################################################
# NODE POOL
####################################################

resource "google_container_node_pool" "nodes" {

  name = "node-pool"

  cluster = google_container_cluster.cluster.name

  location = google_container_cluster.cluster.location

  node_count = 1

  node_config {

    machine_type = "e2-small"

    disk_type = "pd-standard"

    disk_size_gb = 20

    preemptible = true

    service_account = google_service_account.gke_nodes.email

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

  depends_on = [

    google_container_node_pool.nodes

  ]

  metadata {

    name = "production"

  }

}
####################################################
# APPLICATION SOURCE CODE
####################################################

resource "kubernetes_config_map" "node_app_code" {

  metadata {

    name = "node-app-code"

    namespace = kubernetes_namespace.production.metadata[0].name

  }

  data = {

    "index.js" = <<EOF

const express = require("express");

const { metrics } = require("@opentelemetry/api");

const {

  MeterProvider,
  PeriodicExportingMetricReader

} = require("@opentelemetry/sdk-metrics");

const {

  OTLPMetricExporter

} = require("@opentelemetry/exporter-metrics-otlp-http");

const {

  Resource

} = require("@opentelemetry/resources");

const {

  SemanticResourceAttributes

} = require("@opentelemetry/semantic-conventions");



const exporter = new OTLPMetricExporter({

  url: "http://otel-collector:4318/v1/metrics"

});



const meterProvider = new MeterProvider({

  resource: new Resource({

    [SemanticResourceAttributes.SERVICE_NAME]:

      "node-monitoring-demo"

  })

});



meterProvider.addMetricReader(

  new PeriodicExportingMetricReader({

    exporter: exporter,

    exportIntervalMillis: 5000

  })

);



metrics.setGlobalMeterProvider(

  meterProvider

);



const meter = metrics.getMeter(

  "node-monitoring-demo"

);



const requestCounter = meter.createCounter(

  "application_requests_total",

  {

    description:

      "Total application requests"

  }

);



const latencyHistogram = meter.createHistogram(

  "application_latency_ms",

  {

    description:

      "Application response latency"

  }

);



const app = express();



app.get("/", (req,res)=>{

    const start = Date.now();

    requestCounter.add(1);

    const latency = Date.now()-start;

    latencyHistogram.record(latency);

    res.json({

        application:"Node Demo",

        status:"healthy",

        latency_ms:latency

    });

});



app.get("/health",(req,res)=>{

    res.send("OK");

});



app.listen(

3000,

()=>console.log(

"Application started"

));

EOF

    "package.json" = <<EOF

{

  "name":"otel-metrics-demo",

  "version":"1.0.0",

  "dependencies":{

    "express":"^4.18.2",

    "@opentelemetry/api":"^1.9.0",

    "@opentelemetry/sdk-metrics":"^1.25.1",

    "@opentelemetry/resources":"^1.25.1",

    "@opentelemetry/semantic-conventions":"^1.25.1",

    "@opentelemetry/exporter-metrics-otlp-http":"^0.52.1"

  }

}

EOF

  }

}

####################################################
# NODE APPLICATION
####################################################

resource "kubernetes_deployment" "node" {

  metadata {

    name = "node-app"

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

          name = "node"

          image = "node:20-alpine"

          working_dir = "/app"

          command = [

            "sh",

            "-c"

          ]

          args = [

            "cp /src/* /app/ && npm install && node index.js"

          ]

          port {

            container_port = 3000

          }

          volume_mount {

            name = "application"

            mount_path = "/src"

          }

          volume_mount {

            name = "runtime"

            mount_path = "/app"

          }

        }

        volume {

          name = "application"

          config_map {

            name = kubernetes_config_map.node_app_code.metadata[0].name

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
# NODE SERVICE
####################################################

resource "kubernetes_service" "node" {

  metadata {

    name = "node"

    namespace = kubernetes_namespace.production.metadata[0].name

  }

  spec {

    selector = {

      app = "node"

    }

    port {

      port = 3000

      target_port = 3000

    }

  }

}
####################################################
# OPENTELEMETRY COLLECTOR CONFIGURATION
####################################################

resource "kubernetes_config_map" "otel_config" {

  metadata {

    name = "otel-config"

    namespace = kubernetes_namespace.production.metadata[0].name

  }

  data = {

    "otel.yaml" = <<EOF

receivers:

  otlp:

    protocols:

      grpc:

        endpoint: 0.0.0.0:4317

      http:

        endpoint: 0.0.0.0:4318

processors:

  batch:

exporters:

  googlecloud:

    project: devops-cert-labs

  debug:

    verbosity: detailed

service:

  pipelines:

    metrics:

      receivers: [otlp]

      processors: [batch]

      exporters: [googlecloud, debug]

EOF

  }

}

####################################################
# OPENTELEMETRY COLLECTOR
####################################################

resource "kubernetes_deployment" "otel_collector" {

  metadata {

    name = "otel-collector"

    namespace = kubernetes_namespace.production.metadata[0].name

  }

  spec {

    replicas = 1

    selector {

      match_labels = {

        app = "otel"

      }

    }

    template {

      metadata {

        labels = {

          app = "otel"

        }

      }

      spec {

        container {

          name = "otel"

          image = "otel/opentelemetry-collector-contrib:latest"

          args = [

            "--config=/etc/otel.yaml"

          ]

          port {

            container_port = 4317

          }

          port {

            container_port = 4318

          }

          volume_mount {

            name = "otel-config"

            mount_path = "/etc/otel.yaml"

            sub_path = "otel.yaml"

          }

        }

        volume {

          name = "otel-config"

          config_map {

            name = kubernetes_config_map.otel_config.metadata[0].name

          }

        }

      }

    }

  }

}

####################################################
# OTEL SERVICE
####################################################

resource "kubernetes_service" "otel" {

  metadata {

    name = "otel-collector"

    namespace = kubernetes_namespace.production.metadata[0].name

  }

  spec {

    selector = {

      app = "otel"

    }

    port {

      name = "grpc"

      port = 4317

      target_port = 4317

    }

    port {

      name = "http"

      port = 4318

      target_port = 4318

    }

  }

}

####################################################
# LOAD BALANCER
####################################################

resource "kubernetes_service" "application" {

  metadata {

    name = "application"

    namespace = kubernetes_namespace.production.metadata[0].name

  }

  spec {

    selector = {

      app = "node"

    }

    port {

      port = 80

      target_port = 3000

    }

    type = "LoadBalancer"

  }

}
####################################################
# OUTPUTS
####################################################

output "application_url" {

  description = "Public Load Balancer URL"

  value = kubernetes_service.application.status[0].load_balancer[0].ingress[0].ip

}

output "curl_command" {

  value = "curl http://${kubernetes_service.application.status[0].load_balancer[0].ingress[0].ip}"

}

output "health_check" {

  value = "curl http://${kubernetes_service.application.status[0].load_balancer[0].ingress[0].ip}/health"

}

output "generate_traffic" {

  value = <<EOF
for i in {1..100}; do
  curl http://${kubernetes_service.application.status[0].load_balancer[0].ingress[0].ip} >/dev/null
done
EOF

}

output "verify_pods" {

  value = "kubectl get pods -n production"

}

output "verify_services" {

  value = "kubectl get svc -n production"

}

output "verify_collector_logs" {

  value = "kubectl logs deployment/otel-collector -n production"

}

output "verify_application_logs" {

  value = "kubectl logs deployment/node-app -n production"

}

output "correct_exam_answer" {

  value = "Answer C - Install the OpenTelemetry client libraries in the application, configure Google Cloud Monitoring as the export destination, and observe application metrics in Cloud Monitoring."

}

####################################################
# GKE SERVICE ACCOUNT
####################################################

resource "google_service_account" "gke_nodes" {

  account_id = "gke-otel-nodes"

  display_name = "GKE OpenTelemetry Nodes"

}

####################################################
# IAM
####################################################

resource "google_project_iam_member" "metric_writer" {

  project = "devops-cert-labs"

  role = "roles/monitoring.metricWriter"

  member = "serviceAccount:${google_service_account.gke_nodes.email}"

}
