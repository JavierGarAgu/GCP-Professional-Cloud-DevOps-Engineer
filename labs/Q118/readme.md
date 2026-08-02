# Q118 - Shift Left Security with Binary Authorization

```text
#########################################################
#                                                       #
#          Q118 - SHIFT LEFT SECURITY ON GKE            #
#                                                       #
#        Binary Authorization + Trusted Images          #
#                                                       #
#########################################################
```

## Scenario

The company wants to implement a **shift left security** strategy for Google Kubernetes Engine (GKE).

Only trusted and approved container images should be allowed to run in the cluster.

The correct answer is:

**C. Use Binary Authorization to attest images during your CI/CD pipeline.**

This question is directly covered by **Lab Q16**, where Binary Authorization is integrated into a complete CI/CD pipeline.

---

## Why Option C is Correct

Binary Authorization enforces deployment policies before containers are allowed to run.

Instead of discovering security issues after deployment, images are validated during the CI/CD pipeline.

Only approved and trusted images can be deployed to GKE.

This follows the shift left security principle by moving security checks earlier in the software delivery lifecycle.

---

## Architecture

```text
Developer
     |
     v
GitHub Repository
     |
     v
Cloud Build
     |
     +-------------------------+
     |                         |
     | Build Docker Image      |
     |                         |
     +-------------------------+
               |
               v
Artifact Registry
               |
               v
Binary Authorization
               |
      Trusted Image?
         /        \
       Yes         No
       |            |
       v            v
Deploy to GKE   Deployment Blocked
```

---

## What Lab Q16 Demonstrates

Lab Q16 builds the complete infrastructure required for Binary Authorization.

The lab includes:

* Artifact Registry repository
* Cloud Build pipeline
* Cloud KMS signing key
* Binary Authorization API
* Container Analysis API
* GKE cluster with Binary Authorization enabled
* Kubernetes namespace
* IAM permissions for Cloud Build and GKE

The Terraform configuration also enables Binary Authorization on the cluster.

Example:

```hcl
binary_authorization {

  evaluation_mode = "PROJECT_SINGLETON_POLICY_ENFORCE"

}
```

This configuration tells GKE to enforce Binary Authorization policies before workloads are deployed.

---

## Why the Other Answers Are Incorrect

### A. Deploy Falco or Twistlock

These tools monitor workloads after deployment.

They detect runtime security issues but do not prevent untrusted images from being deployed.

---

### B. Configure IAM Policies

IAM controls user permissions.

It does not validate whether container images are trusted.

---

### D. Enable Container Analysis

Container Analysis scans images and reports vulnerabilities.

It provides useful security information but does not stop deployments.

Binary Authorization is the component that enforces deployment policies.

---

## Key Exam Idea

Remember the difference:

* Container Analysis → Scans images.
* Binary Authorization → Decides whether an image is allowed to run.

If the exam mentions:

* trusted images
* approved images
* image attestation
* deployment policy
* shift left security

the answer is almost always **Binary Authorization**.

---

## Conclusion

Question Q118 is essentially the theoretical version of Lab Q16.

The lab demonstrates how to integrate Binary Authorization into a CI/CD pipeline so that only trusted container images stored in Artifact Registry can be deployed to GKE.

This reduces security risks before deployment and implements a true shift left security approach.
