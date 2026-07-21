# Jenkins Deployment on Google Cloud Compute Engine

## Lab Overview

This lab explains the correct architecture choice for deploying Jenkins in Google Cloud Platform (GCP) when Jenkins is used as a CI/CD platform to automate application releases.

The scenario is based on a Google Cloud Professional Cloud DevOps Engineer exam question:

> Your application runs on Google Cloud Platform. You need to implement Jenkins for deploying application releases to GCP. You want to streamline the release process, lower operational toil, and keep user data secure.

The correct answer is:

**Deploy Jenkins on Compute Engine virtual machines.**

The purpose of this lab is not only to deploy Jenkins, but also to understand the architectural reasoning behind choosing Compute Engine instead of other alternatives.

---

# Business Requirements

The company has an application running on Google Cloud and needs an automated release process.

The objectives are:

- Automate application deployments.
- Reduce manual release tasks.
- Reduce operational overhead.
- Keep application data and credentials secure.
- Provide a reliable platform for CI/CD pipelines.

Jenkins is selected because it is a widely used automation server capable of managing:

- Continuous Integration (CI).
- Continuous Delivery (CD).
- Automated testing.
- Application deployments.
- Infrastructure automation.

However, Jenkins requires a stable and persistent environment.

---

# Why Deploy Jenkins on Compute Engine?

The correct solution is:

```

Jenkins → Compute Engine Virtual Machine

```

Compute Engine is the best option because Jenkins behaves like a traditional server application.

Jenkins requires:

- A permanent runtime environment.
- Persistent storage.
- Network availability.
- Operating system access.
- Plugin installation.
- Configuration management.

A Compute Engine virtual machine provides all these requirements.

The architecture looks like this:

```

Developer
|
|
v
Source Code Repository
|
|
v
Jenkins Server
(Compute Engine VM)
|
|
+----------------------+
|                      |
v                      v
Artifact Registry        GKE Cluster
|                      |
|                      |
+-----------> Application Deployment

```

Jenkins acts as the automation engine that builds, tests, and deploys applications into Google Cloud.

---

# Compute Engine Advantages for Jenkins

## Persistent Environment

Jenkins stores important information such as:

- Pipeline configurations.
- Installed plugins.
- Build history.
- Credentials.
- Workspace files.

A Compute Engine VM with Persistent Disk guarantees that this information remains available after restarts.

Example:

```

/var/lib/jenkins

Contains:

* jobs/
* plugins/
* credentials/
* build history
* pipeline definitions

```

---

## Full Operating System Control

Jenkins requires software dependencies such as:

- Java Runtime Environment.
- Docker.
- Google Cloud SDK.
- Additional build tools.

With Compute Engine, administrators can install and configure everything required by the CI/CD environment.

Example:

```

Compute Engine VM

Ubuntu Linux

Installed:

Java
Jenkins
Docker
Google Cloud SDK
Terraform

```

---

## Integration with Google Cloud Services

Jenkins running on Compute Engine can securely communicate with other GCP services.

Examples:

```

Jenkins
|
+--> Artifact Registry
|
+--> Google Kubernetes Engine
|
+--> Cloud Storage
|
+--> Secret Manager
|
+--> Cloud Monitoring

```

This allows complete automated release pipelines.

---

# Security Design

Security is a key requirement of the question.

The Jenkins VM should use a dedicated Google Cloud Service Account.

Example:

```

Jenkins VM
|
|
v
Service Account
|
|
+--> Artifact Registry Writer
|
+--> Kubernetes Developer
|
+--> Secret Manager Access

```

The principle of least privilege should always be applied.

Jenkins should only have the permissions required to perform deployments.

---

# Protecting Sensitive Information

Credentials and secrets should never be stored directly inside Jenkins pipelines.

Bad practice:

```

username = admin
password = mypassword123

```

Recommended approach:

```

Jenkins
|
v
Secret Manager
|
v
Temporary Access

```

Google Cloud services should be accessed using:

- IAM roles.
- Service Accounts.
- Secret Manager.
- Short-lived credentials.

---

# Why Not Local Workstations?

## Option A - Implement Jenkins on local workstations

This is incorrect.

A developer computer is not an appropriate place for an enterprise CI/CD platform.

Problems:

- The computer can be offline.
- No high availability.
- Difficult maintenance.
- Security problems.
- Depends on a single user.

CI/CD systems must run on reliable infrastructure.

---

# Why Not Kubernetes On-Premises?

## Option B - Implement Jenkins on Kubernetes on-premises

This option can work technically, but it increases operational complexity.

The company would need to manage:

- Physical infrastructure.
- Kubernetes clusters.
- Networking.
- Storage.
- Security patches.
- Hardware failures.

The objective of the question is reducing operational toil.

Moving Jenkins to an external on-premises Kubernetes environment creates additional responsibilities.

Since the application already runs on GCP, keeping Jenkins inside Google Cloud is a simpler solution.

---

# Why Not Cloud Functions?

## Option C - Implement Jenkins on Google Cloud Functions

Cloud Functions is not designed to host Jenkins.

Cloud Functions is:

- Serverless.
- Event-driven.
- Stateless.
- Designed for short executions.

Jenkins requires:

- A long-running server.
- Persistent files.
- Installed plugins.
- Continuous availability.

Therefore, Cloud Functions cannot be used for Jenkins hosting.

---

# Terraform Infrastructure Design

A Terraform implementation of this architecture would create the required infrastructure automatically.

The main components are:

```

Terraform
|
+-- Compute Engine VM
|
+-- Persistent Disk
|
+-- Service Account
|
+-- IAM Permissions
|
+-- Firewall Rules

````

Example Terraform resources:

```hcl
google_compute_instance
google_compute_disk
google_service_account
google_project_iam_member
google_compute_firewall
````

Terraform provides:

* Infrastructure as Code.
* Repeatable deployments.
* Version control.
* Reduced manual configuration.

---

# Possible CI/CD Workflow

A complete Jenkins pipeline could look like this:

```
Developer pushes code
          |
          v
Git Repository
          |
          v
Jenkins Pipeline
          |
          +--> Build application
          |
          +--> Run tests
          |
          +--> Build Docker image
          |
          +--> Push image to Artifact Registry
          |
          +--> Deploy to GKE
          |
          v
Production Application
```

This provides an automated and reliable release process.

---

# Exam Strategy

For the Google Cloud Professional Cloud DevOps Engineer exam, remember this rule:

Jenkins is a traditional server application.

When you see:

* Jenkins
* Persistent configuration
* Plugins
* CI/CD automation server

Think:

```
Jenkins → Compute Engine
```

Do not choose:

* Cloud Functions → serverless and stateless.
* Local machines → unreliable.
* External infrastructure → increases operational effort.

---

# Final Answer

The correct answer is:

**D - Implement Jenkins on Compute Engine virtual machines.**

Compute Engine provides the persistent, secure, and configurable environment required by Jenkins while allowing integration with Google Cloud services such as Artifact Registry, GKE, Secret Manager, and Cloud Monitoring.

This solution reduces operational toil, improves security, and provides a reliable foundation for automated application releases.
