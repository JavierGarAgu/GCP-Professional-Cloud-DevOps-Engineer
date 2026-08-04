# Q134 - Binary Authorization for Trusted Container Images

## Objective

The goal of this question is to identify the Google Cloud service that enforces deploy-time security policies while keeping operational management as simple as possible.

This question covers the same concept as **Q133** and is directly related to **Lab Q16**, where Binary Authorization was integrated with Cloud Build, Artifact Registry, Cloud KMS, and GKE.

---

## Scenario

The company operates in a regulated environment where only trusted container images are allowed to run in production.

The recommended Google Cloud solution is to enable **Binary Authorization** on the GKE clusters.

**Correct Answer: A**

Configure Binary Authorization in your GKE clusters to enforce deploy-time security policies.

---

## Why Binary Authorization?

Binary Authorization is a managed Google Cloud service that verifies container images before deployment.

Only images that satisfy the configured security policy and have valid attestations are allowed to run.

This provides strong deployment security with very little operational overhead.

---

## Deployment Flow

```text
Developer
     |
     v
Commit source code
     |
     v
Cloud Build
     |
     +----------------------+
     | Build Docker image   |
     | Security validation  |
     | Create attestation   |
     +----------------------+
     |
     v
Artifact Registry
     |
     v
Binary Authorization
     |
     +----------------------+
     | Trusted image ?      |
     +----------+-----------+
                |
         Yes    |    No
          |     |     |
          v     |     v
     Deploy     |  Deployment denied
        to GKE  |
```

---

## Why the Other Answers Are Wrong

### B. Artifact Registry Writer Role

Restricting write permissions improves security, but it does not verify container images during deployment.

---

### C. Cloud Run Validator

A custom validation service would increase operational complexity and management overhead.

The question explicitly asks for the solution with the lowest management effort.

---

### D. Kritis

Kritis can enforce image security policies, but it requires additional deployment and maintenance.

Binary Authorization is Google's fully managed solution and is the recommended choice for GKE.

---

## Relationship with Lab Q16

Lab Q16 implements the infrastructure required for Binary Authorization:

- Artifact Registry
- Cloud Build
- Cloud KMS
- Binary Authorization
- GKE
- IAM configuration
- Trusted deployment pipeline

The lab demonstrates how trusted images are validated before deployment instead of after they are already running.

---

## Exam Tips

Remember the following services:

- Binary Authorization = Enforce trusted image deployment
- Container Analysis = Scan images for vulnerabilities
- Cloud KMS = Sign trusted artifacts
- Cloud Build = Build images and create attestations
- Artifact Registry = Store container images

If the exam mentions:

- trusted images
- deploy-time security
- deployment policy
- admission control
- regulated environment
- minimize management overhead

The correct answer is almost always **Binary Authorization**.