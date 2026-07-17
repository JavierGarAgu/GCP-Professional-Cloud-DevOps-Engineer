COMMANDS

```
# Test
curl $(terraform output -raw application_url)

# Generate traffic
1..1000 | % { curl $(terraform output -raw application_url) > $null }

# Check logs
gcloud logging read "textPayload:CACHE_MISS" --limit=20

# Describe metric
gcloud logging metrics describe cache_miss_count
```

# Q36 - Visualize Cache Misses with Logs-Based Metrics

## Question

You support an application that stores product information in cached memory. For every cache miss, an entry is logged in Cloud Logging. You want to visualize how often a cache miss happens over time.

**Correct answer: C**

> Create a logs-based metric in Cloud Logging and a dashboard for that metric in Cloud Monitoring.

---

# Why Answer C Is Correct

Every cache miss is already written to **Cloud Logging**, so the best solution is to convert those log entries into a metric.

A **logs-based metric** counts every log that matches a filter. Cloud Monitoring can then display this metric in a dashboard, allowing engineers to visualize cache misses over time.

This solution is fully managed, updates automatically, and follows Google Cloud observability best practices.

---

# Why the Other Answers Are Incorrect

### A. Link Cloud Logging to Looker Studio

Looker Studio is mainly used for reporting and analytics. Although it can display log data, it is not designed for operational monitoring or near real-time dashboards.

---

### B. Use Cloud Profiler

Cloud Profiler analyzes CPU and memory usage inside applications. It does not process application logs or count cache misses.

---

### D. Export logs to BigQuery

BigQuery is useful for long-term analytics and historical reporting, but creating scheduled queries adds unnecessary complexity. Cloud Logging already provides logs-based metrics for this purpose.

---

# Laboratory Overview

This lab demonstrates how to monitor cache misses using Google Kubernetes Engine, Cloud Logging, and Cloud Monitoring.

A Flask application was deployed to GKE. Every request randomly generates a cache miss, and the application writes the message:

```

CACHE\_MISS

```

to the container logs.

Cloud Logging automatically collects these logs.

A logs-based metric filters every log containing `CACHE_MISS`, and Cloud Monitoring displays the metric in a dashboard.

The architecture is:

```

User
|
v
Load Balancer
|
v
GKE Service
|
v
Flask Application
|
v
Cloud Logging
|
v
Logs-Based Metric
|
v
Cloud Monitoring Dashboard

```

---

# Terraform Structure

## Providers

The configuration uses the Google and Kubernetes providers.

The Google provider creates Google Cloud resources, while the Kubernetes provider deploys objects inside the GKE cluster.

---

## Enable APIs

Terraform enables the required APIs:

- Container API
- Cloud Logging API
- Cloud Monitoring API

These services are required before creating the cluster and monitoring resources.

---

## GKE Cluster

A Google Kubernetes Engine cluster is created in **europe-west1-b**.

The default node pool is removed and replaced with a custom node pool using a small preemptible virtual machine.

---

## Namespace

A dedicated Kubernetes namespace called **production** is created to isolate the application resources.

---

## Flask Application

The application source code is stored inside a Kubernetes ConfigMap.

The Flask application simulates cache behavior.

For approximately one out of every three requests it writes:

```

CACHE\_MISS

```

to standard output.

Since GKE automatically sends container logs to Cloud Logging, no additional logging configuration is required.

---

## Deployment

A Kubernetes Deployment creates one application replica.

The container uses the official Python image, installs Flask, loads the application from the ConfigMap, and starts the web server.

---

## Service

A Kubernetes LoadBalancer Service exposes the application to the Internet.

Terraform outputs the public IP address and URL after deployment.

---

## Logs-Based Metric

Terraform creates a Cloud Logging metric called:

```

cache\_miss\_count

```

The metric only counts log entries that satisfy this filter:

- Kubernetes container
- Production namespace
- Text contains `CACHE_MISS`

Each matching log increases the metric value.

---

## Monitoring Dashboard

Terraform creates a Cloud Monitoring dashboard.

The dashboard displays a line chart using the logs-based metric:

```

logging.googleapis.com/user/cache\_miss\_count

```

This allows engineers to observe cache miss frequency over time.

---

# Validation

The deployment was validated using the following steps:

- Deploy the infrastructure with Terraform.
- Access the application through the Load Balancer.
- Generate many HTTP requests.
- Verify that `CACHE_MISS` entries appear in Cloud Logging.
- Verify that the logs-based metric exists.
- Open the Monitoring dashboard and observe the metric visualization.

---

# Result

The laboratory successfully demonstrates Google's recommended solution for monitoring cache misses.

Instead of exporting logs or using external analytics tools, Cloud Logging transforms log entries into a metric that Cloud Monitoring visualizes in a dashboard.

This approach is scalable, simple, and follows Google Cloud observability best practices.

