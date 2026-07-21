COMMANDS
```
terraform fmt
terraform validate
terraform apply

$IP = terraform output -raw application_external_ip

echo $IP

1..200 | ForEach-Object {
    Invoke-WebRequest "http://$IP" -UseBasicParsing
}

gcloud logging read `
'resource.type="k8s_container" AND resource.labels.namespace_name="production"' `
--freshness=10m `
--limit=20 `
--format="value(textPayload)"

$SINK = terraform output -raw log_sink_name

gcloud logging sinks describe $SINK

$BUCKET = terraform output -raw log_archive_bucket

gcloud storage buckets get-iam-policy gs://$BUCKET

gcloud storage ls --recursive --long gs://$BUCKET

gcloud storage buckets describe gs://$BUCKET

1..1000 | ForEach-Object {
    Invoke-WebRequest "http://$IP" -UseBasicParsing | Out-Null
}

#Start-Sleep -Seconds 600

gcloud storage ls --recursive --long gs://$BUCKET
```

# Q62 - Cloud Logging Sink and Seven-Year Log Archive with Cloud Storage

## Overview

This lab is based on question Q1 from the Google Cloud Professional Cloud DevOps Engineer exam preparation.

The objective of this scenario is to archive application logs for seven years while minimizing storage costs and reducing operational complexity.

The requirement comes from a government agency that needs to keep application logs for a long period of time for compliance reasons.

The correct answer for the exam question is:

**D. Create a sink in Stackdriver (Cloud Logging), create a Cloud Storage bucket for storing archived logs, and select the bucket as the log export destination.**

This lab implements this architecture using Terraform, Google Kubernetes Engine (GKE), Cloud Logging, Log Router sinks, IAM permissions, and Cloud Storage.

---

# Exam Question Analysis

## Question

You are working with a government agency that requires you to archive application logs for seven years.

You need to configure Stackdriver to export and store the logs while minimizing costs of storage.

What should you do?

---

# Answer Analysis

## Option A

Create a Cloud Storage bucket and develop your application to send logs directly to the bucket.

Incorrect.

The application should not be responsible for managing log storage.

This creates unnecessary development complexity and increases operational maintenance.

Applications should only generate logs. Google Cloud services should handle log collection and routing.

---

## Option B

Develop an App Engine application that pulls logs from Stackdriver and saves them in BigQuery.

Incorrect.

BigQuery is designed for analytics and querying large datasets.

For long-term log retention, Cloud Storage is cheaper and more appropriate, especially with Archive storage classes.

---

## Option C

Create an export in Stackdriver and configure Cloud Pub/Sub to store logs in permanent storage.

Incorrect.

Pub/Sub is useful when logs need to be processed in real time by another system.

However, adding Pub/Sub increases complexity and is unnecessary when the only requirement is long-term storage.

---

## Option D

Create a sink in Stackdriver, create a Cloud Storage bucket for storing archived logs, and select the bucket as the log export destination.

Correct.

Cloud Logging sinks are designed to route logs automatically to different destinations.

The architecture becomes:

Application

↓

GKE Container Logs

↓

Cloud Logging

↓

Logging Sink

↓

Cloud Storage Archive Bucket

↓

Seven Years Retention

This solution minimizes storage costs and reduces operational effort.

---

# Lab Architecture

The infrastructure created in this lab is:

```
User
 |
 v
External LoadBalancer
 |
 v
Nginx
 |
 v
Node.js Application
 |
 v
Redis

Node.js Logs
 |
 v
GKE Container Logging
 |
 v
Cloud Logging
 |
 v
Log Router Sink
 |
 v
Cloud Storage Archive Bucket
 |
 v
7 Year Retention
```

The main components are:

- Google Kubernetes Engine cluster
- Kubernetes namespace
- Node.js application
- Redis backend
- Nginx reverse proxy
- Cloud Logging
- Cloud Logging sink
- Cloud Storage Archive bucket
- IAM permissions

---

# Terraform Implementation

## Provider Configuration

Terraform uses:

- Google Provider
- Kubernetes Provider

The Google Cloud project:

```
devops-cert-labs-v2
```

The region:

```
europe-west1
```

Terraform manages both Google Cloud resources and Kubernetes resources.

---

# GKE Cluster

The first part of the Terraform file creates the Kubernetes cluster.

Cluster name:

```
node-observability-lab
```

Location:

```
europe-west1-b
```

The default node pool is removed and replaced with a custom node pool.

Configuration:

- Machine type: e2-small
- Disk type: pd-standard
- Disk size: 20GB
- Nodes: 1
- Preemptible nodes enabled

The objective is to create a small and cheap environment for testing observability.

---

# Kubernetes Application

The lab deploys a simple Node.js application.

The application:

- Runs inside Kubernetes.
- Uses Redis as a backend.
- Generates logs on every request.
- Exposes port 3000.

Example generated logs:

```
Request received successfully. Hits=200
```

The traffic flow:

```
Client

↓

Nginx Service

↓

Node.js Container

↓

Redis Service
```

---

# Nginx Reverse Proxy

Nginx is deployed as a public LoadBalancer service.

Its responsibility is:

- Receive external traffic.
- Forward requests to the Node.js application.

The user accesses:

```
External IP
```

and Nginx forwards traffic internally to:

```
node:3000
```

---

# Cloud Storage Archive Bucket

A Cloud Storage bucket is created to store exported logs.

Terraform resource:

```
google_storage_bucket
```

Configuration:

Bucket name:

```
application-logs-archive-devops-cert
```

Location:

```
EU
```

Storage class:

```
ARCHIVE
```

Uniform bucket-level access:

```
Enabled
```

The Archive storage class is used because logs are stored for a long period and are rarely accessed.

This reduces storage costs.

---

# Seven-Year Retention Policy

The bucket contains a retention policy.

Terraform configuration:

```
retention_period = 220752000
```

The value is calculated in seconds:

```
7 years = 220752000 seconds
```

The retention policy prevents deletion or modification of archived logs before the required compliance period.

---

# Cloud Logging Sink

The most important resource in this lab is the Cloud Logging sink.

Terraform resource:

```
google_logging_project_sink
```

The sink name:

```
application-log-archive-sink
```

The sink filters Kubernetes container logs:

```
resource.type="k8s_container"

resource.labels.namespace_name="production"
```

The destination is:

```
Cloud Storage bucket
```

The sink creates a dedicated writer identity:

```
serviceAccount:
service-944392114661@gcp-sa-logging.iam.gserviceaccount.com
```

---

# IAM Permissions

The Cloud Logging sink requires permission to create objects inside the bucket.

Terraform grants:

```
roles/storage.objectCreator
```

to the sink writer identity.

Without this permission:

```
Cloud Logging

X

Cloud Storage
```

The export would fail.

---

# Deployment Procedure

## Format Terraform

Run:

```
terraform fmt
```

---

## Validate Terraform

Run:

```
terraform validate
```

---

## Deploy Infrastructure

Run:

```
terraform apply
```

Terraform creates:

- GKE cluster
- Kubernetes workloads
- LoadBalancer
- Cloud Storage bucket
- Logging sink
- IAM permissions

---

# Testing the Application

Get the external IP:

```
$IP = terraform output -raw application_external_ip
```

Generate traffic:

```
1..200 | ForEach-Object {
    Invoke-WebRequest "http://$IP" -UseBasicParsing
}
```

The application generates logs that are collected by Cloud Logging.

---

# Verify Cloud Logging

Command:

```
gcloud logging read `
'resource.type="k8s_container" AND resource.labels.namespace_name="production"' `
--freshness=10m `
--limit=20 `
--format="value(textPayload)"
```

Expected output:

```
Request received successfully. Hits=150
Request received successfully. Hits=151
```

This confirms that Kubernetes logs are reaching Cloud Logging.

---

# Verify Logging Sink

Get sink name:

```
$SINK = terraform output -raw log_sink_name
```

Check sink:

```
gcloud logging sinks describe $SINK
```

Expected:

```
destination:
storage.googleapis.com/application-logs-archive-devops-cert
```

---

# Verify IAM Permissions

Get bucket name:

```
$BUCKET = terraform output -raw log_archive_bucket
```

Check bucket IAM:

```
gcloud storage buckets get-iam-policy gs://$BUCKET
```

Expected:

```
roles/storage.objectCreator
```

with the Cloud Logging service account.

---

# Verify Archived Logs

Cloud Logging exports logs asynchronously.

Check Cloud Storage:

```
gcloud storage ls --recursive --long gs://$BUCKET
```

Example result:

```
gs://application-logs-archive-devops-cert/stderr/2026/07/21/18:00:00_18:59:59_S0.json
```

This confirms that logs are successfully archived.

---

# Verify Retention Policy

Command:

```
gcloud storage buckets describe gs://$BUCKET
```

Expected:

```
retentionPeriod:
220752000
```

This confirms seven-year retention.

---

# Final Result

The lab successfully implements the recommended Google Cloud architecture.

The final workflow is:

```
Application

↓

GKE Container Logs

↓

Cloud Logging

↓

Log Sink

↓

Cloud Storage Archive Bucket

↓

Seven Years Retention
```

The main lesson for the Professional Cloud DevOps Engineer exam is:

When you need long-term log storage, use Cloud Logging sinks to route logs to Cloud Storage.

Do not make applications manage log storage directly.

Cloud Logging + Log Sink + Cloud Storage Archive is the recommended solution because it provides:

- Low operational overhead.
- Lower storage cost.
- Secure IAM control.
- Long-term compliance retention.