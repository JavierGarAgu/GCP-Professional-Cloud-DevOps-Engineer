#######################################################
#
# TERRAFORM
#
#######################################################

terraform {

  required_version = ">= 1.5"

  required_providers {

    google = {

      source = "hashicorp/google"

      version = "~> 5.0"

    }

    kubernetes = {

      source = "hashicorp/kubernetes"

      version = "~> 2.31"

    }

  }

}

#######################################################
#
# GOOGLE PROVIDER
#
#######################################################

provider "google" {

  project = "devops-cert-labs-v3"

  region = "europe-west1"

}

#######################################################
#
# ENABLE REQUIRED APIS
#
#######################################################

locals {

  apis = [

    "compute.googleapis.com",

    "container.googleapis.com",

    "serviceusage.googleapis.com",

    "cloudtrace.googleapis.com",

    "monitoring.googleapis.com",

    "logging.googleapis.com"

  ]

}

resource "google_project_service" "services" {

  for_each = toset(local.apis)

  service = each.key

  disable_on_destroy = false

}

#######################################################
#
# NETWORK
#
#######################################################

resource "google_compute_network" "gke_network" {

  depends_on = [
    google_project_service.services
  ]

  name = "observability-network"

  auto_create_subnetworks = false

}

resource "google_compute_subnetwork" "gke_subnet" {

  name = "observability-subnet"

  region = "europe-west1"

  network = google_compute_network.gke_network.id

  ip_cidr_range = "10.10.0.0/24"

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

  name = "observability-cluster"

  location = "europe-west1-b"

  network = google_compute_network.gke_network.id

  subnetwork = google_compute_subnetwork.gke_subnet.id

  deletion_protection = false

  remove_default_node_pool = true

  initial_node_count = 1

}

#######################################################
#
# NODE POOL
#
#######################################################

resource "google_container_node_pool" "nodes" {

  name = "primary-pool"

  location = "europe-west1-b"

  cluster = google_container_cluster.cluster.name

  node_count = 1

  node_config {

    machine_type = "e2-medium"

    disk_size_gb = 30

    disk_type = "pd-standard"

    oauth_scopes = [

      "https://www.googleapis.com/auth/cloud-platform"

    ]

  }

}

#######################################################
#
# KUBERNETES PROVIDER
#
#######################################################

data "google_client_config" "default" {}

provider "kubernetes" {

  host = "https://${google_container_cluster.cluster.endpoint}"

  token = data.google_client_config.default.access_token

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

  depends_on = [
    google_container_node_pool.nodes
  ]

  metadata {

    name = "production"

  }

}

#######################################################
#
# REDIS DEPLOYMENT
#
#######################################################

resource "kubernetes_deployment" "redis" {

  metadata {

    name = "redis"

    namespace = kubernetes_namespace.production.metadata[0].name

  }

  spec {

    replicas = 1

    selector {

      match_labels = {

        app = "redis"

      }

    }

    template {

      metadata {

        labels = {

          app = "redis"

        }

      }

      spec {

        container {

          name = "redis"

          image = "redis:alpine"

          port {

            container_port = 6379

          }

        }

      }

    }

  }

}

#######################################################
#
# REDIS SERVICE
#
#######################################################

resource "kubernetes_service" "redis" {

  metadata {

    name = "redis"

    namespace = kubernetes_namespace.production.metadata[0].name

  }

  spec {

    selector = {

      app = "redis"

    }

    port {

      port = 6379

      target_port = 6379

    }

  }

}

#######################################################
#
# NODE APPLICATION CODE (OpenTelemetry)
#
#######################################################

resource "kubernetes_config_map" "node_app_code" {

  metadata {

    name      = "node-app-code"

    namespace = kubernetes_namespace.production.metadata[0].name

  }

  data = {

    "index.js" = <<EOF
const { NodeSDK } = require('@opentelemetry/sdk-node');
const { getNodeAutoInstrumentations } = require('@opentelemetry/auto-instrumentations-node');
const { OTLPTraceExporter } = require('@opentelemetry/exporter-trace-otlp-http');

const sdk = new NodeSDK({

  traceExporter: new OTLPTraceExporter({

    url: 'http://otel-collector:4318/v1/traces'

  }),

  instrumentations: [

    getNodeAutoInstrumentations()

  ]

});

sdk.start();

const express = require('express');
const redis = require('redis');

const app = express();

const client = redis.createClient({

  url: 'redis://redis:6379'

});

(async () => {

  await client.connect();

})();

app.get('/', async (req, res) => {

  const hits = await client.incr('hits');

  await new Promise(resolve => setTimeout(resolve, 1200));

  res.send('Node response hits=' + hits);

});

app.listen(3000, () => {

  console.log('Node app listening on port 3000');

});
EOF

    "package.json" = <<EOF
{
  "name": "node-app",
  "version": "1.0.0",
  "dependencies": {
    "express": "^4.18.2",
    "redis": "^4.6.13",
    "@opentelemetry/sdk-node": "^0.57.0",
    "@opentelemetry/auto-instrumentations-node": "^0.57.0",
    "@opentelemetry/exporter-trace-otlp-http": "^0.57.0"
  }
}
EOF

  }

}

#######################################################
#
# NODE DEPLOYMENT
#
#######################################################

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

          name  = "node"
          image = "node:20-alpine"

          working_dir = "/app"

          command = [

            "sh",
            "-c"

          ]

          args = [

            "cp /app-src/index.js /app/index.js && cp /app-src/package.json /app/package.json && npm install && node /app/index.js"

          ]

          port {

            container_port = 3000

          }

          volume_mount {

            name       = "app-code"
            mount_path = "/app-src"

          }

          volume_mount {

            name       = "app-runtime"
            mount_path = "/app"

          }

        }

        volume {

          name = "app-code"

          config_map {

            name = kubernetes_config_map.node_app_code.metadata[0].name

          }

        }

        volume {

          name = "app-runtime"

          empty_dir {}

        }

      }

    }

  }

}

#######################################################
#
# NODE SERVICE
#
#######################################################

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

#######################################################
#
# NGINX CONFIG
#
#######################################################

resource "kubernetes_config_map" "nginx_config" {

  metadata {

    name = "nginx-config"

    namespace = kubernetes_namespace.production.metadata[0].name

  }

  data = {

    default_conf = <<EOF
server {

    listen 80;

    location / {

        proxy_pass http://node:3000;

        proxy_http_version 1.1;

        proxy_set_header Host \$host;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;

    }

}
EOF

  }

}

#######################################################
#
# NGINX DEPLOYMENT
#
#######################################################

resource "kubernetes_deployment" "nginx" {

  metadata {

    name = "nginx"

    namespace = kubernetes_namespace.production.metadata[0].name

  }

  spec {

    replicas = 1

    selector {

      match_labels = {

        app = "nginx"

      }

    }

    template {

      metadata {

        labels = {

          app = "nginx"

        }

      }

      spec {

        container {

          name = "nginx"

          image = "nginx:latest"

          port {

            container_port = 80

          }

          volume_mount {

            name = "nginx-config"

            mount_path = "/etc/nginx/conf.d/default.conf"

            sub_path = "default_conf"

          }

        }

        volume {

          name = "nginx-config"

          config_map {

            name = kubernetes_config_map.nginx_config.metadata[0].name

          }

        }

      }

    }

  }

}

#######################################################
#
# NGINX LOAD BALANCER
#
#######################################################

resource "kubernetes_service" "nginx" {

  metadata {

    name = "nginx"

    namespace = kubernetes_namespace.production.metadata[0].name

  }

  spec {

    selector = {

      app = "nginx"

    }

    port {

      port = 80

      target_port = 80

    }

    type = "LoadBalancer"

  }

}

#######################################################
#
# OPENTELEMETRY CONFIGURATION
#
#######################################################

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

    project: devops-cert-labs-v3

  debug:

    verbosity: detailed

service:

  pipelines:

    traces:

      receivers: [otlp]

      processors: [batch]

      exporters: [googlecloud, debug]

EOF

  }

}

#######################################################
#
# OPENTELEMETRY COLLECTOR
#
#######################################################

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
#######################################################
#
# OPENTELEMETRY SERVICE
#
#######################################################

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

      name = "otlp-grpc"

      port = 4317

      target_port = 4317

    }

    port {

      name = "otlp-http"

      port = 4318

      target_port = 4318

    }

  }

}

#######################################################
#
# OUTPUTS
#
#######################################################

output "cluster_name" {

  value = google_container_cluster.cluster.name

}

output "cluster_endpoint" {

  value = google_container_cluster.cluster.endpoint

}

output "namespace" {

  value = kubernetes_namespace.production.metadata[0].name

}

output "nginx_service_name" {

  value = kubernetes_service.nginx.metadata[0].name

}

output "load_balancer_ip" {

  value = try(

    kubernetes_service.nginx.status[0].load_balancer[0].ingress[0].ip,

    "Pending..."

  )

}

output "application_url" {

  value = try(

    "http://${kubernetes_service.nginx.status[0].load_balancer[0].ingress[0].ip}",

    "Pending..."

  )

}

output "otel_collector_service" {

  value = kubernetes_service.otel.metadata[0].name

}

output "redis_service" {

  value = kubernetes_service.redis.metadata[0].name

}

output "node_service" {

  value = kubernetes_service.node.metadata[0].name

}
