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

  name     = "sli-lab"
  location = "europe-west1-b"

  deletion_protection = false

  remove_default_node_pool = true

  initial_node_count = 1

}

####################################################
# NODE POOL
####################################################

resource "google_container_node_pool" "nodes" {

  name     = "default-pool"

  cluster  = google_container_cluster.cluster.name

  location = "europe-west1-b"

  node_count = 1

  node_config {

    machine_type = "e2-small"

    disk_type = "pd-standard"

    disk_size_gb = 20

    preemptible = true

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
# NODE.JS APPLICATION
####################################################

resource "kubernetes_config_map" "node_app" {

  metadata {

    name      = "node-app"

    namespace = kubernetes_namespace.production.metadata[0].name

  }

  data = {

    "index.js" = <<EOF
const express = require("express");

const app = express();

function sleep(ms){
    return new Promise(resolve => setTimeout(resolve, ms));
}

app.get("/", async (req,res)=>{

    const start = Date.now();

    // 80% de peticiones rápidas
    // 20% de peticiones lentas

    if(Math.random() < 0.8){

        await sleep(40);

    }else{

        await sleep(150);

    }

    const latency = Date.now() - start;

    res.send(
        "Homepage latency = " + latency + " ms\\n"
    );

});

app.listen(3000, ()=>{

    console.log("Server listening on port 3000");

});
EOF

    "package.json" = <<EOF
{
  "name":"homepage-lab",
  "version":"1.0.0",
  "dependencies":{
      "express":"^4.18.2"
  }
}
EOF

  }

}

####################################################
# NODE DEPLOYMENT
####################################################

resource "kubernetes_deployment" "node" {

  metadata {

    name = "homepage"

    namespace = kubernetes_namespace.production.metadata[0].name

  }

  spec {

    replicas = 1

    selector {

      match_labels = {

        app = "homepage"

      }

    }

    template {

      metadata {

        labels = {

          app = "homepage"

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

####################################################
# NODE SERVICE
####################################################

resource "kubernetes_service" "node" {

  metadata {

    name = "homepage"

    namespace = kubernetes_namespace.production.metadata[0].name

  }

  spec {

    selector = {

      app = "homepage"

    }

    port {

      port = 3000

      target_port = 3000

    }

  }

}

####################################################
# NGINX CONFIGURATION
####################################################

resource "kubernetes_config_map" "nginx_config" {

  metadata {

    name      = "nginx-config"

    namespace = kubernetes_namespace.production.metadata[0].name

  }

  data = {

    "default.conf" = <<EOF
server {

    listen 80;

    location / {

        proxy_pass http://homepage:3000;

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

####################################################
# OUTPUT
####################################################

output "load_balancer_ip" {

  value = kubernetes_service.nginx.status[0].load_balancer[0].ingress[0].ip

}