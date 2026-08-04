# Q133 - Binary Authorization and Trusted Images

```text
=========================================================
   ____  _                       _          _   _     
  |  _ \(_)                     | |        | | | |    
  | |_) |_ _ __   __ _ _ __ _   | |    __ _| |_| |__  
  |  _ <| | '_ \ / _` | '__| |  | |   / _` | __| '_ \ 
  | |_) | | | | | (_| | |  | |  | |__| (_| | |_| | | |
  |____/|_|_| |_|\__,_|_|  |_|  |_____\__,_|\__|_| |_|

        Trusted Images with Binary Authorization
=========================================================
```

## Objective

The goal of this question is to understand how to prevent untrusted container images from being deployed to Google Kubernetes Engine (GKE). This is a core Shift Left Security practice.

This question is based on the implementation completed in **Lab Q16**, where Binary Authorization, Cloud Build, Artifact Registry, KMS, and GKE were integrated into a secure deployment pipeline.

---

## Scenario

The InfoSec team requires every GKE cluster to accept only trusted and approved container images.

The correct solution is to use **Binary Authorization** with image attestations created during the CI/CD pipeline.

**Correct Answer: B**

Use Binary Authorization to attest images during your CI/CD pipeline.

---

## Why Binary Authorization?

Binary Authorization acts as an admission controller for GKE.

Instead of checking images after deployment, it verifies whether an image was approved before allowing it to run.

This moves security earlier in the software delivery process.

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
     | Run security checks  |
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
     Deploy     |  Deployment blocked
        to GKE  |
```

---

## Why the Other Answers Are Wrong

### A. Container Analysis

Container Analysis scans images for known vulnerabilities.

It helps detect CVEs but does not stop vulnerable images from being deployed.

---

### C. IAM Policies

IAM controls who can access Google Cloud resources.

It does not validate container images before deployment.

---

### D. Falco or Twistlock

These tools monitor running workloads.

They provide runtime security, not deployment protection.

This is a Shift Right approach instead of Shift Left.

---

## Relationship with Lab Q16

Lab Q16 demonstrates the complete infrastructure required for Binary Authorization, including:

- Artifact Registry
- Cloud Build trigger
- GKE cluster
- Binary Authorization enabled
- Cloud KMS signing key
- IAM permissions
- Trusted deployment pipeline

The purpose of the lab is to understand how trusted images move through a secure CI/CD pipeline before reaching production.

---

## Exam Tips

Remember these concepts:

- Container Analysis = Detect vulnerabilities
- Binary Authorization = Allow only trusted images
- Cloud KMS = Sign trusted artifacts
- Cloud Build = Create attestations
- GKE = Enforce deployment policy

If the exam mentions:

- trusted images
- approved images
- image attestation
- prevent deployment
- admission control
- Shift Left Security

The correct answer is almost always **Binary Authorization**.