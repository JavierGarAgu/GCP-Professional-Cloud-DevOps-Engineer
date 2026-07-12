# Google Cloud Professional Cloud DevOps Engineer Lab

# Question - Reducing Network Costs with Standard Network Tier

---

## Introduction

This repository contains a small hands-on lab created while preparing for the **Google Cloud Professional Cloud DevOps Engineer** certification.

The goal of this lab is not to build a production-ready application. Instead, it demonstrates one of the networking concepts frequently tested in the certification exam.

The lab deploys a simple web application on **Google Kubernetes Engine (GKE)** exposed through a **LoadBalancer Service**.

The objective is understanding how the **Google Cloud Network Service Tier** affects networking costs.

---

# Exam Question

> You support the backend of a mobile phone game that runs on a Google Kubernetes Engine (GKE) cluster. The application is serving HTTP requests from users.
>
> You need to implement a solution that will reduce the network cost.
>
> **What should you do?**

### A

Configure the VPC as a Shared VPC Host project.

### B ✅

Configure your network services on the Standard Tier.

### C

Configure your Kubernetes cluster as a Private Cluster.

### D

Configure a Google Cloud HTTP Load Balancer as Ingress.

---

# Why is B correct?

The question is **not** asking about security, network organization, or load balancing.

The objective is **reducing networking costs**.

Google Cloud offers two different network service tiers:

* **Premium Tier**
* **Standard Tier**

Premium Tier uses Google's private global backbone to carry traffic across the world, providing lower latency and higher performance.

Standard Tier routes traffic through regional ISP networks much earlier.

Because it does not rely on Google's premium global network, it is **less expensive**.

Nothing changes for the application itself.

The application still runs on GKE.

Users still access the same service.

Only the network tier changes.

---

# Why are the other answers incorrect?

### A - Shared VPC

Shared VPC centralizes network administration across multiple Google Cloud projects.

It improves governance and simplifies network management.

It **does not reduce networking costs**.

---

### C - Private Cluster

A Private GKE Cluster removes public IP addresses from worker nodes.

This improves security.

However, external users still reach the application through a Load Balancer.

The networking cost remains essentially unchanged.

---

### D - HTTP Load Balancer as Ingress

Ingress provides Layer 7 routing, SSL termination, and URL-based routing.

It improves application delivery.

It **does not reduce networking costs**.

In many cases, HTTP(S) Load Balancers use the Premium Tier by default.

---

# Lab Architecture

```
                     Internet Users
                            │
                            ▼
                External LoadBalancer Service
                            │
             Standard / Premium Network Tier
                            │
                            ▼
                     Google Kubernetes Engine
                            │
                     Kubernetes Service
                            │
                            ▼
                       Backend Deployment
```

---

# Infrastructure

Terraform creates:

* Custom VPC
* Subnetwork
* GKE Cluster
* Node Pool
* Kubernetes Namespace
* Backend Deployment
* Kubernetes LoadBalancer Service
* Regional Static IP configured with Standard Tier

The infrastructure is intentionally small because the objective is understanding how the Network Tier affects cost rather than building a production environment.

---

# Standard Network Tier

The LoadBalancer Service is configured to use the **Standard Network Tier**.

The static external IP is also created using:

```
network_tier = "STANDARD"
```

This configuration reduces networking costs while keeping the application publicly accessible.

---

# Premium Network Tier

To compare both configurations, the lab can also be deployed using:

```
network_tier = "PREMIUM"
```

and

```
cloud.google.com/network-tier = "Premium"
```

The application continues working exactly the same.

Only the underlying Google Cloud network changes.

---

# Lab Steps

## 1. Deploy the infrastructure

```powershell
terraform init

terraform apply -auto-approve
```

Terraform creates the complete GKE environment.

---

## 2. Configure kubectl

```powershell
gcloud container clusters get-credentials network-tier-lab `
    --zone europe-west1-b `
    --project devops-cert-labs
```

This downloads the cluster credentials into your local kubeconfig.

---

## 3. Verify the deployment

Check the Pods:

```powershell
kubectl get pods -n production
```

Example:

```
NAME                               READY   STATUS    RESTARTS
mobile-game-backend-xxxxx          1/1     Running   0
```

---

## 4. Verify the LoadBalancer

```powershell
kubectl get svc -n production
```

Example:

```
NAME      TYPE           EXTERNAL-IP
backend   LoadBalancer   34.xxx.xxx.xxx
```

The application is now publicly accessible.

---

## 5. Verify the Network Tier

```powershell
gcloud compute addresses describe backend-ip `
    --region=europe-west1
```

Expected output:

```
networkTier: STANDARD
```

This confirms that the LoadBalancer uses the Standard Network Tier.

---

# Compare with Premium Tier

Modify the Terraform configuration:

```
network_tier = "PREMIUM"
```

and

```
cloud.google.com/network-tier = "Premium"
```

Apply the changes:

```powershell
terraform apply -auto-approve
```

Verify again:

```powershell
gcloud compute addresses describe backend-ip `
    --region=europe-west1
```

Now the output should show:

```
networkTier: PREMIUM
```

The application still works exactly the same.

Only the underlying Google Cloud network has changed.

---

# Why is Standard Tier useful?

Premium Tier provides:

* Lower latency
* Google's global backbone
* Better worldwide performance

Standard Tier provides:

* Lower networking cost
* Regional routing
* Suitable for applications that prioritize cost over global performance

The exam specifically asks how to **reduce network cost**.

Therefore, Standard Tier is the correct solution.

---

# Google Cloud Services Used

* Google Kubernetes Engine (GKE)
* VPC
* Compute Engine Static IP
* Kubernetes
* Terraform

---

# Concepts Practiced

* Infrastructure as Code
* Google Kubernetes Engine
* Kubernetes Services
* External Load Balancer
* Google Cloud Networking
* Standard Network Tier
* Premium Network Tier
* Cost Optimization

---

# What I Learned

After completing this lab I better understand why the correct answer is **B**.

Changing the Network Service Tier does not require modifying the application or the Kubernetes cluster.

The backend, deployments, services, and LoadBalancer remain exactly the same.

Only the Google Cloud networking layer changes.

Standard Tier offers lower networking costs by routing traffic through regional ISP networks instead of Google's global premium backbone.

---

# Conclusion

This is a very small lab, but it demonstrates an important networking concept frequently tested in the Google Cloud Professional Cloud DevOps Engineer certification.

The key is understanding the objective of the question.

It is **not** asking about security.

It is **not** asking about network architecture.

It is **not** asking about application availability.

It simply asks how to **reduce network costs**.

Among all the available options, configuring network services to use the **Standard Network Tier** is the only solution specifically designed for that purpose.

---

## Verification

```powershell
terraform init

terraform apply -auto-approve

gcloud container clusters get-credentials network-tier-lab `
    --zone europe-west1-b `
    --project devops-cert-labs

kubectl get pods -n production

kubectl get svc -n production

gcloud compute addresses describe backend-ip `
    --region=europe-west1

terraform destroy -auto-approve
```