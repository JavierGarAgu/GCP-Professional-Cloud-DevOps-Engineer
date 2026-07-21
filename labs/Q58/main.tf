terraform {

  required_version = ">= 1.5"

  required_providers {

    google = {
      source  = "hashicorp/google"
      version = "~> 6.0"
    }

    null = {
      source  = "hashicorp/null"
      version = "~> 3.2"
    }

  }

}

#######################################################
#
# PROVIDER
#
#######################################################

provider "google" {

  project = "devops-cert-labs-v2"

  region = "europe-west1"

}

#######################################################
#
# ENABLE REQUIRED APIs
#
#######################################################

locals {
  kms_location = "global"

  key_ring_name = "application-keyring-q58-21"

  crypto_key_name = "application-encryption-key"

  apis = [

    "cloudkms.googleapis.com",
    "iam.googleapis.com"

  ]

}

resource "google_project_service" "services" {

  for_each = toset(local.apis)

  service = each.key

  disable_on_destroy = false

}

#######################################################
#
# APPLICATION SERVICE ACCOUNT
#
#######################################################

resource "google_service_account" "application" {

  depends_on = [

    google_project_service.services

  ]

  account_id = "application-sa"

  display_name = "Application Service Account"

}

#######################################################
#
# KMS KEY RING
#
#######################################################

resource "google_kms_key_ring" "application" {

  depends_on = [
    google_project_service.services
  ]

  name     = local.key_ring_name
  location = local.kms_location

}
#######################################################
#
# KMS CRYPTO KEY
#
#######################################################

resource "google_kms_crypto_key" "application_key" {

  name            = local.crypto_key_name
  key_ring        = google_kms_key_ring.application.id
  purpose         = "ENCRYPT_DECRYPT"
  rotation_period = "2592000s"

}

#######################################################
#
# IAM
#
#######################################################

resource "google_kms_crypto_key_iam_member" "application_access" {

  crypto_key_id = google_kms_crypto_key.application_key.id

  role = "roles/cloudkms.cryptoKeyEncrypterDecrypter"

  member = "serviceAccount:${google_service_account.application.email}"

}

#######################################################
#
# KMS DEMO
#
#######################################################

resource "null_resource" "kms_demo" {

  depends_on = [

    google_kms_crypto_key.application_key,
    google_kms_crypto_key_iam_member.application_access

  ]

  provisioner "local-exec" {

    interpreter = ["PowerShell", "-Command"]

    command = <<-EOT

      Write-Host ""
      Write-Host "========================================="
      Write-Host " Google Cloud KMS Demonstration"
      Write-Host "========================================="
      Write-Host ""

      "MySuperSecretPassword123!" | Out-File `
        -FilePath secret.txt `
        -Encoding ascii

      Write-Host "Encrypting secret with Cloud KMS..."

      gcloud kms encrypt `
        --location=${local.kms_location} `
        --keyring=${local.key_ring_name} `
        --key=${local.crypto_key_name} `
        --plaintext-file=secret.txt `
        --ciphertext-file=secret.enc

      Write-Host ""
      Write-Host "Plaintext file removed."

      Remove-Item secret.txt -Force

      Write-Host ""
      Write-Host "Decrypting secret..."

      gcloud kms decrypt `
        --location=${local.kms_location} `
        --keyring=${local.key_ring_name} `
        --key=${local.crypto_key_name} `
        --ciphertext-file=secret.enc `
        --plaintext-file=secret.dec

      Write-Host ""
      Write-Host "Recovered secret:"
      Get-Content secret.dec

      Write-Host ""
      Write-Host "-----------------------------------------"
      Write-Host "Key Information"
      Write-Host "-----------------------------------------"

      gcloud kms keys describe ${local.crypto_key_name} `
        --location=${local.kms_location} `
        --keyring=${local.key_ring_name}

      Write-Host ""
      Write-Host "-----------------------------------------"
      Write-Host "Key Versions"
      Write-Host "-----------------------------------------"

      gcloud kms keys versions list `
        --location=${local.kms_location} `
        --keyring=${local.key_ring_name} `
        --key=${local.crypto_key_name}

      Write-Host ""
      Write-Host "Cloud KMS demo completed."

    EOT

  }

}

#######################################################
#
# OUTPUTS
#
#######################################################

output "key_ring" {

  description = "Cloud KMS Key Ring"

  value = google_kms_key_ring.application.id

}

output "kms_key" {

  description = "Cloud KMS Crypto Key"

  value = google_kms_crypto_key.application_key.id

}

output "service_account" {

  description = "Application Service Account"

  value = google_service_account.application.email

}