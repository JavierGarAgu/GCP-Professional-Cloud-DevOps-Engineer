# Google Cloud Professional Cloud DevOps Engineer Lab

# Question 9 - Blue/Green Deployment and Continuous Integration

---

## Introduction

This repository contains a simple hands-on lab created while preparing for the **Google Cloud Professional Cloud DevOps Engineer** certification.

The goal of this lab is not to build a production ready application. Instead, it tries to reproduce one of the concepts that appears in the certification exam using a very small infrastructure that is easy to understand.

The lab combines two important DevOps practices:

* **Blue/Green Deployment**
* **Continuous Integration (CI)**

Both concepts help reduce the **Mean Time To Recovery (MTTR)** after a failed deployment.

---

# Exam Question

> You deploy a new release of an internal application during a weekend maintenance window when there is minimal user traffic. After the window ends, you learn that one of the new features isn't working as expected in the production environment. After an extended outage, you roll back the new release and deploy a fix.
>
> You want to modify your release process to reduce the mean time to recovery so you can avoid extended outages in the future.
>
> **What should you do? (Choose two.)**

### A

Before merging new code, require two different peers to review the code changes.

### B ✅

Adopt the Blue/Green deployment strategy when releasing new code via a CD server.

### C

Integrate a code linting tool to validate coding standards before any code is accepted into the repository.

### D

Require developers to run automated integration tests on their local development environments before release.

### E ✅

Configure a CI server. Add a suite of unit tests to your code and have your CI server run them on every commit and verify any changes.

---

# Why are B and E correct?

The objective of the question is **not** to improve code quality.

The objective is reducing the recovery time when a deployment goes wrong.

Blue/Green deployment allows switching the production traffic almost instantly between two different versions of the application.

Continuous Integration automatically executes tests before a new version is promoted.

Together, these two practices reduce downtime and make deployments much safer.

---

# Lab Architecture

```
                    GitHub Repository
                           │
                           │ Push / Manual Trigger
                           ▼
                    Cloud Build (CI)
                           │
               Run automated tests
                           │
                  Tests successful?
                           │
                    Yes ───────────────► Patch Service
                           │
                           ▼
                     Kubernetes Service
                           │
                 Blue  ◄────────► Green
                           │
                           ▼
                    External Load Balancer
```

---

# Infrastructure

Terraform creates:

* A GKE Cluster
* One Node Pool
* A Kubernetes Namespace
* Blue Deployment
* Green Deployment
* Kubernetes Service
* External Load Balancer
* Cloud Build Trigger
* IAM permissions required by Cloud Build

The infrastructure is intentionally very small because the purpose is understanding the deployment strategy instead of creating a complex environment.

---

# Blue Deployment

The Blue deployment represents the stable production version.

When Terraform finishes, the Kubernetes Service points to the Blue deployment.

Users only access the Blue version.

---

# Green Deployment

The Green deployment already exists inside the cluster.

It is ready to receive traffic but nobody is using it yet.

This is one of the biggest advantages of Blue/Green deployment.

The new version is already running before users start using it.

---

# Continuous Integration

Cloud Build acts as the Continuous Integration server.

When the trigger is executed it performs a very simple pipeline.

The pipeline simulates:

* Running automated tests
* Connecting to the Kubernetes cluster
* Promoting the Green deployment

In a real project many more tests would probably exist.

For this lab the pipeline is intentionally simple.

---

# Pipeline Flow

```
Cloud Build Trigger

↓

Run automated tests

↓

Tests passed

↓

Connect to GKE

↓

Patch Kubernetes Service

↓

Traffic changes from Blue to Green
```

---

# Lab Steps

## 1. Deploy the infrastructure

```bash
terraform init
terraform apply
```

Terraform creates all required Google Cloud resources.

---

## 2. Get the Load Balancer IP

```bash
terraform output
```

Example:

```
34.xxx.xxx.xxx
```

---

## 3. Verify Blue deployment

Execute:

```powershell
curl.exe -s http://<LOAD_BALANCER_IP> | findstr "homepage"
```

Expected output:

```
homepage-blue
```

This confirms the Kubernetes Service is sending traffic to the Blue deployment.

---

## 4. Execute the Cloud Build Trigger

Run the trigger manually from Google Cloud Console.

Cloud Build starts the pipeline.

The pipeline simulates automated testing.

If every step finishes correctly, the Service selector changes from Blue to Green.

---

## 5. Verify Green deployment

Execute again:

```powershell
curl.exe -s http://<LOAD_BALANCER_IP> | findstr "homepage"
```

Now the output should be similar to:

```
homepage-green
```

The application changed version without creating another Load Balancer.

Only the Kubernetes Service selector was modified.

---

# Why is Blue/Green useful?

Without Blue/Green deployment, a failed release normally requires:

* stopping production
* deploying the previous version
* waiting until the application becomes available again

This process may take several minutes.

Sometimes even longer.

With Blue/Green deployment both versions already exist.

Changing production traffic only requires updating the Service selector.

Recovery becomes much faster.

---

# Why is Continuous Integration useful?

CI automatically validates the application before deployment.

Instead of waiting until users discover a bug, the pipeline detects many problems earlier.

Typical CI tasks include:

* Unit tests
* Static analysis
* Linting
* Security scanning
* Build verification

This lab only simulates automated tests because the objective is understanding the deployment workflow.

---

# What happens if tests fail?

If automated tests fail, Cloud Build stops immediately.

The Service selector is never modified.

Users continue accessing the Blue deployment.

This prevents releasing a broken version into production.

---

# Real Production Workflow

A real company would probably have something similar to this:

Developer

↓

Push code

↓

Cloud Build

↓

Run Unit Tests

↓

Run Security Scan

↓

Build Docker Image

↓

Push image to Artifact Registry

↓

Deploy Green version

↓

Health Checks

↓

Switch production traffic

↓

Monitor application

↓

Remove old version later

This lab only reproduces the most important ideas.

---

# Google Cloud Services Used

* Google Kubernetes Engine (GKE)
* Cloud Build
* IAM
* Kubernetes
* Terraform

---

# Concepts Practiced

* Infrastructure as Code
* Continuous Integration
* Kubernetes Deployments
* Kubernetes Services
* Blue/Green Deployment
* Google Cloud IAM
* Cloud Build Triggers
* DevOps Best Practices

---

# What I Learned

After completing this lab I better understand why the correct answers are **B** and **E**.

Blue/Green deployment helps reducing downtime because switching traffic is almost instant.

Continuous Integration prevents many deployment problems before they reach production.

Both practices work together.

CI reduces the number of bad deployments.

Blue/Green reduces the recovery time if something still goes wrong.

---

# Conclusion

This is a very small lab, but it demonstrates an important DevOps idea that is frequently used in real environments.

Instead of focusing on building a complicated application, the objective is understanding **why** Google recommends Blue/Green deployments together with Continuous Integration.

For the certification exam, remembering the goal is very important.

The question is asking how to **reduce Mean Time To Recovery (MTTR)**.

Blue/Green deployment makes rollback almost immediate.

Continuous Integration verifies the application before promoting the new version.

Together, they create a safer deployment process and significantly reduce production outages.

## Verification

```bash
terraform init

terraform apply -auto-approve

terraform output

curl.exe -s http://<LOAD_BALANCER_IP> | findstr "homepage"

gcloud builds triggers list

gcloud builds triggers run bluegreen-ci --branch=main

curl.exe -s http://<LOAD_BALANCER_IP> | findstr "homepage"

terraform destroy -auto-approve
```
