COMMANDS
```
gcloud container clusters get-credentials slo-cluster --zone europe-west1-b

kubectl get nodes

kubectl get ns

kubectl get deploy -n production

kubectl get pods -n production -o wide

kubectl get svc -n production

kubectl describe configmap service-slo -n production

kubectl get configmap service-slo -n production -o yaml

kubectl get endpoints -n production

kubectl rollout status deployment/demo-app -n production

kubectl get all -n production

$EXTERNAL_IP = kubectl get svc demo-service -n production -o jsonpath="{.status.loadBalancer.ingress[0].ip}"

echo $EXTERNAL_IP

curl.exe http://$EXTERNAL_IP

kubectl logs -n production deployment/demo-app --tail=20
```

# GCP Professional Cloud DevOps Engineer - Q84

## Goal

This lab simulates a Google Kubernetes Engine (GKE) environment where a microservice is deployed and monitored using the Site Reliability Engineering (SRE) concepts of **SLI**, **SLO**, and **Error Budget**.

The Terraform configuration does not create a real Cloud Monitoring SLO because that requires several additional Monitoring resources. Instead, it focuses on deploying the infrastructure and representing the exam concepts in a simple way.

---

# Exam Question

> Your team is running microservices in Google Kubernetes Engine (GKE). You want to detect consumption of an error budget to protect customers and define release policies. What should you do?

**Correct answer**

> **C. Create a SLO. Create an Alert Policy on `select_slo_burn_rate`.**

---

# Why C is Correct

The important keywords are:

- Error Budget
- Release Policies
- Burn Rate

An **SLI (Service Level Indicator)** is only a metric, such as availability, latency, or request success rate.

An **SLO (Service Level Objective)** defines the target value for an SLI.

Example:

- Availability SLI
- Objective: 99.9%

Once an SLO exists, Google Cloud automatically knows the allowed failure percentage.

That allowed failure percentage is called the **Error Budget**.

Cloud Monitoring also calculates the **SLO Burn Rate**, which measures how quickly the error budget is being consumed.

If the burn rate becomes too high:

- Alert Policies are triggered.
- Deployments can be paused.
- Release policies protect users until the service becomes stable again.

This is exactly what the question is asking.

---

# Why the Other Answers are Wrong

## A

Creating SLIs only creates measurements.

SLIs alone do not create an Error Budget because there is no objective defined.

Without an SLO there is no burn rate.

---

## B

Anthos Service Mesh provides useful metrics about microservices.

However, the question is about consuming an Error Budget and making release decisions.

Anthos Service Mesh does not replace SLO monitoring.

---

## D

Uptime Checks verify that an endpoint is reachable.

They are useful for availability monitoring but they do not measure Error Budget consumption.

The exam specifically asks about detecting Error Budget consumption, which requires monitoring the SLO Burn Rate.

---

# Terraform Architecture

## 1. Providers

Terraform uses:

- Google Provider
- Kubernetes Provider

The Google provider creates the cloud infrastructure.

The Kubernetes provider deploys resources inside the cluster.

---

## 2. APIs

The configuration enables the required Google Cloud APIs:

- Compute Engine API
- Kubernetes Engine API
- Service Usage API

These APIs are required before creating the cluster.

---

## 3. Network

A custom VPC is created together with a subnet.

The GKE cluster is attached to this network.

---

## 4. GKE Cluster

Terraform creates:

- One GKE cluster
- One managed node pool

This provides the Kubernetes environment used during the lab.

---

## 5. Kubernetes Namespace

A namespace called **production** is created.

All application resources are deployed inside this namespace.

---

## 6. Deployment

The deployment creates two replicas of the sample application.

The application image is:

```
nginxdemos/hello
```

This image simply returns an HTML page showing information about the pod that handled the request.

---

## 7. Service

A Kubernetes Service of type **LoadBalancer** exposes the application.

Google Cloud automatically creates an external load balancer and assigns a public IP address.

Requests sent to that IP are distributed across the running pods.

---

## 8. Simulated SLO

A ConfigMap called:

```
service-slo
```

stores information representing the monitoring configuration:

- SLI
- SLO
- Alert Policy
- Burn Rate

This ConfigMap is only used as a learning aid.

A production environment would use Cloud Monitoring Service Monitoring resources instead.

---

# Validation

After deployment you can verify:

```
terraform apply
```

Cluster status:

```
kubectl get nodes
```

Pods:

```
kubectl get pods -n production
```

Service:

```
kubectl get svc -n production
```

Endpoints:

```
kubectl get endpoints -n production
```

ConfigMap:

```
kubectl get configmap service-slo -n production -o yaml
```

Application:

```
curl http://<EXTERNAL_IP>
```

Logs:

```
kubectl logs deployment/demo-app -n production
```

---

# Key SRE Concepts

**SLI**

A metric describing service quality.

Examples:

- Availability
- Latency
- Error Rate

---

**SLO**

The desired target for an SLI.

Example:

99.9% availability.

---

**Error Budget**

The amount of failure allowed before violating the SLO.

Example:

99.9% SLO

↓

0.1% Error Budget

---

**Burn Rate**

The speed at which the Error Budget is being consumed.

A high Burn Rate indicates that the service is failing faster than expected.

Cloud Monitoring exposes this through:

```
select_slo_burn_rate
```

---

# Exam Tip

Remember this association:

| Exam Keyword | Think About |
|--------------|-------------|
| SLI | Measurement |
| SLO | Target |
| Error Budget | Allowed failures |
| Burn Rate | Error Budget consumption |
| Release Policies | Stop deployments when Burn Rate is too high |

If the question mentions **Error Budget**, **Burn Rate**, and **Release Policies**, the expected solution is almost always:

> **Create an SLO and configure an Alert Policy using `select_slo_burn_rate`.**