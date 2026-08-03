COMMANDS
```
choco install kubernetes-helm
gcloud auth configure-docker europe-west1-docker.pkg.dev

helm create demo-chart

helm package demo-chart

dir *.tgz

helm push demo-chart-0.1.0.tgz oci://europe-west1-docker.pkg.dev/devops-cert-labs-v4/helm-oci

gcloud artifacts packages list `
--repository=helm-oci `
--location=europe-west1

gcloud artifacts versions list `
--package=demo-chart `
--repository=helm-oci `
--location=europe-west1

gcloud artifacts docker images list europe-west1-docker.pkg.dev/devops-cert-labs-v4/helm-oci

helm pull oci://europe-west1-docker.pkg.dev/devops-cert-labs-v4/helm-oci/demo-chart --version 0.1.0
```
# Q113 - Store Helm Charts as OCI Artifacts in Artifact Registry

## Scenario

The organization uses Helm to package Kubernetes applications.

Some Helm charts are private, while others come from public repositories.

The security team considers public Helm repositories a security risk because they are outside the organization's control.

The objective is to manage both public and private charts in a single platform with native Google Cloud security features.

The correct answer is:

**A. Store public and private charts in OCI format by using Artifact Registry.**

---

# Why This Is the Correct Solution

Artifact Registry supports the Open Container Initiative (OCI) specification.

Although it is commonly used to store Docker images, it can also store other OCI artifacts such as Helm charts.

Using Artifact Registry provides several advantages:

* Identity and Access Management (IAM)
* Native access control
* VPC Service Controls support
* Private storage
* Centralized artifact management

Instead of downloading Helm charts directly from public repositories, every chart can be stored inside the organization's Artifact Registry repository.

This creates a single trusted location for all application packages.

---

# Why the Other Answers Are Incorrect

## B. GitHub Enterprise

GitHub is a source code platform.

Although Helm charts can be stored in Git repositories, GitHub is not a native OCI registry and does not provide the same Artifact Registry integration.

---

## C. Cloud Storage Bucket

A Cloud Storage bucket can host a traditional Helm repository.

However, this solution does not use the OCI standard and requires additional synchronization between Git and Cloud Storage.

It also lacks the native OCI workflow supported by Artifact Registry.

---

## D. Self-Hosted Helm Repository

Running a Helm repository inside Google Kubernetes Engine increases operational complexity.

The organization would need to maintain infrastructure, storage, updates, monitoring, and backups.

Artifact Registry is a managed service that removes this operational overhead.

---

# Lab Architecture

The laboratory creates an Artifact Registry repository configured to store OCI artifacts.

A Helm chart is packaged locally and uploaded directly into Artifact Registry.

```text
                Developer
                     │
                     ▼
              Helm Chart (.tgz)
                     │
             helm package
                     │
                     ▼
              helm push (OCI)
                     │
                     ▼
        Artifact Registry Repository
             Format: DOCKER (OCI)
                     │
      ┌──────────────┴──────────────┐
      │                             │
      ▼                             ▼
 Private Helm Charts         Public Helm Charts
```

---

# Lab Implementation

Terraform creates the following resources:

* Artifact Registry API
* Artifact Registry repository
* Service Account
* Artifact Registry Writer IAM role

After the infrastructure is deployed, a Helm chart is created locally.

The chart is packaged into a compressed archive.

Finally, the package is uploaded to Artifact Registry using the OCI protocol.

The uploaded chart can later be downloaded directly from Artifact Registry.

---

# OCI Repository

One important concept demonstrated in this lab is that Helm charts are stored as OCI artifacts.

The repository format is configured as:

```text
DOCKER
```

This may look confusing at first.

The repository is not limited to Docker images.

Artifact Registry uses Docker repositories to store OCI-compatible artifacts, including Helm charts.

This means the same repository technology can manage multiple OCI artifact types.

---

# Benefits of Artifact Registry

Using Artifact Registry provides several security and operational advantages:

* Centralized artifact storage
* IAM access control
* Integration with VPC Service Controls
* Private repositories
* Native OCI support
* Managed Google Cloud service
* No infrastructure maintenance

These features make Artifact Registry a better choice than maintaining a self-hosted Helm repository.

---

# Key Lesson

Artifact Registry is more than a Docker image registry.

It is a managed OCI registry capable of storing different artifact types, including Helm charts.

Using Artifact Registry allows organizations to replace public Helm repositories with a secure, centrally managed OCI repository while benefiting from Google Cloud IAM and VPC Service Controls.
