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

  region = "europe-west1"

}



####################################################
# GKE CLUSTER
####################################################

resource "google_container_cluster" "cluster" {

  name = "container-monitoring-lab"

  location = "europe-west1-b"


  deletion_protection = false


  remove_default_node_pool = true


  initial_node_count = 1

}



####################################################
# BIGGER NODE POOL
####################################################

resource "google_container_node_pool" "nodes" {


  name = "monitoring-node-pool"


  cluster = google_container_cluster.cluster.name


  location = google_container_cluster.cluster.location



  node_count = 1



  node_config {


    machine_type = "e2-standard-4"


    disk_type = "pd-standard"


    disk_size_gb = 30



    oauth_scopes = [

      "https://www.googleapis.com/auth/cloud-platform"

    ]

  }

}



####################################################
# KUBERNETES PROVIDER
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

resource "kubernetes_namespace" "monitoring" {


  metadata {


    name = "monitoring-lab"

  }

}



####################################################
# CPU CONTAINER
####################################################

resource "kubernetes_deployment" "cpu_container" {


  metadata {


    name = "cpu-container"


    namespace = kubernetes_namespace.monitoring.metadata[0].name


    labels = {

      app = "cpu-container"

    }

  }



  spec {


    replicas = 1



    selector {


      match_labels = {

        app = "cpu-container"

      }

    }



    template {


      metadata {


        labels = {

          app = "cpu-container"

        }

      }



      spec {


        container {


          name = "cpu"


          image = "node:20-alpine"



          command = [

            "node"

          ]



          args = [

            "-e",

            "setInterval(()=>{let x=0;for(let i=0;i<10000000;i++){x+=Math.sqrt(i)}},100)"

          ]



          resources {


            requests = {

              cpu = "250m"

              memory = "128Mi"

            }



            limits = {

              cpu = "1000m"

              memory = "256Mi"

            }


          }


        }


      }


    }


  }


}



####################################################
# MEMORY CONTAINER
####################################################

resource "kubernetes_deployment" "memory_container" {


  metadata {


    name = "memory-container"


    namespace = kubernetes_namespace.monitoring.metadata[0].name


    labels = {

      app = "memory-container"

    }

  }



  spec {


    replicas = 1



    selector {


      match_labels = {

        app = "memory-container"

      }

    }



    template {


      metadata {


        labels = {

          app = "memory-container"

        }

      }



      spec {


        container {


          name = "memory"


          image = "node:20-alpine"



          command = [

            "node"

          ]



          args = [

            "-e",

            "let data=[];setInterval(()=>{data.push(Buffer.alloc(1024*1024))},500)"

          ]



          resources {


            requests = {

              cpu = "100m"

              memory = "256Mi"

            }



            limits = {

              cpu = "500m"

              memory = "1Gi"

            }


          }


        }


      }


    }


  }


}



####################################################
# OUTPUTS
####################################################

output "cluster_name" {

  value = google_container_cluster.cluster.name

}



output "namespace" {

  value = kubernetes_namespace.monitoring.metadata[0].name

}