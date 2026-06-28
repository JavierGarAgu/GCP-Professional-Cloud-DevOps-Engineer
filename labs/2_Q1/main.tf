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



provider "google" {

  project = "devops-cert-labs"
  region  = "europe-west1"

}



#
# GKE
#

resource "google_container_cluster" "cluster" {

  name = "node-observability-lab"

  location = "europe-west1-b"

  deletion_protection = false

  remove_default_node_pool = true

  initial_node_count = 1

}



#
# NODE POOL
#

resource "google_container_node_pool" "nodes" {


  name = "node-pool"


  cluster = google_container_cluster.cluster.name


  location = "europe-west1-b"


  node_count = 1



  node_config {


    machine_type = "e2-small"


    disk_type = "pd-standard"


    disk_size_gb = 20


    preemptible = true

  }


}



#
# KUBERNETES AUTH
#

data "google_client_config" "current" {}



provider "kubernetes" {


  host = "https://${google_container_cluster.cluster.endpoint}"


  token = data.google_client_config.current.access_token


  cluster_ca_certificate = base64decode(

    google_container_cluster.cluster.master_auth[0].cluster_ca_certificate

  )


}



#
# NAMESPACE
#

resource "kubernetes_namespace" "production" {


  metadata {

    name = "production"

  }

}



#
# REDIS DEPLOYMENT
#

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



#
# REDIS SERVICE
#

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

#node deployment
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
const { Resource } = require('@opentelemetry/resources');
const { SemanticResourceAttributes } = require('@opentelemetry/semantic-conventions');

const sdk = new NodeSDK({

  traceExporter: new OTLPTraceExporter({
    url: 'http://otel-collector:4318/v1/traces',
  }),

  instrumentations: [
    getNodeAutoInstrumentations()
  ],

  resource: new Resource({

    [SemanticResourceAttributes.SERVICE_NAME]:
      'node-app'

  }),

});


sdk.start();


const express = require('express');
const redis = require('redis');


const app = express();


const client = redis.createClient({
  url:'redis://redis:6379'
});


client.connect();


app.get('/', async(req,res)=>{

  let hits = await client.incr('hits');

  res.send(
    'Node response hits=' + hits
  );

});


app.listen(3000);

EOF


    "package.json" = <<EOF
{
  "name":"node-app",
  "version":"1.0.0",
  "dependencies":{

    "express":"^4.18.0",
    "redis":"^4.6.0",

    "@opentelemetry/sdk-node":"^0.52.0",
    "@opentelemetry/auto-instrumentations-node":"^0.52.0",
    "@opentelemetry/exporter-trace-otlp-http":"^0.52.0",
    "@opentelemetry/resources":"^1.25.0",
    "@opentelemetry/semantic-conventions":"^1.25.0"

  }
}
EOF

  }

}


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

            "cp /app-src/index.js /app/index.js && cp /app-src/package.json /app/package.json && npm install && node /app/index.js"

          ]



          port {

            container_port = 3000

          }



          volume_mount {


            name = "app-code"


            mount_path = "/app-src"


          }



          volume_mount {


            name = "app-runtime"


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

#
# NODE SERVICE
#

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


#
# NGINX CONFIG
#

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



#
# NGINX DEPLOYMENT
#

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



#
# NGINX SERVICE PUBLICO
#

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

#
# OPENTELEMETRY CONFIG
#
resource "kubernetes_config_map" "otel_config" {

  metadata {
    name      = "otel-config"
    namespace = kubernetes_namespace.production.metadata[0].name
  }

  data = {
    "otel.yaml" = <<EOF
receivers:
  otlp:
    protocols:
      http:
        endpoint: 0.0.0.0:4318
      grpc:
        endpoint: 0.0.0.0:4317

exporters:
  debug:
    verbosity: detailed

service:
  pipelines:
    traces:
      receivers: [otlp]
      exporters: [debug]
EOF
  }
}



#
# OPENTELEMETRY COLLECTOR
#
resource "kubernetes_deployment" "otel_collector" {

  metadata {
    name      = "otel-collector"
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
          name  = "otel"
          image = "otel/opentelemetry-collector:latest"

          args = ["--config=/etc/otel.yaml"]

          port {
            container_port = 4318
          }

          port {
            container_port = 4317
          }

          volume_mount {
            name       = "otel-config"
            mount_path = "/etc/otel.yaml"
            sub_path   = "otel.yaml"
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



#
# OTEL SERVICE (para que Node lo vea dentro del cluster)
#
resource "kubernetes_service" "otel" {

  metadata {
    name      = "otel-collector"
    namespace = kubernetes_namespace.production.metadata[0].name
  }

  spec {

    selector = {
      app = "otel"
    }

    port {
      name        = "otlp-http"
      port        = 4318
      target_port = 4318
    }

    port {
      name        = "otlp-grpc"
      port        = 4317
      target_port = 4317
    }
  }
}
