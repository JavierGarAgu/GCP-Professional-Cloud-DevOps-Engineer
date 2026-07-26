COMMANDS
```
gcloud container clusters get-credentials terraform-cluster --zone=europe-west1-b --project=devops-cert-labs-v3
gcloud iam service-accounts list
gcloud container clusters describe terraform-cluster --zone=europe-west1-b --format="value(workloadIdentityConfig.workloadPool)"
kubectl get sa terraform-runner -o yaml
gcloud iam service-accounts get-iam-policy terraform-deployer@devops-cert-labs-v3.iam.gserviceaccount.com
```

# Q92 - Terraform CI/CD Authentication with GKE Workload Identity

## Exam Question

You are creating a CI/CD pipeline to perform Terraform deployments of Google Cloud resources. Your CI/CD tooling is running in Google Kubernetes Engine (GKE) and uses an ephemeral Pod for each pipeline run.

You must ensure that the pipelines that run in the Pods have the appropriate Identity and Access Management (IAM) permissions to perform the Terraform deployments. You want to follow Google-recommended practices for identity management.

**What should you do? (Choose two.)**

- A. Create a new Kubernetes service account, and assign the service account to the Pods. Use Workload Identity to authenticate as the Google service account.
- B. Create a new JSON service account key for the Google service account, store the key as a Kubernetes secret, inject the key into the Pods, and set the GOOGLE_APPLICATION_CREDENTIALS environment variable.
- C. Create a new Google service account, and assign the appropriate IAM permissions.
- D. Create a new JSON service account key for the Google service account, store the key in the secret management store for the CI/CD tool, and configure Terraform to use this key for authentication.
- E. Assign the appropriate IAM permissions to the Google service account associated with the Compute Engine VM instances that run the Pods.

**Correct answers: A and C**

---

# Architecture

```
                          Google Cloud

                    +----------------------+
                    |      IAM Roles       |
                    |----------------------|
                    | Container Admin      |
                    | Compute Admin        |
                    | ServiceAccountUser   |
                    +----------+-----------+
                               |
                               |
                               v
                 +------------------------------+
                 | Google Service Account (GSA) |
                 | terraform-deployer           |
                 +--------------+---------------+
                                ^
                                |
             roles/iam.workloadIdentityUser
                                |
                                |
+------------------------------------------------------------+
|                     GKE Cluster                            |
|                                                            |
|  Workload Identity Enabled                                 |
|                                                            |
|  +-----------------------------------------------+         |
|  | Kubernetes Service Account (KSA)              |         |
|  | terraform-runner                              |         |
|  +----------------------+------------------------+         |
|                         |                                  |
|                         |                                  |
|                  Ephemeral CI/CD Pod                       |
|                  Terraform Apply                           |
|                  Terraform Destroy                         |
|                                                            |
+------------------------------------------------------------+
```

---

# Authentication Flow

```
Terraform Pod
      |
      v
Kubernetes Service Account
      |
      | Workload Identity
      v
Google Service Account
      |
      v
IAM Permissions
      |
      v
Google Cloud Resources
```

No service account keys are created or stored.

---

# Strategy

Google recommends using Workload Identity instead of JSON service account keys.

The Pod authenticates by using its Kubernetes Service Account.

The Kubernetes Service Account is mapped to a Google Service Account.

The Google Service Account receives only the IAM permissions required for Terraform deployments.

This approach provides:

- No long-lived credentials
- Least privilege access
- Automatic credential rotation
- Better security
- Easier management

---

# main.tf Explanation

## Terraform Providers

The configuration uses the Google and Kubernetes providers.

```terraform
provider "google"
provider "kubernetes"
```

The Kubernetes provider is used to create Kubernetes resources after the GKE cluster is available.

---

## Enable Required APIs

Only the required APIs are enabled.

- Container API
- IAM API

---

## Google Service Account

A dedicated Google Service Account is created.

```text
terraform-deployer
```

This account is used by Terraform instead of the node service account.

---

## IAM Permissions

The Google Service Account receives the permissions required to deploy infrastructure.

Example:

- roles/container.admin
- roles/compute.admin
- roles/iam.serviceAccountUser

This follows the principle of least privilege.

---

## GKE Cluster

The cluster enables Workload Identity.

```terraform
workload_identity_config {
    workload_pool = "PROJECT_ID.svc.id.goog"
}
```

This creates the identity pool used to connect Kubernetes identities with Google Cloud identities.

---

## Kubernetes Service Account

Terraform creates a Kubernetes Service Account.

```text
terraform-runner
```

It contains the annotation:

```text
iam.gke.io/gcp-service-account=terraform-deployer@PROJECT_ID.iam.gserviceaccount.com
```

This annotation links the Kubernetes identity with the Google identity.

---

## Workload Identity Binding

Terraform grants the Kubernetes Service Account permission to impersonate the Google Service Account.

```text
roles/iam.workloadIdentityUser
```

Binding:

```text
serviceAccount:PROJECT_ID.svc.id.goog[default/terraform-runner]
```

Without this binding, authentication would fail.

---

# Verification Commands

List Google Service Accounts

```bash
gcloud iam service-accounts list
```

Verify Workload Identity

```bash
gcloud container clusters describe terraform-cluster \
--zone=europe-west1-b \
--format="value(workloadIdentityConfig.workloadPool)"
```

Verify Kubernetes Service Account

```bash
kubectl get sa terraform-runner -o yaml
```

Verify Workload Identity binding

```bash
gcloud iam service-accounts get-iam-policy terraform-deployer@devops-cert-labs-v3.iam.gserviceaccount.com
```

---

# Why A Is Correct

A Kubernetes Service Account is created for the Pod.

Workload Identity allows the Pod to authenticate as the Google Service Account without using service account keys.

---

# Why C Is Correct

A dedicated Google Service Account is created.

It receives only the IAM roles required for Terraform deployments.

---

# Why B Is Incorrect

It stores a JSON key inside Kubernetes.

Google recommends avoiding service account keys whenever possible.

---

# Why D Is Incorrect

Although the key is stored in a secret manager, it is still a long-lived credential.

Workload Identity is the recommended solution.

---

# Why E Is Incorrect

Granting permissions to the node service account gives every Pod on the node unnecessary permissions.

This violates the principle of least privilege.

---

# Key Takeaways

- Use Workload Identity.
- Create a dedicated Google Service Account.
- Create a dedicated Kubernetes Service Account.
- Bind both identities using `roles/iam.workloadIdentityUser`.
- Never use JSON service account keys when Workload Identity is available.
- Grant only the minimum IAM permissions required.