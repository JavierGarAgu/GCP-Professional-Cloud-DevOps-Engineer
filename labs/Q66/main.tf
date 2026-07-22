terraform {

  required_version = ">= 1.5"

  required_providers {

    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }

    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.35"
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
  region  = "europe-west1"

}

#######################################################
#
# GKE CLUSTER
#
#######################################################

resource "google_container_cluster" "development" {

  name     = "development-cluster"
  location = "europe-west1-b"

  deletion_protection = false

  remove_default_node_pool = true

  initial_node_count = 1

}

#######################################################
#
# NODE POOL
#
#######################################################

resource "google_container_node_pool" "development_nodes" {

  name = "development-pool"

  cluster = google_container_cluster.development.name

  location = google_container_cluster.development.location

  node_count = 2

  node_config {

    machine_type = "e2-small"

    disk_size_gb = 20

    disk_type = "pd-standard"

    preemptible = true

  }

}

#######################################################
#
# AUTHENTICATION
#
#######################################################

data "google_client_config" "current" {}

provider "kubernetes" {

  host = "https://${google_container_cluster.development.endpoint}"

  token = data.google_client_config.current.access_token

  cluster_ca_certificate = base64decode(
    google_container_cluster.development.master_auth[0].cluster_ca_certificate
  )

}

#######################################################
#
# TEAM A
#
#######################################################

resource "kubernetes_namespace" "team_a" {

  metadata {

    name = "team-a"

  }

}

#######################################################
#
# TEAM B
#
#######################################################

resource "kubernetes_namespace" "team_b" {

  metadata {

    name = "team-b"

  }

}

#######################################################
#
# TEAM A - NODE DEPLOYMENT
#
#######################################################

resource "kubernetes_deployment" "team_a_node" {

  metadata {

    name      = "node-app"

    namespace = kubernetes_namespace.team_a.metadata[0].name

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
            "cp /app-src/index.js /app/index.js && cp /app-src/package.json /app/package.json && npm install && node index.js"
          ]

          port {

            container_port = 3000

          }

          volume_mount {

            name = "app-code"

            mount_path = "/app-src"

          }

          volume_mount {

            name = "runtime"

            mount_path = "/app"

          }

        }

        volume {

          name = "app-code"

          config_map {

            name = kubernetes_config_map.team_a_node_code.metadata[0].name

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
# TEAM A - NODE SERVICE
#
#######################################################

resource "kubernetes_service" "team_a_node" {

  metadata {

    name      = "node"

    namespace = kubernetes_namespace.team_a.metadata[0].name

  }

  spec {

    selector = {

      app = "node"

    }

    port {

      port        = 3000

      target_port = 3000

    }

  }

}

#######################################################
#
# TEAM A - REDIS DEPLOYMENT
#
#######################################################

resource "kubernetes_deployment" "team_a_redis" {

  metadata {

    name = "redis"

    namespace = kubernetes_namespace.team_a.metadata[0].name

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
# TEAM A - REDIS SERVICE
#
#######################################################

resource "kubernetes_service" "team_a_redis" {

  metadata {

    name = "redis"

    namespace = kubernetes_namespace.team_a.metadata[0].name

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
# TEAM A - NODE CONFIG MAP
#
#######################################################

resource "kubernetes_config_map" "team_a_node_code" {

  metadata {

    name = "node-app-code"

    namespace = kubernetes_namespace.team_a.metadata[0].name

  }

  data = {

    "index.js" = <<EOF
const express=require('express');
const redis=require('redis');

const app=express();

const client=redis.createClient({
  url:'redis://redis:6379'
});

client.connect();

app.get('/',async(req,res)=>{

  let hits=await client.incr('hits');

  res.send('Team A - Hits: '+hits);

});

app.listen(3000);
EOF

    "package.json" = <<EOF
{
  "name":"node-app",
  "version":"1.0.0",
  "dependencies":{
    "express":"^4.18.0",
    "redis":"^4.6.0"
  }
}
EOF

  }

}
#######################################################
#
# TEAM A - NGINX CONFIG
#
#######################################################

resource "kubernetes_config_map" "team_a_nginx_config" {

  metadata {

    name = "nginx-config"

    namespace = kubernetes_namespace.team_a.metadata[0].name

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
# TEAM A - NGINX DEPLOYMENT
#
#######################################################

resource "kubernetes_deployment" "team_a_nginx" {

  metadata {

    name = "nginx"

    namespace = kubernetes_namespace.team_a.metadata[0].name

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

            name = kubernetes_config_map.team_a_nginx_config.metadata[0].name

          }

        }

      }

    }

  }

}

#######################################################
#
# TEAM A - NGINX SERVICE
#
#######################################################

resource "kubernetes_service" "team_a_nginx" {

  metadata {

    name = "nginx"

    namespace = kubernetes_namespace.team_a.metadata[0].name

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
# TEAM B - REDIS DEPLOYMENT
#
#######################################################

resource "kubernetes_deployment" "team_b_redis" {

  metadata {

    name = "redis"

    namespace = kubernetes_namespace.team_b.metadata[0].name

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
# TEAM B - REDIS SERVICE
#
#######################################################

resource "kubernetes_service" "team_b_redis" {

  metadata {

    name = "redis"

    namespace = kubernetes_namespace.team_b.metadata[0].name

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
# TEAM B - NODE CONFIG MAP
#
#######################################################

resource "kubernetes_config_map" "team_b_node_code" {

  metadata {

    name = "node-app-code"

    namespace = kubernetes_namespace.team_b.metadata[0].name

  }

  data = {

    "index.js" = <<EOF
const express=require('express');
const redis=require('redis');

const app=express();

const client=redis.createClient({
  url:'redis://redis:6379'
});

client.connect();

app.get('/',async(req,res)=>{

  let hits=await client.incr('hits');

  res.send('Team B - Hits: '+hits);

});

app.listen(3000);
EOF

    "package.json" = <<EOF
{
  "name":"node-app",
  "version":"1.0.0",
  "dependencies":{
    "express":"^4.18.0",
    "redis":"^4.6.0"
  }
}
EOF

  }

}
#######################################################
#
# TEAM B - NODE DEPLOYMENT
#
#######################################################

resource "kubernetes_deployment" "team_b_node" {

  metadata {

    name = "node-app"

    namespace = kubernetes_namespace.team_b.metadata[0].name

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
            "cp /app-src/index.js /app/index.js && cp /app-src/package.json /app/package.json && npm install && node index.js"
          ]

          port {

            container_port = 3000

          }

          volume_mount {

            name = "app-code"

            mount_path = "/app-src"

          }

          volume_mount {

            name = "runtime"

            mount_path = "/app"

          }

        }

        volume {

          name = "app-code"

          config_map {

            name = kubernetes_config_map.team_b_node_code.metadata[0].name

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
# TEAM B - NODE SERVICE
#
#######################################################

resource "kubernetes_service" "team_b_node" {

  metadata {

    name = "node"

    namespace = kubernetes_namespace.team_b.metadata[0].name

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
# TEAM B - NGINX CONFIG
#
#######################################################

resource "kubernetes_config_map" "team_b_nginx_config" {

  metadata {

    name = "nginx-config"

    namespace = kubernetes_namespace.team_b.metadata[0].name

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
# TEAM B - NGINX DEPLOYMENT
#
#######################################################

resource "kubernetes_deployment" "team_b_nginx" {

  metadata {

    name = "nginx"

    namespace = kubernetes_namespace.team_b.metadata[0].name

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

            name = kubernetes_config_map.team_b_nginx_config.metadata[0].name

          }

        }

      }

    }

  }

}

#######################################################
#
# TEAM B - NGINX SERVICE
#
#######################################################

resource "kubernetes_service" "team_b_nginx" {

  metadata {

    name = "nginx"

    namespace = kubernetes_namespace.team_b.metadata[0].name

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
# TEAM A ROLE
#
#######################################################

resource "kubernetes_role" "team_a" {

  metadata {

    name = "team-a-role"

    namespace = kubernetes_namespace.team_a.metadata[0].name

  }

  rule {

    api_groups = [

      "",
      "apps"

    ]

    resources = [

      "pods",
      "pods/log",
      "pods/exec",
      "services",
      "configmaps",
      "deployments"

    ]

    verbs = [

      "get",
      "list",
      "watch",
      "create",
      "update",
      "patch",
      "delete"

    ]

  }

}

#######################################################
#
# TEAM A ROLE BINDING
#
#######################################################

resource "kubernetes_role_binding" "team_a" {

  metadata {

    name = "team-a-binding"

    namespace = kubernetes_namespace.team_a.metadata[0].name

  }

  subject {

    kind = "User"

    name = "team-a@example.com"

    api_group = "rbac.authorization.k8s.io"

  }

  role_ref {

    api_group = "rbac.authorization.k8s.io"

    kind = "Role"

    name = kubernetes_role.team_a.metadata[0].name

  }

}
#######################################################
#
# TEAM B ROLE
#
#######################################################

resource "kubernetes_role" "team_b" {

  metadata {

    name = "team-b-role"

    namespace = kubernetes_namespace.team_b.metadata[0].name

  }

  rule {

    api_groups = [

      "",
      "apps"

    ]

    resources = [

      "pods",
      "pods/log",
      "pods/exec",
      "services",
      "configmaps",
      "deployments"

    ]

    verbs = [

      "get",
      "list",
      "watch",
      "create",
      "update",
      "patch",
      "delete"

    ]

  }

}

#######################################################
#
# TEAM B ROLE BINDING
#
#######################################################

resource "kubernetes_role_binding" "team_b" {

  metadata {

    name = "team-b-binding"

    namespace = kubernetes_namespace.team_b.metadata[0].name

  }

  subject {

    kind = "User"

    name = "team-b@example.com"

    api_group = "rbac.authorization.k8s.io"

  }

  role_ref {

    api_group = "rbac.authorization.k8s.io"

    kind = "Role"

    name = kubernetes_role.team_b.metadata[0].name

  }

}
#######################################################
#
# TEAM A NETWORK POLICY
#
#######################################################

resource "kubernetes_network_policy" "team_a" {

  metadata {

    name = "team-a-network-policy"

    namespace = kubernetes_namespace.team_a.metadata[0].name

  }

  spec {

    pod_selector {}

    policy_types = [

      "Ingress",
      "Egress"

    ]

    ingress {

      from {

        pod_selector {}

      }

    }

    egress {

      to {

        pod_selector {}

      }

    }

  }

}
#######################################################
#
# TEAM B NETWORK POLICY
#
#######################################################

resource "kubernetes_network_policy" "team_b" {

  metadata {

    name = "team-b-network-policy"

    namespace = kubernetes_namespace.team_b.metadata[0].name

  }

  spec {

    pod_selector {}

    policy_types = [

      "Ingress",
      "Egress"

    ]

    ingress {

      from {

        pod_selector {}

      }

    }

    egress {

      to {

        pod_selector {}

      }

    }

  }

}
#######################################################
#
# CLUSTER
#
#######################################################

output "cluster_name" {

  description = "GKE Cluster Name"

  value = google_container_cluster.development.name

}

output "cluster_endpoint" {

  description = "GKE API Endpoint"

  value = google_container_cluster.development.endpoint

}

#######################################################
#
# TEAM A
#
#######################################################

output "team_a_namespace" {

  value = kubernetes_namespace.team_a.metadata[0].name

}

output "team_a_load_balancer_ip" {

  value = try(
    kubernetes_service.team_a_nginx.status[0].load_balancer[0].ingress[0].ip,
    "Pending"
  )

}

#######################################################
#
# TEAM B
#
#######################################################

output "team_b_namespace" {

  value = kubernetes_namespace.team_b.metadata[0].name

}

output "team_b_load_balancer_ip" {

  value = try(
    kubernetes_service.team_b_nginx.status[0].load_balancer[0].ingress[0].ip,
    "Pending"
  )

}
