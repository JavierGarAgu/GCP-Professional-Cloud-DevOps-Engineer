The correct answer is A: Use Cloud Build to trigger a Spinnaker pipeline because it separates the build and deployment phases correctly. Cloud Build is responsible for creating and publishing the container image, while Spinnaker manages the deployment process in Kubernetes. This option requires less development effort than creating custom solutions with Pub/Sub or Jenkins. It is also a common CI/CD pattern used in real environments because it allows automated deployments, rollbacks and advanced delivery strategies. In this lab, Cloud Build simulates the Spinnaker deployment step to keep the example simple.

COMMANDS

```
gcloud container clusters get-credentials event-driven-gke --zone=europe-west1-b --project=devops-cert-labs

kubectl cluster-info

kubectl get nodes -o wide

kubectl get ns

kubectl get all -n production

kubectl get events -n production --sort-by=.lastTimestamp

gcloud run services list --region=europe-west1

gcloud run services describe deployment-service --region=europe-west1

gcloud pubsub topics list

gcloud pubsub subscriptions list

gcloud pubsub topics publish deployment-events --message="{\"image\":\"webapp\",\"tag\":\"latest\"}"

gcloud builds triggers list

gcloud builds list

gcloud artifacts docker images list europe-west1-docker.pkg.dev/devops-cert-labs/deployment-images

gcloud iam service-accounts list

gcloud projects get-iam-policy devops-cert-labs
```

```markdown
# Google Cloud Professional Cloud DevOps Engineer Lab

# Question - Automated Deployment After Container Image Update

---

## Introduction

This repository contains a small hands-on lab created while preparing for the **Google Cloud Professional Cloud DevOps Engineer** certification.

The goal of this lab is to understand how an automated deployment pipeline can be created when a new container image is available.

The exam question asks:

> Your application images are built and pushed to Google Container Registry (GCR). You want to build an automated pipeline that deploys the application when the image is updated while minimizing the development effort. What should you do?

Options:

A. Use Cloud Build to trigger a Spinnaker pipeline.  
B. Use Cloud Pub/Sub to trigger a Spinnaker pipeline.  
C. Use a custom builder in Cloud Build to trigger Jenkins pipeline.  
D. Use Cloud Pub/Sub to trigger a custom deployment service running in GKE.

---

# Correct Answer

## A - Use Cloud Build to trigger a Spinnaker pipeline.

---

## Why?

The best answer is **Cloud Build triggering Spinnaker** because this follows the common CI/CD architecture.

Cloud Build is responsible for building and publishing the container image.

After that, a Continuous Delivery tool like Spinnaker manages the deployment process to Kubernetes.

The flow is:

```

Developer
|
v
Cloud Build
|
| Build image
| Push image
|
v
Spinnaker Pipeline
|
| Deploy application
|
v
GKE

```

Spinnaker is designed for deployment orchestration, rollback strategies and progressive delivery.

---

# Why the other options are not correct?

### B - Pub/Sub triggering Spinnaker

Pub/Sub can be used for event notifications, but it is not the main deployment orchestrator.

It can notify systems that something changed, but Spinnaker should handle the deployment workflow.

---

### C - Cloud Build triggering Jenkins

This adds unnecessary complexity.

Jenkins can perform CI/CD tasks, but in Google Cloud environments Cloud Build integrates better with Google services.

---

### D - Pub/Sub triggering a custom deployment service in GKE

This can work technically, but it requires creating and maintaining a custom deployment application.

The question asks for minimizing development effort, so using an existing CD platform is preferred.

---

# Lab Implementation

In this lab, Spinnaker is simulated using Cloud Build deployment stages.

The architecture is:

```

GitHub
|
v
Cloud Build Trigger
|
+--> Build Docker image
|
+--> Push image to Artifact Registry
|
+--> Publish Pub/Sub event
|
+--> Deploy application to GKE

````

Pub/Sub is included to simulate the event generated when a new image is available.

In a real production environment, this event could be consumed by a deployment platform such as Spinnaker.

---

# Infrastructure

Terraform creates:

- GKE cluster
- Artifact Registry repository
- Cloud Build trigger
- Pub/Sub topic
- IAM permissions
- Kubernetes namespace

The application repository contains:

- Dockerfile
- Simple Flask application
- Cloud Build pipeline
- Kubernetes manifests

---

# Testing

After pushing a change to the main branch:

1. Cloud Build starts automatically.
2. The Docker image is created.
3. The image is pushed to Artifact Registry.
4. The deployment event is published.
5. The application is deployed to GKE.

Verify the deployment:

```bash
kubectl get pods -n production

kubectl get service -n production
````

---

# Conclusion

The main idea is that Cloud Build handles the CI part and a deployment platform like Spinnaker handles the CD part.

For this laboratory, Cloud Build directly performs the deployment to keep the example simple, but the architecture represents the same event-driven deployment concept.
