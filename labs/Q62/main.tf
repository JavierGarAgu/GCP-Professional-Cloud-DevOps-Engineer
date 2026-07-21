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

  project = "devops-cert-labs-v2"

  region = "europe-west1"

}



resource "google_container_cluster" "cluster" {

  name = "node-observability-lab"

  location = "europe-west1-b"

  deletion_protection = false

  remove_default_node_pool = true

  initial_node_count = 1

}



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



data "google_client_config" "current" {}



provider "kubernetes" {

  host = "https://${google_container_cluster.cluster.endpoint}"

  token = data.google_client_config.current.access_token

  cluster_ca_certificate = base64decode(
    google_container_cluster.cluster.master_auth[0].cluster_ca_certificate
  )

}



resource "kubernetes_namespace" "production" {

  metadata {

    name = "production"

  }

}

#
# REDIS
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



#
# NODE APPLICATION CODE
#

resource "kubernetes_config_map" "node_app_code" {

  metadata {

    name = "node-app-code"

    namespace = kubernetes_namespace.production.metadata[0].name

  }


  data = {

    "index.js" = <<EOF

const express = require('express');
const redis = require('redis');

const app = express();


const client = redis.createClient({
  url: 'redis://redis:6379'
});


client.connect();



app.get('/', async(req,res)=>{


  let hits = await client.incr('hits');


  console.log(
    "Request received successfully. Hits=" + hits
  );


  res.send(
    'Node response hits=' + hits
  );


});



app.listen(3000,()=>{

 console.log("Node application started on port 3000");

});

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



#
# NODE DEPLOYMENT
#

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
# NGINX CONFIGURATION
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
# PUBLIC SERVICE
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




#################################################
#
# ENABLE REQUIRED APIS
#
#################################################


resource "google_project_service" "logging" {

  project = "devops-cert-labs-v2"

  service = "logging.googleapis.com"

  disable_on_destroy = false

}



resource "google_project_service" "storage" {

  project = "devops-cert-labs-v2"

  service = "storage.googleapis.com"

  disable_on_destroy = false

}




#################################################
#
# CLOUD STORAGE ARCHIVE BUCKET
#
#################################################


resource "google_storage_bucket" "log_archive" {


  name = "application-logs-archive-devops-cert"


  location = "EU"


  storage_class = "ARCHIVE"



  uniform_bucket_level_access = true



  retention_policy {


    retention_period = 220752000


  }



  depends_on = [

    google_project_service.storage

  ]


}





#################################################
#
# LOGGING SINK
#
#################################################


resource "google_logging_project_sink" "application_logs_sink" {


  name = "application-log-archive-sink"



  destination = "storage.googleapis.com/${google_storage_bucket.log_archive.name}"



  filter = <<EOF

resource.type="k8s_container"

resource.labels.namespace_name="production"

EOF



  unique_writer_identity = true



  depends_on = [

    google_project_service.logging

  ]

}




#################################################
#
# GIVE SINK WRITE PERMISSION
#
#################################################


resource "google_storage_bucket_iam_member" "sink_writer" {


  bucket = google_storage_bucket.log_archive.name



  role = "roles/storage.objectCreator"



  member = google_logging_project_sink.application_logs_sink.writer_identity


}





#################################################
#
# OUTPUTS
#
#################################################


output "application_external_ip" {

  description = "External IP"

  value = kubernetes_service.nginx.status[0].load_balancer[0].ingress[0].ip

}



output "gke_cluster_name" {

  value = google_container_cluster.cluster.name

}



output "gke_endpoint" {

  value = google_container_cluster.cluster.endpoint

}



output "log_archive_bucket" {

  value = google_storage_bucket.log_archive.name

}



output "log_sink_name" {

  value = google_logging_project_sink.application_logs_sink.name

}



output "log_sink_writer_identity" {

  value = google_logging_project_sink.application_logs_sink.writer_identity

}
