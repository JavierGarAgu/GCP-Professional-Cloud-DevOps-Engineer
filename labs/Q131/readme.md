COMMANDS
```
#INSIDE JENKINS VM
curl \
-H "Metadata-Flavor: Google" \
http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/email

mkdir terraform-demo
cd terraform-demo

terraform {
  required_version = ">= 1.5"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }
  }
}

provider "google" {
  project = "devops-cert-labs-v4"
  region  = "europe-west1"
}

resource "google_storage_bucket" "terraform_demo" {

  name                        = "devops-cert-labs-v4-terraform-auth-demo-20260804"
  location                    = "EU"
  force_destroy               = true
  uniform_bucket_level_access = true

  labels = {
    lab = "terraform-auth"
  }

}

Plan: 1 to add, 0 to change, 0 to destroy.
google_storage_bucket.terraform_demo: Creating...
google_storage_bucket.terraform_demo: Creation complete after 2s [id=devops-cert-labs-v4-terraform-auth-demo-20260804]

Apply complete! Resources: 1 added, 0 changed, 0 destroyed.
```

# Q131 - Terraform Authentication with Attached Service Account

## Overview

This lab demonstrates the Google recommended way to authenticate Terraform running on a Jenkins virtual machine.

Instead of downloading a Service Account key or using `gcloud auth login`, Terraform automatically authenticates by using the Service Account attached to the Compute Engine VM through Application Default Credentials (ADC).

---

## Architecture

```text
                    +-------------------------+
                    |      Compute Engine     |
                    |-------------------------|
                    |                         |
                    | Jenkins                 |
                    | Terraform               |
                    | Google Cloud CLI        |
                    |                         |
                    +-----------+-------------+
                                |
                                | Attached Service Account
                                |
                    +-----------v-------------+
                    |  Metadata Server (ADC)  |
                    +-----------+-------------+
                                |
                                |
                    +-----------v-------------+
                    |      Google Cloud       |
                    |                         |
                    | Cloud Storage           |
                    | IAM                     |
                    | Compute Engine          |
                    +-------------------------+
```

---

## Project Structure

```text
Q131/
│
├── terraform/
│   └── main.tf
│
└── README.md
```

---

## Infrastructure Created

The Terraform configuration creates:

- Service Account
- IAM permissions
- Compute Engine VM
- Firewall rule for SSH and Jenkins
- Startup script
- Jenkins
- Terraform
- Google Cloud CLI

The VM is configured with an attached Service Account that has the required IAM permissions.

---

## Authentication Flow

```text
Terraform
     │
     │
     ▼
Application Default Credentials
     │
     ▼
Metadata Server
     │
     ▼
Attached Service Account
     │
     ▼
Google Cloud APIs
```

No credentials are stored on the VM.

No Service Account JSON key is required.

No manual authentication is required.

---

## Verification

After connecting to the VM, verify the attached Service Account:

```bash
curl \
-H "Metadata-Flavor: Google" \
http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/email
```

Terraform can now create Google Cloud resources without running:

```bash
gcloud auth login
```

or

```bash
gcloud auth application-default login
```

and without setting:

```bash
GOOGLE_APPLICATION_CREDENTIALS
```

---

## Terraform Deployment

Initialize Terraform:

```bash
terraform init
```

Review the execution plan:

```bash
terraform plan
```

Deploy the infrastructure:

```bash
terraform apply
```

---

## Why Option A Is Correct

The Compute Engine VM has an attached Service Account with the required IAM permissions.

Terraform automatically retrieves temporary credentials from the Compute Engine Metadata Server by using Application Default Credentials (ADC).

This is the Google recommended authentication method because it eliminates the need to manage or distribute Service Account private keys.

Incorrect alternatives include:

- Using downloaded Service Account JSON keys.
- Storing credentials in environment variables.
- Running `gcloud auth application-default login` on the VM.

---

## Key Learning Points

- Use an attached Service Account for Compute Engine workloads.
- Terraform automatically uses Application Default Credentials.
- No Service Account key files are required.
- Follow the principle of least privilege when assigning IAM roles.
- This is the recommended authentication method for Terraform on Google Cloud.
```