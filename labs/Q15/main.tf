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
# GOOGLE PROVIDER
####################################################

provider "google" {

  project = "devops-cert-labs"
  region  = "europe-west1"

}

####################################################
# GKE CLUSTER
####################################################

resource "google_container_cluster" "cluster" {

  name     = "database-failover-lab"

  location = "europe-west1-b"

  deletion_protection = false

  remove_default_node_pool = true

  initial_node_count = 1

}

####################################################
# NODE POOL
####################################################

resource "google_container_node_pool" "default_pool" {

  name     = "default-pool"

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
# GOOGLE CLIENT
####################################################

data "google_client_config" "current" {}

####################################################
# KUBERNETES PROVIDER
####################################################

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

resource "kubernetes_namespace" "chat" {

  metadata {

    name = "chat"

  }

}
####################################################
# CHAT APPLICATION
####################################################

resource "kubernetes_config_map" "chat_app" {

  metadata {

    name      = "chat-app"

    namespace = kubernetes_namespace.chat.metadata[0].name

  }

  data = {

    "index.js" = <<EOF
const express = require("express");

const app = express();

let databaseAvailable = true;

let failoverRunning = false;

function sleep(ms){

    return new Promise(resolve => setTimeout(resolve, ms));

}

app.get("/", (req,res)=>{

    if(!databaseAvailable){

        return res.status(503).send(
            "Database unavailable. Failover in progress.\\n"
        );

    }

    res.send(
        "Chat service running. Database healthy.\\n"
    );

});

app.get("/status",(req,res)=>{

    res.json({

        databaseAvailable,

        failoverRunning

    });

});

app.post("/database/fail", async (req,res)=>{

    if(failoverRunning){

        return res.status(409).send(
            "Failover already running.\\n"
        );

    }

    failoverRunning = true;

    res.send(
        "Database failure simulated. Check the logs.\\n"
    );

    console.log("--------------------------------");

    console.log("DATABASE FAILURE");

    console.log("--------------------------------");

    console.log("Waiting 5 seconds...");

    console.log("Simulating MTTD = 5 minutes");

    await sleep(5000);

    console.log("--------------------------------");

    console.log("Failure detected");

    console.log("Starting failover");

    console.log("--------------------------------");

    databaseAvailable = false;

    console.log("Database unavailable");

    console.log("Waiting 20 seconds...");

    console.log("Simulating MTTR = 20 minutes");

    await sleep(20000);

    databaseAvailable = true;

    failoverRunning = false;

    console.log("--------------------------------");

    console.log("Failover completed");

    console.log("Database healthy");

    console.log("--------------------------------");

});

const PORT = 3000;

app.listen(PORT, ()=>{

    console.log("");

    console.log("========================================");

    console.log(" Chat Application Started");

    console.log(" Port: " + PORT);

    console.log("");

    console.log("Endpoints:");

    console.log("GET  /");

    console.log("GET  /status");

    console.log("POST /database/fail");

    console.log("");

    console.log("========================================");

});
EOF

    "package.json" = <<EOF
{
  "name": "database-failover-lab",
  "version": "1.0.0",
  "description": "Database Failover Risk Lab",
  "main": "index.js",
  "dependencies": {
    "express": "^4.18.2"
  }
}
EOF

  }

}
####################################################
# CHAT APPLICATION DEPLOYMENT
####################################################

resource "kubernetes_deployment" "chat" {

  metadata {

    name = "chat-api"

    namespace = kubernetes_namespace.chat.metadata[0].name

    labels = {

      app = "chat-api"

    }

  }

  spec {

    replicas = 1

    selector {

      match_labels = {

        app = "chat-api"

      }

    }

    template {

      metadata {

        labels = {

          app = "chat-api"

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

            "cp /src/index.js /app/index.js && cp /src/package.json /app/package.json && npm install && node index.js"

          ]

          port {

            container_port = 3000

          }

          volume_mount {

            name = "source"

            mount_path = "/src"

          }

          volume_mount {

            name = "runtime"

            mount_path = "/app"

          }

        }

        volume {

          name = "source"

          config_map {

            name = kubernetes_config_map.chat_app.metadata[0].name

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
# INTERNAL SERVICE
####################################################

resource "kubernetes_service" "chat" {

  metadata {

    name = "chat-api"

    namespace = kubernetes_namespace.chat.metadata[0].name

  }

  spec {

    selector = {

      app = "chat-api"

    }

    port {

      port = 3000

      target_port = 3000

    }

    type = "ClusterIP"

  }

}
####################################################
# NGINX CONFIGURATION
####################################################

resource "kubernetes_config_map" "nginx_config" {

  metadata {

    name      = "nginx-config"

    namespace = kubernetes_namespace.chat.metadata[0].name

  }

  data = {

    "default.conf" = <<EOF
server {

    listen 80;

    location / {

        proxy_pass http://chat-api:3000;

        proxy_http_version 1.1;

        proxy_set_header Host \$host;

        proxy_set_header X-Real-IP \$remote_addr;

        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;

    }

}
EOF

  }

}

####################################################
# NGINX DEPLOYMENT
####################################################

resource "kubernetes_deployment" "nginx" {

  metadata {

    name = "nginx"

    namespace = kubernetes_namespace.chat.metadata[0].name

    labels = {

      app = "nginx"

    }

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

            name = "config"

            mount_path = "/etc/nginx/conf.d/default.conf"

            sub_path = "default.conf"

          }

        }

        volume {

          name = "config"

          config_map {

            name = kubernetes_config_map.nginx_config.metadata[0].name

          }

        }

      }

    }

  }

}

####################################################
# PUBLIC LOAD BALANCER
####################################################

resource "kubernetes_service" "nginx" {

  metadata {

    name = "nginx"

    namespace = kubernetes_namespace.chat.metadata[0].name

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

####################################################
# OUTPUT
####################################################

output "load_balancer_ip" {

  description = "Public IP address of the chat application"

  value = kubernetes_service.nginx.status[0].load_balancer[0].ingress[0].ip

}