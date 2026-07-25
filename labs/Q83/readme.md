Download https://sourceforge.net/projects/istio.mirror/files/1.30.3/istioctl-1.30.3-win.zip/download



COMMANDS
```
gcloud config set project devops-cert-labs-v3

gcloud container clusters get-credentials asm-cluster --zone europe-west1-b

$EXTERNAL_IP = terraform output -raw external_ip

.\istioctl.exe install --set profile=demo -y

kubectl label namespace production istio-injection=enabled --overwrite

kubectl rollout restart deployment app-v1 -n production

kubectl rollout restart deployment app-v2 -n production

kubectl apply -f .\anthos.yaml

kubectl get destinationrule -n production

kubectl get virtualservice -n production
```

# README

## Exam Question

**Question**

> Your organization has a containerized web application that runs on-premises. As part of the migration plan to Google Cloud, you need to select a deployment strategy and platform that meets the following acceptance criteria:
>
> 1. The platform must be able to direct traffic from Android devices to an Android-specific microservice.
> 2. The platform must allow arbitrary percentage-based traffic splitting.
> 3. The deployment strategy must allow continuous testing of multiple versions of any microservice.
>
> **Correct answer:** **D**
>
> Deploy the application to **Google Kubernetes Engine (GKE)** with **Anthos Service Mesh**. Use a **VirtualService** to route Android traffic based on the **User-Agent** header and perform **90/10 traffic splitting** between application versions.

---

# Why Option D?

The key point of the question is not Kubernetes itself. The important technology is **Anthos Service Mesh**, which is Google's managed implementation of **Istio**.

A standard Kubernetes Service can distribute traffic across Pods, but it cannot easily perform advanced routing based on HTTP headers or arbitrary traffic percentages.

Anthos Service Mesh extends Kubernetes networking with intelligent traffic management.

This allows engineers to:

* Route traffic according to HTTP headers.
* Perform Canary deployments.
* Perform Blue/Green deployments.
* Split traffic using custom percentages.
* Test multiple application versions simultaneously.

These are exactly the requirements described in the exam question.

---

# Project Architecture

```
Internet
     │
     ▼
LoadBalancer Service
     │
     ▼
VirtualService
     │
     ├──────── Android User-Agent ───────► app-v2
     │
     └──────── Other Clients
                 │
                 ├── 90% ───────────────► app-v1
                 └── 10% ───────────────► app-v2
```

The VirtualService is responsible for all routing decisions.

---

# Terraform Structure

This Terraform project intentionally keeps the infrastructure as simple as possible while reproducing the exam scenario.

## Google Provider

The provider configures the Google Cloud project and region used by Terraform.

```terraform
provider "google" {

  project = "devops-cert-labs-v3"

  region = "europe-west1"

}
```

---

## Required APIs

Terraform enables only the APIs required for GKE.

* Compute Engine API
* Kubernetes Engine API
* Service Usage API

---

## Network

A custom VPC and subnet are created.

```
VPC
 └── Subnet
      └── GKE Cluster
```

This avoids using Google's default network.

---

## GKE Cluster

Terraform creates a minimal Kubernetes cluster.

```
GKE Cluster

└── Node Pool

    └── Worker Node
```

Only one node is required because this is a demonstration environment.

---

## Namespace

A dedicated namespace called **production** isolates the application resources.

```
production

├── app-v1

├── app-v2

└── demo-service
```

---

## Application Deployments

Two independent Deployments are created.

```
app-v1

labels:

    app=demo

    version=v1
```

```
app-v2

labels:

    app=demo

    version=v2
```

The **version** label is extremely important because Istio uses it to identify each subset.

---

## Kubernetes Service

A LoadBalancer Service exposes both application versions.

```
LoadBalancer

↓

demo-service

↓

app-v1

app-v2
```

At this point Kubernetes simply distributes requests between available Pods.

No intelligent routing exists yet.

---

# Anthos Service Mesh

The intelligent routing is implemented after Terraform finishes.

Since Anthos Service Mesh is based on Istio, this lab installs Istio locally to reproduce exactly the same behavior.

Two resources are created.

---

## DestinationRule

The DestinationRule defines the available application subsets.

```
Subset v1

↓

version=v1
```

```
Subset v2

↓

version=v2
```

Without this resource, the VirtualService cannot reference different versions.

---

## VirtualService

The VirtualService defines the routing policy.

### Android Devices

```
User-Agent contains Android

↓

app-v2
```

Android users are always redirected to version 2.

---

### Other Clients

```
90%

↓

app-v1
```

```
10%

↓

app-v2
```

This reproduces a classic Canary deployment.

Only a small percentage of users receive the new version.

---

# Why Istio?

Without Istio:

```
Client

↓

Kubernetes Service

↓

Pods
```

Kubernetes performs basic load balancing.

It cannot easily answer questions such as:

* Send Android users to version 2.
* Send Premium users to version 2.
* Send 10% of traffic to a Canary release.

---

With Istio:

```
Client

↓

VirtualService

↓

Routing Rules

↓

Pods
```

Traffic is controlled using policies instead of application code.

The application itself never needs to know which version receives each request.

---

# PowerShell Commands

Load the Kubernetes credentials.

```powershell
gcloud config set project devops-cert-labs-v3

gcloud container clusters get-credentials asm-cluster --zone europe-west1-b
```

Retrieve the external IP created by Terraform.

```powershell
$EXTERNAL_IP = terraform output -raw external_ip
```

Install Istio.

```powershell
.\istioctl.exe install --set profile=demo -y
```

Enable automatic sidecar injection.

```powershell
kubectl label namespace production istio-injection=enabled --overwrite
```

Restart both Deployments so Istio injects the Envoy proxy.

```powershell
kubectl rollout restart deployment app-v1 -n production

kubectl rollout restart deployment app-v2 -n production
```

Deploy the routing configuration.

```powershell
kubectl apply -f .\anthos.yaml
```

Verify the resources.

```powershell
kubectl get destinationrule -n production

kubectl get virtualservice -n production
```

---

# Key Exam Takeaways

* GKE provides the Kubernetes platform.
* Anthos Service Mesh adds advanced traffic management.
* Anthos Service Mesh is based on Istio.
* A Kubernetes Service performs basic load balancing.
* A VirtualService performs intelligent traffic routing.
* A DestinationRule defines application subsets such as **v1** and **v2**.
* Traffic can be routed according to HTTP headers such as **User-Agent**.
* Traffic can be split using arbitrary percentages.
* Canary deployments become simple because multiple application versions can run simultaneously.
* The correct answer is **Option D** because only **GKE + Anthos Service Mesh** satisfies all three requirements: header-based routing, percentage-based traffic splitting, and continuous testing of multiple microservice versions.
