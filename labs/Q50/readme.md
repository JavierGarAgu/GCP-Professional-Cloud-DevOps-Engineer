# Q49 - Binary Authorization for Approved Deployments

## Exam Question

Your organization recently adopted a container-based workflow for application development. Applications are built and deployed automatically to a production GKE cluster.

The security team is concerned that developers or operators could bypass the CI/CD pipeline and deploy container images directly to production.

What should you do?

**Correct answer: D**

> Enable Binary Authorization inside the Kubernetes cluster and configure the build pipeline as an attestor.

---

## Lab Overview

This lab is intentionally very similar to **Q16** because both exam questions test the same Google Cloud feature.

The objective is to guarantee that only container images built, signed, and approved by the CI/CD pipeline can run inside the production GKE cluster.

Even if someone has Kubernetes access, Binary Authorization prevents the deployment of unsigned or untrusted images.

---

## Architecture

```
Developer
     │
     ▼
GitHub (main branch)
     │
     ▼
Cloud Build Trigger
     │
     ▼
Build Docker Image
     │
     ▼
Artifact Registry
     │
     ▼
Get Image Digest
     │
     ▼
Sign Image (KMS + Binary Authorization Attestor)
     │
     ▼
Deploy to GKE
     │
     ▼
Binary Authorization Policy
     │
     ▼
Only signed images are allowed
```

---

## What Terraform Creates

The `main.tf` file provisions all required infrastructure:

- Required Google Cloud APIs
- Artifact Registry repository
- Cloud Build service account
- GKE node service account
- Cloud KMS key ring
- Cloud KMS asymmetric signing key
- IAM permissions
- GKE cluster
- Binary Authorization enabled on the cluster
- Kubernetes production namespace
- Cloud Build trigger connected to the GitHub repository

---

## Binary Authorization

Binary Authorization is a security feature that verifies container images before they are deployed.

Instead of trusting every image, the cluster checks whether the image has been approved by a trusted attestor.

If the image is not signed, the deployment is rejected.

This prevents developers or operators from bypassing the official CI/CD pipeline.

---

## Cloud Build Pipeline

The pipeline performs the following steps:

1. Build the Docker image.
2. Push the image to Artifact Registry.
3. Retrieve the image digest.
4. Sign the image using Cloud KMS.
5. Create a Binary Authorization attestation.
6. Obtain GKE credentials.
7. Update the Kubernetes manifest with the image digest.
8. Deploy the application to the cluster.

Because the image is signed before deployment, Binary Authorization allows the deployment to succeed.

---

## Why the Correct Answer is D

The exam scenario is about enforcing approvals before applications reach production.

Binary Authorization provides this protection by allowing only images that were approved by a trusted build pipeline.

Even if someone tries to deploy manually with `kubectl`, the cluster refuses unsigned images.

This guarantees that production workloads always come from the approved CI/CD process.

---

## Relation to Q16

This lab is almost identical to **Q16** because both questions evaluate the same Google Cloud security mechanism.

The implementation, architecture, and deployment flow are the same:

- Cloud Build builds the image.
- Artifact Registry stores the image.
- Cloud KMS signs the image.
- Binary Authorization verifies the signature.
- GKE accepts only trusted images.

The only difference is the wording of the exam question. Both questions are solved by using Binary Authorization together with a trusted build pipeline acting as the attestor.

---

## Learning Objectives

After completing this lab, you should understand how to:

- Enable Binary Authorization on a GKE cluster.
- Configure a trusted CI/CD pipeline.
- Sign container images using Cloud KMS.
- Create Binary Authorization attestations.
- Prevent unauthorized deployments.
- Protect production clusters from unsigned container images.