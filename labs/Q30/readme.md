COMMANDS

```
terraform output


echo ""
echo "==============================="
echo "CHECK BACKEND"
echo "==============================="

curl.exe $(terraform output -raw backend_url)


echo ""
echo ""
echo "==============================="
echo "CHECK CDN STATUS"
echo "==============================="

Invoke-Expression $(terraform output -raw cdn_status)


echo ""
echo ""
echo "==============================="
echo "GENERATING USER REQUESTS THROUGH CDN"
echo "==============================="


1..20 | ForEach-Object {

    echo "==============================="
    echo "Request $_"

    curl.exe $(terraform output -raw cdn_url)

    echo ""
    echo ""

}


echo ""
echo "==============================="
echo "SYNTHETIC SLI METRICS"
echo "==============================="

curl.exe $(terraform output -raw synthetic_metrics)



echo ""
echo ""
echo "==============================="
echo "SIMULATING CDN FAILURE"
echo "==============================="


Invoke-Expression $(terraform output -raw cdn_fail)



echo ""
echo ""
echo "==============================="
echo "CHECK CDN STATUS AFTER FAILURE"
echo "==============================="

Invoke-Expression $(terraform output -raw cdn_status)



echo ""
echo ""
echo "==============================="
echo "WAITING FOR SYNTHETIC CLIENT"
echo "==============================="

Start-Sleep -Seconds 60



echo ""
echo ""
echo "==============================="
echo "SLI AFTER CDN FAILURE"
echo "==============================="


curl.exe $(terraform output -raw synthetic_metrics)



echo ""
echo ""
echo "==============================="
echo "RECOVERING CDN"
echo "==============================="


Invoke-Expression $(terraform output -raw cdn_recover)



echo ""
echo ""
echo "==============================="
echo "CHECK CDN RECOVERY"
echo "==============================="

Invoke-Expression $(terraform output -raw cdn_status)



echo ""
echo ""
echo "==============================="
echo "FINAL SYNTHETIC METRICS"
echo "==============================="


curl.exe $(terraform output -raw synthetic_metrics)
```

# Google Cloud Professional Cloud DevOps Engineer Lab

# Question - Increase Availability SLI Coverage Beyond the Cloud Load Balancer

---

## Introduction

This repository contains a hands-on lab created while preparing for the **Google Cloud Professional Cloud DevOps Engineer** certification.

The purpose of this lab is to understand **where availability should be measured** when a web application is deployed behind multiple networking layers.

In this scenario, user requests first pass through a **third-party CDN**, then reach a **Global HTTP/S Cloud Load Balancer**, and finally arrive at the application running on **Google Kubernetes Engine (GKE)**.

An Availability SLI already exists at the Cloud Load Balancer level. However, this SLI cannot detect failures that happen before traffic reaches the load balancer.

The goal is to simulate this architecture and demonstrate why additional measurements are required.

---

# Exam Question

> You support a multi-region web service running on Google Kubernetes Engine (GKE) behind a Global HTTP/S Cloud Load Balancer (CLB). For legacy reasons, user requests first go through a third-party Content Delivery Network (CDN), which then routes traffic to the CLB.
>
> You have already implemented an availability Service Level Indicator (SLI) at the CLB level. However, you want to increase coverage in case of a potential load balancer misconfiguration, CDN failure, or other global networking catastrophe.
>
> Where should you measure this new SLI?
>
> (Choose two.)

- A. Your application servers' logs.
- B. Instrumentation coded directly in the client.
- C. Metrics exported from the application servers.
- D. GKE health checks for your application servers.
- E. A synthetic client that periodically sends simulated user requests.

---

# Correct Answer

**B and E**

---

# Why B is Correct

Client-side instrumentation measures availability from the real user's perspective.

If the CDN cannot reach the Cloud Load Balancer, or if DNS, routing or networking problems occur before the request reaches Google Cloud, the application servers will never receive the request.

Because of this:

- Backend logs never record the failure.
- Application metrics never increase.
- Load Balancer metrics may also show no errors because traffic never arrives.

Only code running inside the client can detect that the user cannot access the application.

---

# Why E is Correct

A synthetic client continuously sends requests that simulate real users.

Unlike backend monitoring, the synthetic client performs requests from outside the infrastructure.

Because it follows exactly the same network path as a normal user:

Internet

↓

Third-party CDN

↓

Cloud Load Balancer

↓

Application

it detects failures affecting:

- CDN outages
- DNS problems
- Load Balancer misconfigurations
- Global routing failures
- Network connectivity issues

This provides much better Availability SLI coverage.

---

# Why the Other Answers Are Wrong

## A — Application Server Logs

Application logs only record requests that successfully reach the backend.

If the CDN fails before forwarding traffic, nothing is logged.

---

## C — Application Metrics

Metrics exported by the application have the same limitation.

No request reaches the application during a networking failure.

---

## D — GKE Health Checks

Health checks only verify whether Kubernetes Pods are healthy.

They do not measure whether users can actually access the application.

---

# Lab Architecture

This lab simulates the complete request path.

```
                 Synthetic Client
                        │
                        │ HTTP Requests
                        ▼
             Third-Party CDN Simulator
                        │
                        ▼
            Backend Application (GKE)
```

The objective is to demonstrate that a monitoring component located outside the infrastructure can detect failures that internal monitoring cannot.

---

# Infrastructure Created

Terraform creates three Compute Engine virtual machines.

## Backend Simulator

This VM represents the application running inside GKE.

It hosts a Flask application exposing several endpoints:

- `/`
- `/health`
- `/fail`
- `/recover`

The backend can intentionally simulate failures to test monitoring behaviour.

---

## Third-Party CDN Simulator

This VM simulates an external CDN.

It receives user requests and forwards them to the backend application.

Additional endpoints allow simulating CDN failures:

- `/cdn/fail`
- `/cdn/recover`
- `/cdn/status`

When the CDN is disabled, users cannot reach the backend even if the application is healthy.

---

## Synthetic Monitoring Client

This VM continuously sends HTTP requests to the CDN.

Every request is classified as:

- Successful
- Failed

The Availability SLI is calculated as:

```
Availability SLI =
Successful Requests / Total Requests × 100
```

The monitoring API exposes:

- `/metrics`
- `/check`
- `/reset`

---

# Monitoring Logic

Every 30 seconds the synthetic client executes:

1. Send a request to the CDN.
2. Wait for the HTTP response.
3. Count success or failure.
4. Update the Availability SLI.

Because the monitoring happens outside the infrastructure, it measures the complete user experience instead of only backend health.

---

# Startup Scripts

Each virtual machine installs:

- Python 3
- Python Virtual Environment (venv)
- Flask
- Requests (where needed)

Every application runs as a **systemd service**, making the deployment much more reliable than simply using `nohup`.

This also allows automatic restart if the application crashes.

---

# Important Issue Found During Development

While creating this lab, an important Terraform issue appeared.

Initially, the Python files were generated using:

```bash
<<'PY'
```

The single quotes prevent Terraform from replacing variables inside the generated file.

As a consequence, values such as:

```python
BACKEND = "http://${google_compute_instance.backend.network_interface[0].network_ip}:8080"
```

were written literally instead of using the backend private IP.

The solution was to replace:

```bash
<<'PY'
```

with:

```bash
<<PY
```

This allows Terraform interpolation before writing the Python script.

---

# Another Issue Found

The first implementation of the synthetic client used an infinite loop before starting Flask.

Because of this, the monitoring thread blocked the web server and the API never became available.

The final implementation solves this problem by running the monitoring loop inside a background thread.

This allows:

- Continuous monitoring
- REST API availability
- Metric visualization at the same time

---

# How to Test the Lab

## Backend

```powershell
curl.exe $(terraform output -raw backend_url)
```

Expected result:

```json
{
  "service":"GKE backend simulator",
  "status":"healthy"
}
```

---

## CDN

```powershell
curl.exe $(terraform output -raw cdn_url)
```

The request should be successfully forwarded to the backend.

---

## Synthetic Monitoring

```powershell
curl.exe $(terraform output -raw synthetic_metrics)
```

Example:

```json
{
  "requests":17,
  "success":12,
  "failed":5,
  "availability_sli":70.59
}
```

---

## Simulate a CDN Failure

```powershell
Invoke-Expression $(terraform output -raw cdn_fail)
```

The CDN immediately stops forwarding requests.

After a few monitoring cycles:

```powershell
curl.exe $(terraform output -raw synthetic_metrics)
```

The Availability SLI decreases because simulated users cannot reach the application.

---

## Recover the CDN

```powershell
Invoke-Expression $(terraform output -raw cdn_recover)
```

The synthetic client starts reporting successful requests again, and the Availability SLI gradually increases.

---

# What This Lab Demonstrates

This lab clearly shows an important SRE principle:

Internal monitoring only observes what happens inside the infrastructure.

External monitoring measures what users actually experience.

Even if the backend is healthy, users may still be unable to access the application due to failures occurring before requests reach Google Cloud.

For this reason, Availability SLIs should not rely only on backend metrics.

Combining:

- Client-side instrumentation
- Synthetic monitoring

provides much better visibility and more accurate Service Level Indicators.

---

# Conclusion

This lab recreates a simplified production environment where a third-party CDN exists in front of Google Cloud.

It demonstrates why backend metrics alone are insufficient to measure availability and why Google recommends complementing Load Balancer SLIs with both **client instrumentation** and **synthetic monitoring**.

This is exactly the reasoning expected for the **Google Cloud Professional Cloud DevOps Engineer** certification exam.

---

# Exam Answer

✅ **B — Instrumentation coded directly in the client**

✅ **E — A synthetic client that periodically sends simulated user requests**