COMMANDS
```
kubectl get deployment -n warehouse

kubectl scale deployment warehouse-consumer --replicas=5 -n warehouse

kubectl get deployment warehouse-consumer -n warehouse

kubectl get pods -n warehouse -w
```

# Q93 - Scale GKE Autopilot Pods to Process More Orders

## Exam Question

You are the on-call Site Reliability Engineer for a microservice that is deployed to a Google Kubernetes Engine (GKE) Autopilot cluster.

Your company runs an online store that publishes order messages to Pub/Sub, and a microservice receives these messages and updates stock information in the warehouse system.

A sales event caused a large increase in orders. The warehouse system cannot process updates quickly enough, so products that are already out of stock are still being sold.

You compare the microservice metrics with normal values.

What should you do?

- A. Decrease the acknowledgment deadline on the subscription.
- B. Add a virtual queue to the online store.
- C. Increase the number of Pod replicas.
- D. Increase the Pod CPU and memory limits.

**Correct answer: C**

---

# Architecture

```
                    High Traffic
                         │
                         ▼
                +----------------+
                |  Online Store  |
                +----------------+
                         │
                         ▼
                   +-----------+
                   |  Pub/Sub  |
                   +-----------+
                         │
                         ▼
        +--------------------------------+
        |      GKE Autopilot Cluster      |
        |                                |
        | Deployment                     |
        | warehouse-consumer             |
        | replicas = 1                   |
        +---------------+----------------+
                        │
                        ▼
              Warehouse System
```

After scaling:

```
                    High Traffic
                         │
                         ▼
                +----------------+
                |  Online Store  |
                +----------------+
                         │
                         ▼
                   +-----------+
                   |  Pub/Sub  |
                   +-----------+
                         │
                         ▼
        +----------------------------------------+
        |        GKE Autopilot Cluster           |
        |                                        |
        | Deployment                             |
        | warehouse-consumer                     |
        | replicas = 5                           |
        |                                        |
        | Pod 1                                 |
        | Pod 2                                 |
        | Pod 3                                 |
        | Pod 4                                 |
        | Pod 5                                 |
        +----------------+-----------------------+
                         │
                         ▼
                 Warehouse System
```

---

# Request Flow

```
Orders
   │
   ▼
Pub/Sub
   │
   ▼
Consumer Pods
   │
   ▼
Warehouse Database
```

More Pods means more consumers working at the same time.

---

# main.tf Explanation

## Providers

The configuration uses two providers.

- Google Provider
- Kubernetes Provider

The Google provider creates Google Cloud resources.

The Kubernetes provider deploys resources inside the GKE cluster.

---

## Required APIs

Terraform enables only the required APIs.

- Google Kubernetes Engine API
- Pub/Sub API

---

## Pub/Sub

Terraform creates:

- One topic
- One subscription

The topic represents incoming customer orders.

The subscription is used by the warehouse microservice.

---

## GKE Autopilot Cluster

Terraform creates a GKE Autopilot cluster.

```text
warehouse-cluster
```

Autopilot automatically manages:

- Nodes
- Operating system
- Upgrades
- Node scaling

You only manage Kubernetes workloads.

---

## Namespace

A dedicated namespace is created.

```text
warehouse
```

This separates the application from other workloads.

---

## Deployment

Terraform creates a Deployment named:

```text
warehouse-consumer
```

The Deployment initially runs:

```text
replicas = 1
```

Only one Pod processes requests.

During a traffic spike, this single Pod becomes the bottleneck.

Increasing the number of replicas allows Kubernetes to run multiple Pods in parallel.

---

## Service

A ClusterIP Service exposes the Deployment inside the cluster.

It allows internal communication between Kubernetes resources.

---

# Why Option C Is Correct

The problem is not Pub/Sub.

The problem is that only one Pod is processing incoming work.

Adding more replicas creates more consumers.

This increases throughput and reduces the processing backlog.

---

# Why Option A Is Incorrect

Changing the acknowledgment deadline does not increase processing capacity.

Messages may even be delivered multiple times if the deadline is too short.

---

# Why Option B Is Incorrect

Pub/Sub already provides queue functionality.

Adding another queue only increases complexity.

It does not increase processing speed.

---

# Why Option D Is Incorrect

Increasing CPU and memory may improve the performance of one Pod.

However, the scenario requires processing more requests simultaneously.

Horizontal scaling is the recommended solution.

---

# Manual Scaling

Initial Deployment

```
warehouse-consumer

Replicas: 1
```

Scale the application

```bash
kubectl scale deployment warehouse-consumer --replicas=5 -n warehouse
```

Result

```
warehouse-consumer

Replicas: 5
```

Kubernetes creates four additional Pods.

---

# Verification Commands

Deploy the infrastructure

```bash
terraform init

terraform apply -auto-approve
```

Connect to the cluster

```bash
gcloud container clusters get-credentials warehouse-cluster \
--region=europe-west1 \
--project=devops-cert-labs-v3
```

Check the Deployment

```bash
kubectl get deployment -n warehouse
```

Scale the Deployment

```bash
kubectl scale deployment warehouse-consumer --replicas=5 -n warehouse
```

Verify the new replicas

```bash
kubectl get deployment warehouse-consumer -n warehouse

kubectl get pods -n warehouse
```

---

# Key Takeaways

- GKE Autopilot manages the infrastructure automatically.
- Deployments control the number of running Pods.
- A traffic spike can overload a single Pod.
- Increasing Pod replicas is horizontal scaling.
- Horizontal scaling increases throughput.
- This is the recommended solution for processing more Pub/Sub messages.
- The correct answer is **C**.