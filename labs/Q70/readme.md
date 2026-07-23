COMMANDS

PREPARE BEFORE INCIDENT SIMULATION
```
gcloud container clusters get-credentials game-cluster-europe --zone europe-west1-b

kubectl apply -f deployment.yaml

kubectl apply -f service.yaml

kubectl get pods

kubectl get svc

gcloud container clusters get-credentials game-cluster-usa --zone us-central1-a

kubectl apply -f deployment.yaml

kubectl apply -f service.yaml

kubectl get pods

kubectl get svc
```

SIMULATE INCIDENT
```
gcloud container clusters get-credentials game-cluster-europe --zone europe-west1-b

kubectl scale deployment mobile-game --replicas=0

kubectl get deployments

kubectl get pods

kubectl get svc

gcloud container clusters get-credentials game-cluster-usa --zone us-central1-a

kubectl get deployments

kubectl get pods

kubectl get svc
```

# Q70 - Google Kubernetes Engine Multi-Region Incident Response

## Overview

This lab demonstrates a multi-region Google Kubernetes Engine (GKE) deployment designed to simulate a production incident. The infrastructure includes two Kubernetes clusters deployed in different Google Cloud regions, allowing the same application to run independently in each location.

The goal of the lab is to understand how Site Reliability Engineering (SRE) principles should be applied during a regional outage. Instead of immediately investigating the root cause, the priority is to restore service availability by redirecting user traffic to a healthy region.

---

# Architecture

The Terraform configuration creates the following infrastructure:

* Required Google Cloud APIs
* Dedicated Virtual Private Cloud (VPC)
* Two regional subnets
* Firewall rules for internal communication
* Service Account for GKE nodes
* IAM permissions for Logging, Monitoring and Artifact Registry
* GKE cluster in Europe
* GKE cluster in the United States

After the infrastructure is deployed, the same Kubernetes application is installed on both clusters.

The architecture looks like this:

```
                 Users
                   │
                   │
          Global Traffic Routing
             /              \
            /                \
           ▼                  ▼
 Europe GKE Cluster     USA GKE Cluster
      Mobile Game         Mobile Game
```

Both clusters host the same application so that one region can continue serving users if the other becomes unavailable.

---

# Terraform Infrastructure

## Google Provider

Terraform configures the Google provider using the target project and default region.

The required APIs are automatically enabled before any infrastructure resources are created.

---

## Networking

A dedicated VPC is created instead of using the default network.

Two custom subnets are provisioned:

* Europe subnet
* USA subnet

This separates the networking resources for each Kubernetes cluster while keeping them inside the same VPC.

A firewall rule allows internal communication between both regions.

---

## Service Account

A dedicated Service Account is created for the Kubernetes nodes.

The Service Account receives only the permissions required for normal cluster operation, including:

* Logging Writer
* Monitoring Metric Writer
* Artifact Registry Reader

Using a dedicated identity follows the Principle of Least Privilege.

---

## Google Kubernetes Engine

Two independent Kubernetes clusters are created.

The first cluster is deployed in:

* europe-west1-b

The second cluster is deployed in:

* us-central1-a

Each cluster contains its own managed node pool with two worker nodes.

Cloud Logging and Cloud Monitoring are enabled to provide observability for both environments.

---

# Kubernetes Deployment

After Terraform finishes, the application is deployed to both clusters.

The lab uses a simple Nginx web server to represent the mobile game application.

The Kubernetes Deployment creates three replicas, while a LoadBalancer Service exposes the application to the Internet.

Both clusters provide the same web application independently.

---

# Simulating the Incident

The incident is simulated by scaling the Deployment in the European cluster from three replicas to zero.

```
kubectl scale deployment mobile-game --replicas=0
```

The application immediately becomes unavailable in Europe.

The deployment running in the United States continues serving users without interruption.

This reproduces the scenario described in the certification exam where an entire region becomes unavailable.

---

# Site Reliability Engineering Approach

One of the most important SRE principles is to restore service before investigating the incident.

The correct sequence is:

1. Minimize user impact.
2. Redirect traffic to a healthy region.
3. Restore service availability.
4. Investigate the root cause.
5. Apply a permanent fix.

This approach reduces downtime and improves the overall user experience.

---

# Exam Question

**Question**

You support a popular mobile game application deployed on Google Kubernetes Engine (GKE) across several Google Cloud regions. Each region has multiple Kubernetes clusters.

You receive a report that none of the users in a specific region can connect to the application.

You want to resolve the incident while following Site Reliability Engineering practices.

What should you do first?

**Correct Answer**

**A — Reroute the user traffic from the affected region to other regions that don't report issues.**

---

# Why Option A is Correct

The primary objective during an incident is to restore service as quickly as possible.

Redirecting user traffic to healthy regions immediately reduces customer impact while engineers investigate the failure.

This follows Google's Site Reliability Engineering philosophy of prioritizing service availability before performing root cause analysis.

---

# Why the Other Answers Are Incorrect

### B

Checking CPU or memory usage may help identify the cause of the incident, but it does not restore service.

Users remain unable to access the application while the investigation is taking place.

---

### C

Adding a larger node pool assumes that the issue is related to resource exhaustion.

At the beginning of an incident there is no evidence supporting this assumption, and creating additional nodes takes time without guaranteeing a solution.

---

### D

Reviewing Cloud Logging is useful for diagnosing the problem after service has been restored.

It is not the first action because it delays recovery and keeps users affected for a longer period.

---

# Conclusion

This lab demonstrates a simple multi-region Kubernetes deployment designed to illustrate Google's Site Reliability Engineering practices.

By deploying identical applications in two independent GKE clusters and simulating a regional failure, the lab shows why restoring service availability takes priority over troubleshooting.

This incident response strategy is a common topic in the Professional Cloud DevOps Engineer certification and reflects how production environments are managed in real-world cloud platforms.
