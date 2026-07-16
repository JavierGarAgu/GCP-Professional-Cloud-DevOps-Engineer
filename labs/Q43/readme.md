# Binary Authorization with Google Kubernetes Engine

## Overview

This lab demonstrates how to protect a Google Kubernetes Engine (GKE) cluster by allowing deployments only from a trusted container image repository.

The goal is to reproduce the following Professional Cloud DevOps Engineer exam scenario:

> Your application services run in Google Kubernetes Engine (GKE). You want to make sure that only images from your centrally managed image registry can be deployed to the cluster while minimizing development time.

The correct solution is to use **Binary Authorization** with a **whitelist name pattern**.

---

## Exam Question

**Question**

Your application services run in Google Kubernetes Engine (GKE). You want to make sure that only images from your centrally managed Google Container Registry (GCR) image registry can be deployed to the cluster while minimizing development time.

**Correct Answer**

**B. Use a Binary Authorization policy that includes the whitelist name pattern.**

### Why?

Binary Authorization validates container images before Kubernetes creates Pods.

Instead of modifying every deployment pipeline or manually checking image names, the security policy is enforced directly by GKE.

Only images that match the trusted repository pattern are allowed to run.

---

# Architecture

```
                GitHub
                   │
                   ▼
             Cloud Build Trigger
                   │
        ┌──────────┴──────────┐
        │                     │
        ▼                     ▼
 Build Docker Image     Push Image
        │                     │
        └──────────┬──────────┘
                   ▼
          Artifact Registry
          trusted-images
                   │
                   ▼
          Google Kubernetes Engine
                   │
                   ▼
        Binary Authorization Policy
                   │
      ┌────────────┴────────────┐
      │                         │
      ▼                         ▼
Trusted repository        External registry
      │                         │
   Allowed                  Denied
```

---

# Project Structure

```
.
├── main.tf
├── cloudbuild.yaml
├── Dockerfile
└── k8s
    └── deployment.yaml
```

---

# main.tf Explanation

The Terraform configuration creates the complete infrastructure required for the lab.

## APIs

Terraform enables all required Google Cloud APIs, including:

- Compute Engine API
- Kubernetes Engine API
- Artifact Registry API
- Binary Authorization API

This guarantees every required service is available before creating resources.

---

## Artifact Registry

Terraform creates a Docker Artifact Registry repository named:

```
trusted-images
```

This repository acts as the organization's trusted container registry.

Only images stored inside this repository will be allowed by Binary Authorization.

---

## Service Accounts

The project creates two service accounts.

### GKE Node Service Account

Used by Kubernetes nodes to pull container images.

It receives the following IAM permission:

- Artifact Registry Reader

### Cloud Build Service Account

Used by Cloud Build during the CI/CD pipeline.

It receives permissions such as:

- Artifact Registry Writer
- Container Admin
- Logging Writer

These permissions allow Cloud Build to build, push and deploy container images.

---

## Google Kubernetes Engine

Terraform deploys a regional GKE cluster with:

- Workload Identity enabled
- VPC Native networking
- Dedicated node pool
- Binary Authorization enabled

The important configuration is:

```terraform
binary_authorization {

  evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"

}
```

This tells GKE to enforce the project Binary Authorization policy before creating Pods.

---

## Binary Authorization Policy

Terraform executes a small local command that imports the Binary Authorization policy.

The policy:

- Enables Binary Authorization.
- Blocks every container image by default.
- Allows only images inside the trusted Artifact Registry repository.

This creates a centralized security policy without modifying application code.

---

## Cloud Build Trigger

Terraform also creates a GitHub trigger.

Every push to the **main** branch automatically starts the CI/CD pipeline.

---

# cloudbuild.yaml Explanation

The Cloud Build pipeline automates the deployment process.

## Step 1

Build the Docker image.

```
docker build
```

---

## Step 2

Push the image into the trusted Artifact Registry repository.

```
docker push
```

---

## Step 3

Obtain credentials for the GKE cluster.

```
gcloud container clusters get-credentials
```

---

## Step 4

Replace the placeholder image inside the Kubernetes manifest.

The deployment always uses the latest image built by Cloud Build.

---

## Step 5

Deploy the application.

```
kubectl apply
```

The deployment succeeds because the image belongs to the trusted repository.

---

## Step 6

Verify that the application is running.

Cloud Build checks the Kubernetes Pods.

---

## Step 7

Attempt to deploy an image from Docker Hub.

Example:

```
nginx:latest
```

This image is **not** part of the trusted repository.

---

## Step 8

Cloud Build checks the deployment events.

Binary Authorization rejects the Pod with an error similar to:

```
Image nginx:latest denied by Binary Authorization default admission rule.
Denied by always_deny admission rule.
```

This confirms that the security policy is working correctly.

---

# Dockerfile

The Dockerfile creates a very small Nginx container.

During the build process, Cloud Build uploads the image into the trusted Artifact Registry repository.

This image is accepted by Binary Authorization because it matches the whitelist pattern.

---

# Validation

After a successful deployment:

```
kubectl get pods
```

The application Pod should be running.

When deploying an external image:

```
kubectl create deployment unauthorized-test --image=nginx:latest
```

Binary Authorization blocks the Pod creation.

---

# What I Learned

During this lab I learned how to:

- Deploy a GKE cluster with Binary Authorization enabled.
- Create a centralized trusted container registry.
- Configure a Binary Authorization whitelist policy.
- Build and deploy container images using Cloud Build.
- Verify that trusted images are accepted.
- Verify that untrusted images are automatically rejected before execution.

---

# Technologies Used

- Terraform
- Google Kubernetes Engine (GKE)
- Binary Authorization
- Artifact Registry
- Cloud Build
- Docker
- GitHub
- Kubernetes
```