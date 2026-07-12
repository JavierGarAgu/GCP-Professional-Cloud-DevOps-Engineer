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

## B - Use Cloud Pub/Sub to trigger a Spinnaker pipeline.

---

## Why?

The correct answer is **Cloud Pub/Sub triggering a Spinnaker pipeline** because the container image is already built and stored in Google Container Registry.

The main requirement is to automatically start a deployment process when a new image version is available.

Cloud Pub/Sub works as an event notification system. When a new image is pushed, it can send an event that triggers Spinnaker, which then manages the deployment to Kubernetes.

The flow is:

```
Container Registry
        |
        | New image pushed
        |
        v
    Cloud Pub/Sub
        |
        | Event notification
        |
        v
    Spinnaker Pipeline
        |
        | Deploy application
        |
        v
        GKE
```

This approach requires less development effort because Pub/Sub and Spinnaker already provide the event-driven deployment workflow.

---

# Why the other options are not correct?

### A - Use Cloud Build to trigger a Spinnaker pipeline

Cloud Build is mainly used for building and publishing container images.

In this scenario, the images are already built and pushed to GCR, so using Cloud Build as the trigger is not the best option.

---

### C - Use a custom builder in Cloud Build to trigger Jenkins pipeline

This introduces unnecessary complexity.

Jenkins could be used for CI/CD, but it requires maintaining another system instead of using Google Cloud native services.

---

### D - Use Cloud Pub/Sub to trigger a custom deployment service running in GKE

This can work technically, but it requires creating and maintaining a custom deployment application.

The question asks for minimizing development effort, so using an existing deployment platform like Spinnaker is preferred.

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
```

Pub/Sub is included to simulate the event notification generated when a new container image becomes available.

In a real production environment, Spinnaker would consume this event and execute the deployment workflow.

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
4. A Pub/Sub event is published.
5. The deployment process starts.
6. The application is deployed to GKE.

Verify the deployment:

```bash
kubectl get pods -n production

kubectl get service -n production
```

---

# Commands

```powershell
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

---

# Conclusion

The main idea is that Cloud Pub/Sub provides the event notification when a new container image is available, and Spinnaker handles the deployment process.

For this laboratory, Cloud Build and Kubernetes simulate this workflow to demonstrate the same event-driven deployment concept in a simpler way.