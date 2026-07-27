terraform {

  required_version = ">= 1.5"

  required_providers {

    google = {

      source  = "hashicorp/google"

      version = "~> 5.0"

    }

  }

}


#######################################################
#
# PROVIDER
#
#######################################################

provider "google" {

  project = "devops-cert-labs-v3"

  region = "europe-west1"

}



#######################################################
#
# VARIABLES
#
#######################################################

variable "organization_id" {

  default = "822444595124"

}


variable "user_email" {

  default = "javiermovilx30@gmail.com"

}



#######################################################
#
# ORGANIZATION IAM
#
#######################################################

resource "google_organization_iam_member" "folder_creator" {

  org_id = var.organization_id

  role = "roles/resourcemanager.folderCreator"

  member = "user:${var.user_email}"

}



resource "google_organization_iam_member" "organization_admin" {

  org_id = var.organization_id

  role = "roles/resourcemanager.organizationAdmin"

  member = "user:${var.user_email}"

}



#######################################################
#
# FOLDERS
#
#######################################################

resource "google_folder" "dev" {

  depends_on = [

    google_organization_iam_member.folder_creator

  ]

  display_name = "Dev"

  parent = "organizations/${var.organization_id}"

}



resource "google_folder" "prod" {

  depends_on = [

    google_organization_iam_member.folder_creator

  ]

  display_name = "Prod"

  parent = "organizations/${var.organization_id}"

}



#######################################################
#
# BIGQUERY DATASETS
#
#######################################################

resource "google_bigquery_dataset" "dev_dataset" {

  project = "devops-cert-labs-v3"

  dataset_id = "dev_dataset"

  location = "EU"

}



resource "google_bigquery_dataset" "prod_dataset" {

  project = "devops-cert-labs-v3"

  dataset_id = "prod_dataset"

  location = "EU"

}



#######################################################
#
# LOG SINK DEV
#
#######################################################

resource "google_logging_folder_sink" "dev_logs" {

  depends_on = [

    google_folder.dev

  ]

  name = "dev-folder-log-sink"


  folder = google_folder.dev.folder_id


  destination = "bigquery.googleapis.com/projects/devops-cert-labs-v3/datasets/dev_dataset"


  include_children = true


  filter = <<EOF
logName:"logs/cloudaudit.googleapis.com"
EOF

}



#######################################################
#
# LOG SINK PROD
#
#######################################################

resource "google_logging_folder_sink" "prod_logs" {

  depends_on = [

    google_folder.prod

  ]

  name = "prod-folder-log-sink"


  folder = google_folder.prod.folder_id


  destination = "bigquery.googleapis.com/projects/devops-cert-labs-v3/datasets/prod_dataset"


  include_children = true


  filter = <<EOF
logName:"logs/cloudaudit.googleapis.com"
EOF

}



#######################################################
#
# BIGQUERY IAM
#
#######################################################

resource "google_bigquery_dataset_iam_member" "dev_writer" {


  project = "devops-cert-labs-v3"


  dataset_id = "dev_dataset"


  role = "roles/bigquery.dataEditor"


  member = google_logging_folder_sink.dev_logs.writer_identity


}



resource "google_bigquery_dataset_iam_member" "prod_writer" {


  project = "devops-cert-labs-v3"


  dataset_id = "prod_dataset"


  role = "roles/bigquery.dataEditor"


  member = google_logging_folder_sink.prod_logs.writer_identity


}

#######################################################
#
# LOGGING PERMISSIONS ON FOLDERS
#
#######################################################

resource "google_folder_iam_member" "dev_logging_admin" {

  folder = google_folder.dev.folder_id

  role = "roles/logging.configWriter"

  member = "user:${var.user_email}"

}



resource "google_folder_iam_member" "prod_logging_admin" {

  folder = google_folder.prod.folder_id

  role = "roles/logging.configWriter"

  member = "user:${var.user_email}"

}



#######################################################
#
# OUTPUTS
#
#######################################################

output "dev_folder" {

  value = google_folder.dev.name

}


output "prod_folder" {

  value = google_folder.prod.name

}


output "dev_sink" {

  value = google_logging_folder_sink.dev_logs.name

}


output "prod_sink" {

  value = google_logging_folder_sink.prod_logs.name

}