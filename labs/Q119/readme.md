COMMANDS
```
gcloud container clusters get-credentials liveness-demo-cluster `
    --zone europe-west1-b `
    --project devops-cert-labs-v4

#ONE TERMINAL
kubectl get pods -n liveness-demo -w

#ANOTHER TERMINAL
$env:KUBE_EDITOR="notepad"
kubectl edit deployment nginx-demo -n liveness-demo
#change / to /test
#watch that the pod restarts every minute because the path fails
<!-- nginx-demo-675db457c4-tbzkl   0/1     Completed           0          10m
nginx-demo-84f875dfcd-gnwx4   1/1     Running             1 (1s ago)   41s
nginx-demo-84f875dfcd-gnwx4   1/1     Running             2 (2s ago)   82s
nginx-demo-84f875dfcd-gnwx4   1/1     Running             3 (1s ago)   2m1s -->

#now lets change the path again to the correct form
```

# Q119 - Configure a Liveness Probe in Google Kubernetes Engine

```text
   ____ _  ________
  / __ \ |/ /____  |
 / / / /   /    / /
/ /_/ /   |    / /
\___\_/_/|_|   /_/

Google Professional Cloud DevOps Engineer
Lab Q119
```

## Overview

This lab demonstrates how to configure a **liveness probe** in a Google Kubernetes Engine (GKE) cluster.

A liveness probe allows Kubernetes to automatically detect when a container is unhealthy and restart it without requiring manual intervention. This improves application availability and follows Google Cloud best practices for self-healing workloads.

---

## Architecture

```text
                    Google Kubernetes Engine

                    +----------------------+
                    |     GKE Cluster      |
                    +----------+-----------+
                               |
                     +---------v---------+
                     |     Deployment    |
                     |       Nginx       |
                     +---------+---------+
                               |
                    HTTP Liveness Probe
                               |
                     GET /
                               |
                  Healthy -> Continue Running

                  Unhealthy -> Restart Pod
```

---

## Technologies Used

- Terraform
- Google Kubernetes Engine (GKE)
- Kubernetes Deployment
- Kubernetes Service
- HTTP Liveness Probe

---

## Resources Created

Terraform deploys the following resources:

- Required Google Cloud APIs
- GKE Standard Cluster
- Node Pool
- Kubernetes Namespace
- Nginx Deployment
- LoadBalancer Service
- HTTP Liveness Probe

---

## Liveness Probe Configuration

The deployment includes the following liveness probe:

```yaml
livenessProbe:
  httpGet:
    path: /
    port: 80
  initialDelaySeconds: 10
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3
```

Kubernetes periodically sends an HTTP request to the application.

If the endpoint stops responding successfully, Kubernetes automatically restarts the container.

---

## Deployment

Initialize Terraform:

```bash
terraform init
```

Review the execution plan:

```bash
terraform plan
```

Deploy the infrastructure:

```bash
terraform apply
```

---

## Configure kubectl

Download the cluster credentials:

```bash
gcloud container clusters get-credentials liveness-demo-cluster \
    --zone europe-west1-b \
    --project devops-cert-labs-v4
```

Verify the cluster:

```bash
kubectl get nodes
```

---

## Verify the Deployment

List the Pods:

```bash
kubectl get pods -n liveness-demo
```

List the Services:

```bash
kubectl get svc -n liveness-demo
```

---

## Test the Liveness Probe

Edit the deployment:

```bash
kubectl edit deployment nginx-demo -n liveness-demo
```

Modify the probe:

```yaml
path: /
```

to

```yaml
path: /path
```

Since the endpoint does not exist anymore, the HTTP probe fails.

Monitor the Pods:

```bash
kubectl get pods -n liveness-demo -w
```

You will observe that Kubernetes restarts the container automatically after the probe fails several times.

---

## Verify the Events

Display detailed Pod information:

```bash
kubectl describe pod <POD_NAME> -n liveness-demo
```

The Events section shows messages similar to:

```text
Warning  Unhealthy
Liveness probe failed

Normal  Killing
Container failed liveness probe, will be restarted
```

This confirms that Kubernetes detected the unhealthy container and restarted it automatically.

---

## Clean Up

Destroy all resources:

```bash
terraform destroy
```

---

## Conclusion

In this lab, a Google Kubernetes Engine cluster was deployed using Terraform together with a Kubernetes Deployment protected by an HTTP liveness probe.

After intentionally changing the health check endpoint, Kubernetes detected the failed health checks and automatically restarted the container without manual intervention.

This behavior demonstrates Kubernetes self-healing capabilities and follows Google's recommended practice for maintaining application availability when a container becomes unhealthy.