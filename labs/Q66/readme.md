COMMANDS
```
gcloud container clusters get-credentials development-cluster --zone europe-west1-b --project devops-cert-labs-v3
kubectl get all -n team-a
kubectl get all -n team-b
kubectl get networkpolicy -A
kubectl get role -A
kubectl get rolebinding -A
kubectl run test-a --image=busybox --restart=Never -n team-a -- sleep 3600
kubectl run test-b --image=busybox --restart=Never -n team-b -- sleep 3600

kubectl wait --for=condition=Ready pod/test-a -n team-a --timeout=120s
kubectl wait --for=condition=Ready pod/test-b -n team-b --timeout=120s

Write-Host ""
Write-Host "===== TEAM A -> TEAM A ====="
kubectl exec -n team-a test-a -- wget -qO- http://node:3000

Write-Host ""
Write-Host "===== TEAM B -> TEAM B ====="
kubectl exec -n team-b test-b -- wget -qO- http://node:3000

Write-Host ""
Write-Host "===== TEAM A -> TEAM B ====="
kubectl exec -n team-a test-a -- wget -T 5 -qO- http://node.team-b.svc.cluster.local:3000

Write-Host ""
Write-Host "===== TEAM B -> TEAM A ====="
kubectl exec -n team-b test-b -- wget -T 5 -qO- http://node.team-a.svc.cluster.local:3000

kubectl delete pod test-a -n team-a
kubectl delete pod test-b -n team-b
```

# Q66 - Kubernetes Multi-Team Isolation with RBAC and Network Policies

## Overview

In this lab, I deployed a Google Kubernetes Engine (GKE) cluster using Terraform and created an environment where two independent development teams could work inside the same Kubernetes cluster while remaining logically separated.

The objective was to simulate a real enterprise environment where multiple teams share the same infrastructure but should only manage their own applications and resources.

The lab combines several Kubernetes concepts, including namespaces, RBAC, services, deployments, ConfigMaps, Network Policies and Load Balancers.

---

# Architecture

The infrastructure contains:

- One GKE cluster
- One node pool with two worker nodes
- Namespace for Team A
- Namespace for Team B
- Redis application for each team
- Node.js application for each team
- NGINX reverse proxy for each team
- LoadBalancer Service for external access
- RBAC Roles and RoleBindings
- Network Policies
- Terraform outputs

Each team has exactly the same architecture but deployed inside its own namespace.

```
Internet
     |
LoadBalancer
     |
   NGINX
     |
 Node.js
     |
   Redis

Namespace: team-a


Internet
     |
LoadBalancer
     |
   NGINX
     |
 Node.js
     |
   Redis

Namespace: team-b
```

---

# Terraform Configuration

## Provider

Terraform uses both the Google and Kubernetes providers.

The Google provider creates the GKE infrastructure.

The Kubernetes provider connects directly to the Kubernetes API after the cluster has been created.

---

## GKE Cluster

The project creates a GKE cluster called:

- development-cluster

The default node pool is removed because a custom node pool is created separately.

The cluster is deployed in:

- europe-west1-b

---

## Node Pool

A dedicated node pool is created with:

- 2 nodes
- e2-small virtual machines
- Standard persistent disks
- Preemptible instances

This is enough to host all workloads while keeping infrastructure costs low.

---

## Namespaces

Two namespaces are created.

```
team-a
team-b
```

Namespaces provide logical separation between applications.

Resources inside one namespace are independent from resources in another namespace.

---

# Team Applications

Each namespace contains three components.

## Redis

Redis stores a simple counter.

Every request increases the counter by one.

---

## Node.js

The Node.js application connects to Redis.

When a request arrives, it increases the Redis counter and returns a message such as:

```
Team A - Hits: 15
```

or

```
Team B - Hits: 8
```

The application source code is stored inside a ConfigMap instead of building a Docker image.

When the container starts, it copies the files locally, installs dependencies with npm and starts the application.

---

## NGINX

NGINX acts as a reverse proxy.

External users connect to NGINX.

NGINX forwards every request to the internal Node.js service.

---

## Services

Each team has:

- Redis ClusterIP Service
- Node.js ClusterIP Service
- NGINX LoadBalancer Service

The LoadBalancer receives a public IP from Google Cloud, making each application accessible from the Internet.

---

# RBAC

Each namespace has its own Role.

The role allows operations such as:

- Create resources
- Delete resources
- Update resources
- Read resources

Permissions apply only inside the corresponding namespace.

RoleBindings assign those permissions to different users.

This prevents one development team from managing resources that belong to another namespace.

---

# Network Policies

A Network Policy is created for each namespace.

The objective is to control how Pods communicate with each other.

In this lab, the policy allows communication between Pods inside the same namespace.

A production environment would normally use stricter rules to block unnecessary traffic between namespaces.

---

# Outputs

Terraform returns useful information after deployment.

Examples include:

- Cluster name
- Cluster endpoint
- Team A namespace
- Team B namespace
- Team A LoadBalancer IP
- Team B LoadBalancer IP

These outputs make it easier to access and verify the environment.

---

# Validation

After deployment I verified that:

- The GKE cluster was running correctly.
- Both namespaces existed.
- Every deployment was healthy.
- Redis, Node.js and NGINX Pods were running.
- Services were correctly created.
- LoadBalancer IP addresses were assigned.
- Both applications were reachable from the browser.

The applications returned responses similar to:

```
Team A - Hits: 4
```

and

```
Team B - Hits: 4
```

showing that each team maintained its own independent Redis database.

---

# Exam Question

**Your company has several development teams sharing the same Kubernetes cluster. Each team must deploy and manage only its own applications while remaining isolated from the others. What should you do?**

**A.** Create separate Compute Engine virtual machines for every team.

**B.** Use only namespaces.

**C.** Give every developer cluster-admin permissions.

**D.** Use namespaces together with RBAC and Network Policies.

**Correct answer: D**

---

# Why D is Correct

Namespaces provide logical separation between teams.

However, namespaces alone do not enforce security.

RBAC defines which users are allowed to manage resources inside each namespace.

Network Policies control how Pods communicate across the cluster.

Together, these three features provide isolation, access control and network security, which is the recommended Kubernetes design.

---

# Why B is Incorrect

Namespaces only organize resources.

They do not prevent users from accessing other namespaces if permissions are too broad.

They also do not restrict network communication between Pods.

Without RBAC and Network Policies, namespaces are only a logical grouping mechanism and do not provide complete isolation.

---

# Key Exam Takeaways

For the Professional Cloud DevOps Engineer exam, remember these ideas:

- Use namespaces to organize workloads.
- Use RBAC to control user permissions.
- Use Network Policies to restrict Pod communication.
- Use Services for internal communication.
- Use LoadBalancers to expose applications externally.
- Multiple teams can safely share one Kubernetes cluster when these features are combined.

When an exam question mentions **multi-team Kubernetes environments**, **shared clusters**, **team isolation**, **least privilege**, or **namespace security**, the expected solution is almost always:

**Namespaces + RBAC + Network Policies**