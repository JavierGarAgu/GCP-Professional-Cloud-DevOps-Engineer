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

            <<EOF
npm init -y &&
npm install express redis &&
node -e "
const express=require('express');
const redis=require('redis');

const app=express();

const client=redis.createClient({
 url:'redis://redis:6379'
});

client.connect();

app.get('/',async(req,res)=>{

 let hits=await client.incr('hits');

 res.send('Node response hits='+hits);

});


app.listen(3000);
"
EOF
          ]



          port {

            container_port = 3000

          }


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