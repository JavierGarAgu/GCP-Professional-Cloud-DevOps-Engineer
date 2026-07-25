COMMANDS

```
gcloud container clusters get-credentials observability-cluster --zone europe-west1-b
$LB = (kubectl get svc nginx -n production -o jsonpath="{.status.loadBalancer.ingress[0].ip}")

Write-Host "Load Balancer: $LB"

1..10 | ForEach-Object {
    try {
        (Invoke-WebRequest -Uri "http://$LB" -UseBasicParsing -TimeoutSec 10).Content
    }
    catch {
        $_.Exception.Message
    }
}

kubectl logs deployment/otel-collector -n production --tail=50
```

# Q74 - Distributed Tracing with OpenTelemetry on Google Kubernetes Engine

## Overview

This lab demonstrates how to implement distributed tracing in a Kubernetes application running on Google Kubernetes Engine (GKE). The infrastructure is fully deployed with Terraform and includes a multi-tier application composed of NGINX, a Node.js backend, Redis, and an OpenTelemetry Collector.

The purpose of the lab is to show how distributed tracing helps identify latency across multiple services by automatically generating and exporting traces.

---

## Exam Question

**Question**

You are responsible for a production application composed of multiple microservices running on Google Kubernetes Engine. Users report that some requests are much slower than expected, but traditional logs and metrics do not clearly identify which service is responsible. You need to understand how each request travels through the application and identify latency between services.

What should you do?

**Correct answer**

**D. Use a distributed tracing framework such as OpenTelemetry or Cloud Trace.**

---

## Why D is Correct

Traditional monitoring tools provide metrics and logs, but they do not show the complete lifecycle of an individual request.

Distributed tracing assigns a unique trace identifier to every request and follows it as it moves through each service. This allows engineers to measure latency, detect bottlenecks, identify slow database calls, and understand service dependencies.

OpenTelemetry is the industry standard framework for generating telemetry data, while Google Cloud Trace stores and visualizes traces inside Google Cloud.

---

## Why the Other Options Are Incorrect

The remaining options typically focus on metrics, logging, or infrastructure monitoring.

Although metrics can indicate that latency exists and logs can report application events, neither provides an end-to-end visualization of a request moving across multiple services.

Only distributed tracing provides complete request visibility across the entire application.

---

# Terraform Infrastructure

The Terraform configuration builds a complete observability environment.

## Google Cloud

Terraform first enables the required Google Cloud APIs, including Compute Engine, Google Kubernetes Engine, Cloud Trace, Cloud Monitoring, Logging, and Service Usage.

A custom VPC network and subnet are created to host the Kubernetes cluster.

---

## Google Kubernetes Engine

A regional infrastructure is created with:

* Custom VPC
* Custom subnet
* GKE cluster
* Dedicated node pool
* Kubernetes provider configured automatically

After deployment, Terraform manages Kubernetes resources directly.

---

## Redis

Redis is deployed as an internal Kubernetes Deployment together with a ClusterIP Service.

The Node.js application stores a request counter inside Redis, creating communication between two services that can later be observed in distributed traces.

---

## Node.js Application

The application is injected through a ConfigMap.

When the container starts it:

* Copies the application files
* Installs dependencies
* Starts the Node.js server

The application automatically instruments itself using OpenTelemetry.

Every incoming HTTP request generates spans that include:

* HTTP request
* Express middleware
* Redis communication
* Processing latency

These traces are exported using the OTLP HTTP protocol.

---

## OpenTelemetry Collector

The collector receives telemetry from the application.

Its responsibilities are:

* Receive OTLP traces
* Batch telemetry
* Export traces to Google Cloud Trace
* Export traces to the debug exporter

The debug exporter is useful during the lab because traces can also be viewed directly inside the collector logs.

---

## NGINX

NGINX acts as the frontend of the application.

It exposes a public Load Balancer and forwards incoming requests to the Node.js backend.

This simulates a real production architecture where clients communicate through a reverse proxy.

---

## End-to-End Request Flow

Client

↓

NGINX Load Balancer

↓

Node.js Application

↓

Redis

↓

OpenTelemetry Collector

↓

Google Cloud Trace

---

## Verification

After the deployment completed successfully:

* All Kubernetes Deployments reached the Running state.
* The Load Balancer exposed the application publicly.
* HTTP requests successfully reached the backend.
* Redis operations generated client spans.
* Express generated middleware and request spans.
* OpenTelemetry Collector received and exported traces.
* The debug exporter displayed complete distributed traces inside the collector logs.

The collector logs confirmed spans for:

* HTTP GET requests
* Express middleware
* Redis connections
* Redis INCR commands
* End-to-end request latency

This demonstrates that distributed tracing is working correctly across the entire application.

---

## Key Concepts

* Distributed tracing follows a request across multiple services.
* Every request belongs to a trace identified by a unique Trace ID.
* Each operation inside the request becomes a span.
* OpenTelemetry is the standard framework for telemetry generation.
* Cloud Trace stores and visualizes traces collected from applications.
* Distributed tracing complements metrics and logs by providing complete request visibility.

---

## Conclusion

This lab demonstrates how to deploy a complete distributed tracing solution using Terraform, Google Kubernetes Engine, OpenTelemetry, Redis, and NGINX.

The architecture automatically generates traces for every request, exports them to Cloud Trace, and provides detailed visibility into service interactions and latency. This is exactly the approach expected by the Professional Cloud DevOps Engineer certification when diagnosing performance problems in distributed systems.
