# GCP Professional Cloud DevOps Engineer

## Question

Your team has recently deployed an NGINX-based application into Google Kubernetes Engine (GKE) and has exposed it to the public via an HTTP Google Cloud Load Balancer (GCLB) ingress. You want to scale the deployment of the application's frontend using an appropriate Service Level Indicator (SLI). What should you do?

**Correct Answer: C**

> Install the Stackdriver custom metrics adapter and configure a Horizontal Pod Autoscaler (HPA) to use the number of requests provided by the Google Cloud Load Balancer.

---

# Objective

The purpose of this lab is to deploy a simple NGINX application into GKE and expose it through a Google Cloud HTTP Load Balancer using an Ingress resource.

The original certification question expects the application to scale based on the number of requests received by the load balancer instead of CPU or memory usage.

---

# Architecture

```
                Internet
                    │
                    ▼
      Google Cloud HTTP Load Balancer
                    │
                    ▼
               GKE Ingress
                    │
                    ▼
              Kubernetes Service
                    │
                    ▼
        NGINX Deployment (Pods)
```

The HTTP Load Balancer receives all external traffic and forwards requests to the Kubernetes Service through the GKE Ingress.

In the original exam scenario, the Horizontal Pod Autoscaler would use request metrics collected from the Google Cloud Load Balancer.

---

# Infrastructure created

Terraform deploys the following resources:

- Google Kubernetes Engine cluster
- Managed node pool
- Workload Identity
- Kubernetes Namespace
- NGINX Deployment
- Kubernetes Service
- GKE Ingress
- Google Cloud HTTP Load Balancer (created automatically by the Ingress)

No CI/CD pipeline is required because the purpose of this lab is to demonstrate autoscaling concepts rather than software delivery.

---

# Main.tf explanation

## Enable Google Cloud APIs

Terraform enables the APIs required for Kubernetes and monitoring.

These include:

- Compute Engine API
- Kubernetes Engine API
- Cloud Monitoring API
- Cloud Logging API
- IAM API

---

## Google Kubernetes Engine

A GKE cluster is created using the Regular release channel.

The cluster uses:

- Workload Identity
- VPC Native networking
- Dedicated node pool
- e2-medium virtual machines

---

## Kubernetes Deployment

Terraform deploys an NGINX application with two replicas.

The Deployment also defines:

- Resource requests
- Resource limits
- Readiness probe
- Liveness probe

These probes are important for application health but they are **not** intended to be used as autoscaling metrics.

---

## Kubernetes Service

A NodePort Service exposes the NGINX Deployment internally.

The Service becomes the backend used by the Ingress.

---

## Kubernetes Ingress

The Ingress automatically creates a Google Cloud HTTP Load Balancer.

This is the component responsible for collecting request metrics that can later be used for autoscaling.

---

# Why Answer C is correct

The application is publicly exposed through a Google Cloud Load Balancer.

The load balancer already knows:

- Number of requests
- Request rate
- Latency
- Availability

These metrics represent the real workload of the application.

Scaling based on incoming requests provides better behaviour than scaling only on CPU usage because traffic can increase before CPU utilization becomes high.

The Horizontal Pod Autoscaler should therefore use request metrics coming from Google Cloud Monitoring.

---

# Why the other answers are incorrect

## A

Using the response time of Liveness and Readiness probes is incorrect.

These probes only verify container health.

They are not Service Level Indicators and should never drive autoscaling decisions.

---

## B

Vertical Pod Autoscaler changes the CPU and memory assigned to existing Pods.

The question asks to scale the frontend deployment by adding more replicas.

Horizontal Pod Autoscaler is the appropriate solution.

---

## D

NGINX exposes its own statistics endpoint, but the application is already behind a Google Cloud Load Balancer.

Using metrics collected by the load balancer provides a more accurate view of user traffic and is the recommended solution.

---

# Important note about the Stackdriver Custom Metrics Adapter

This is one of the few Professional Cloud DevOps Engineer questions whose original implementation has changed over time.

When this exam question was created, Google recommended installing the **Stackdriver Custom Metrics Adapter** to allow the Horizontal Pod Autoscaler to consume metrics from Stackdriver (now Cloud Monitoring).

However, this adapter is now considered legacy and is no longer the recommended approach for modern GKE clusters.

For this reason, this repository **does not install the Stackdriver Custom Metrics Adapter**.

Trying to reproduce the original exam environment today would require using outdated manifests and deprecated components that are no longer officially maintained.

Instead, this lab focuses on deploying the infrastructure required by the scenario:

- GKE
- NGINX
- Service
- Ingress
- Google Cloud Load Balancer

This demonstrates the architecture expected by the certification while avoiding obsolete components.

---

# Exam takeaway

Remember the following rule for the Professional Cloud DevOps Engineer exam:

If an application is exposed through a Google Cloud HTTP Load Balancer and the question asks for an appropriate Service Level Indicator for autoscaling, the expected answer is:

**Use the request metrics provided by the Google Cloud Load Balancer through Cloud Monitoring.**

Historically, this was implemented using the **Stackdriver Custom Metrics Adapter**, which explains why Answer C is the correct answer in the certification.