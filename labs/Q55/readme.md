COMMANDS
#BEFORE APPLY

gcloud services enable containerscanning.googleapis.com

#AFTER APPLY

gcloud artifacts docker images list europe-west1-docker.pkg.dev/devops-cert-labs-v2/secure-images

#select the biggest size image

gcloud artifacts vulnerabilities list "europe-west1-docker.pkg.dev/devops-cert-labs-v2/secure-images/container-analysis-lab@sha256:a4b0561c660a1b7d81ce5c70573f7fade5214c2d256c9bcf60d2dad40d444122"      
+--------------------------------------------------------------------------------------------------------------------+
|                                       Latest scan was at 2026-07-20T18:37:25                                       |
+------------------+--------------------+------+---------------+------------+-------------+--------------+-----------+
|       CVE        | EFFECTIVE_SEVERITY | CVSS | FIX_AVAILABLE | VEX_STATUS |   PACKAGE   | PACKAGE_TYPE | VEX_SCOPE |
+------------------+--------------------+------+---------------+------------+-------------+--------------+-----------+
...
```

# Lab Q55 - Container Analysis Vulnerability Scanning

## Question

Your organization recently adopted a container-based workflow for application development. Your team develops numerous applications that are deployed continuously through an automated build pipeline to the production environment.

A recent security audit alerted your team that the code pushed to production could contain vulnerabilities and that the existing tooling around virtual machine (VM) vulnerabilities no longer applies to the containerized environment.

You need to ensure the security and patch level of all code running through the pipeline.

**What should you do?**

- A. Set up Container Analysis to scan and report Common Vulnerabilities and Exposures.
- B. Configure the containers in the build pipeline to always update themselves before release.
- C. Reconfigure the existing operating system vulnerability software to exist inside the container.
- D. Implement static code analysis tooling against the Docker files used to create the containers.

**Correct Answer:** A

---

# Scenario

Your company already uses a CI/CD pipeline with Cloud Build and Artifact Registry to build and publish Docker images.

However, no vulnerability scanning is configured.

The objective of this lab is to demonstrate how enabling Container Analysis allows Google Cloud to automatically scan container images stored in Artifact Registry and report known CVEs (Common Vulnerabilities and Exposures).

---

# Architecture

```
GitHub Repository
        │
        ▼
Cloud Build Trigger
        │
        ▼
Docker Build
        │
        ▼
Artifact Registry
        │
        ▼
Container Analysis
        │
        ▼
CVE Report
```

---

# Terraform Resources

## Provider

The lab uses the Google provider.

```terraform
provider "google"
```

---

## APIs

Terraform enables the services required by the pipeline.

- Artifact Registry API
- Cloud Build API

Container Analysis is intentionally not enabled at the beginning of the lab.

```terraform
google_project_service
```

Students must identify the missing API and enable it during the exercise.

---

## Artifact Registry

Terraform creates a Docker repository called:

```
secure-images
```

Cloud Build pushes all generated images into this repository.

```terraform
google_artifact_registry_repository
```

---

## Storage Bucket

A Cloud Storage bucket is created for the lab.

A random suffix guarantees a unique bucket name.

```terraform
google_storage_bucket
```

---

## Cloud Build Trigger

Terraform creates a GitHub trigger.

Whenever code is pushed to the **main** branch:

- Cloud Build starts automatically.
- Docker builds the image.
- The image is pushed into Artifact Registry.

```terraform
google_cloudbuild_trigger
```

---

## Outputs

Terraform returns useful information including:

- Artifact Registry repository
- Artifact Registry URL
- Cloud Storage bucket
- Cloud Build trigger
- Region

---

# Dockerfile

The Docker image intentionally installs several operating system packages.

Example:

- curl
- wget
- vim

These packages increase the number of known vulnerabilities, making the Container Analysis report more interesting.

---

# Cloud Build

The Cloud Build pipeline performs two steps.

## Build

```
docker build
```

## Push

```
docker push
```

The image is uploaded into Artifact Registry.

---

# Initial Problem

The pipeline successfully builds and publishes images.

However, no vulnerability scan is performed.

Running:

```powershell
gcloud artifacts vulnerabilities list IMAGE
```

returns:

```
Scan status unknown
```

because Container Analysis has not been configured.

---

# Solution

Enable the required APIs.

```terraform
resource "google_project_service" "containeranalysis" {

  service = "containeranalysis.googleapis.com"

}

resource "google_project_service" "containerscanning" {

  service = "containerscanning.googleapis.com"

}
```

After enabling both services:

1. Push new code.
2. Cloud Build creates a new image.
3. Artifact Registry stores the image.
4. Container Analysis scans the image automatically.

---

# Verification

List the images stored in Artifact Registry.

```powershell
gcloud artifacts docker images list europe-west1-docker.pkg.dev/devops-cert-labs-v2/secure-images
```

Find the digest of the newest image.

Then inspect its vulnerabilities.

```powershell
gcloud artifacts vulnerabilities list "europe-west1-docker.pkg.dev/devops-cert-labs-v2/secure-images/container-analysis-lab@sha256:<DIGEST>"
```

Expected output:

```
Latest scan was at ...

CVE-XXXX-XXXX
Severity: CRITICAL

CVE-XXXX-XXXX
Severity: HIGH

CVE-XXXX-XXXX
Severity: LOW
```

Multiple CVEs should be reported.

---

# Why Answer A is Correct

Container Analysis continuously scans container images stored in Artifact Registry.

It identifies:

- Known vulnerabilities
- CVEs
- Severity levels
- Vulnerable operating system packages

This provides centralized vulnerability management for containerized workloads.

---

# Why the Other Answers Are Incorrect

## B

Containers should not update themselves before deployment.

Images must be immutable and reproducible.

---

## C

Traditional VM vulnerability software is designed for virtual machines, not container images.

Google Cloud already provides a native vulnerability scanning solution.

---

## D

Static analysis of Dockerfiles can identify bad practices, but it does not detect known package vulnerabilities or CVEs inside the built image.

---

# Commands

Apply the infrastructure.

```powershell
terraform apply -auto-approve
```

List images.

```powershell
gcloud artifacts docker images list europe-west1-docker.pkg.dev/devops-cert-labs-v2/secure-images
```

Check vulnerabilities.

```powershell
gcloud artifacts vulnerabilities list "europe-west1-docker.pkg.dev/devops-cert-labs-v2/secure-images/container-analysis-lab@sha256:<DIGEST>"
```

Enable the missing services.

```powershell
gcloud services enable containeranalysis.googleapis.com
gcloud services enable containerscanning.googleapis.com
```

Trigger a new build.

```powershell
gcloud builds triggers run container-analysis-pipeline --branch=main
```

---

# Conclusion

This lab demonstrates how Container Analysis integrates with Artifact Registry and Cloud Build to automatically scan container images for known vulnerabilities.

Once Container Analysis is enabled, every newly published image is analyzed and CVEs are reported automatically, providing a secure container delivery pipeline.