The correct answer is **B**. The database failure is still detected in **5 minutes**, so the **MTTD** does not change. The new database takes **twice as long to fail over**, increasing the **MTTR** from **10 to 20 minutes**. The **MTBF** remains **90 days** because failures still occur once per quarter, and the **user impact** stays at **33%** since only one of the three GCP zones is affected. Therefore, the updated reliability metrics are **MTTD: 5, MTTR: 20, MTBF: 90, Impact: 33%**.


COMMANDS

```
gcloud container clusters get-credentials database-failover-lab --zone europe-west1-b --project devops-cert-labs

$LB = terraform output -raw load_balancer_ip

kubectl get pods -n chat
kubectl get svc -n chat

Invoke-WebRequest http://$LB/
Invoke-RestMethod http://$LB/status

Start-Job -ArgumentList $LB {
    param($LB)
    while ($true) {
        try {
            (Invoke-WebRequest http://$LB/ -TimeoutSec 2).StatusCode
        } catch {
            503
        }
        Start-Sleep 1
    }
} | Out-Null

$Start = Get-Date

Invoke-WebRequest -Method POST http://$LB/database/fail

do {
    $Status = Invoke-RestMethod http://$LB/status
    Start-Sleep -Milliseconds 500
} while ($Status.databaseAvailable)

$Detected = Get-Date

do {
    $Status = Invoke-RestMethod http://$LB/status
    Start-Sleep -Milliseconds 500
} while (-not $Status.databaseAvailable)

$Recovered = Get-Date

Receive-Job *

Get-Job | Stop-Job
Get-Job | Remove-Job

$Results = @(
    [PSCustomObject]@{
        Metric = "MTTD"
        Value  = "$([math]::Round(($Detected-$Start).TotalSeconds,2)) seconds (~5 minutes)"
    }
    [PSCustomObject]@{
        Metric = "MTTR"
        Value  = "$([math]::Round(($Recovered-$Detected).TotalSeconds,2)) seconds (~20 minutes)"
    }
    [PSCustomObject]@{
        Metric = "MTBF"
        Value  = "90 days"
    }
    [PSCustomObject]@{
        Metric = "Impact"
        Value  = "33%"
    }
)

$Results | Format-Table -AutoSize
```

# Google Cloud Professional Cloud DevOps Engineer Lab

# Question - Database Failover Reliability Risk

---

## Introduction

This repository contains a small hands-on lab created while preparing for the **Google Cloud Professional Cloud DevOps Engineer** certification.

The goal of this lab is to understand how reliability metrics are calculated when a database failure occurs and a failover process is required.

The exam question asks:

> Your product is deployed across three Google Cloud Platform (GCP) zones, with users distributed evenly between them. A database failure occurs once per quarter, is detected within five minutes, and currently requires a 10-minute failover. A new real-time chat feature introduces a new database system that takes twice as long to fail over between zones. What are the updated reliability metrics?

Options:

A. MTTD: 5, MTTR: 10, MTBF: 90, Impact: 33%

B. MTTD: 5, MTTR: 20, MTBF: 90, Impact: 33%

C. MTTD: 5, MTTR: 10, MTBF: 90, Impact: 50%

D. MTTD: 5, MTTR: 20, MTBF: 90, Impact: 50%

---

# Correct Answer

## B - MTTD: 5, MTTR: 20, MTBF: 90, Impact: 33%

---

## Why?

The correct answer is **B** because only the database failover duration changes.

The database failure is still detected within **5 minutes**, so the **Mean Time To Detect (MTTD)** remains unchanged.

The new database system takes **twice as long** to complete the failover, increasing the **Mean Time To Repair (MTTR)** from **10 minutes to 20 minutes**.

Database failures still occur **once every quarter**, so the **Mean Time Between Failures (MTBF)** remains approximately **90 days**.

Finally, the failure only affects **one of the three GCP zones**, so approximately **33% of users** experience the outage.

The reliability metrics become:

```
MTTD  = 5 minutes

MTTR  = 20 minutes

MTBF  = 90 days

Impact = 33%
```

---

# Why the other options are not correct?

### A - MTTD: 5, MTTR: 10, MTBF: 90, Impact: 33%

This answer assumes the failover time does not change.

However, the question explicitly states that the new database requires **twice as long** to fail over.

---

### C - MTTD: 5, MTTR: 10, MTBF: 90, Impact: 50%

This option has two errors.

The failover time should increase to **20 minutes**, and only **one of three zones** is affected, not half of the users.

---

### D - MTTD: 5, MTTR: 20, MTBF: 90, Impact: 50%

The MTTR is correct, but the impact percentage is incorrect.

Since the service runs in **three zones**, a failure in one zone affects approximately **33% of users**, not 50%.

---

# Lab Implementation

This lab simulates a database failure and the failover process using a simple Node.js application running on Google Kubernetes Engine (GKE).

Instead of deploying a real distributed database, the application reproduces the same reliability concepts measured in the exam:

- Database failure
- Failure detection (MTTD)
- Failover process (MTTR)
- Service recovery

The simulated workflow is:

```
Database Failure
        |
        | Wait 5 seconds
        | (Simulated MTTD)
        |
        v
Failure Detected
        |
        | Start Failover
        |
        | Database unavailable
        | Wait 20 seconds
        | (Simulated MTTR)
        |
        v
Database Recovered
        |
        v
Application Available
```

The laboratory scales minutes down to seconds to make the demonstration practical:

- **5 seconds = 5 simulated minutes (MTTD)**
- **20 seconds = 20 simulated minutes (MTTR)**

---

# Infrastructure

Terraform creates:

- GKE cluster
- Node pool
- Kubernetes namespace
- Node.js application
- Kubernetes ConfigMaps
- Kubernetes Deployments
- Internal ClusterIP Service
- NGINX reverse proxy
- External LoadBalancer

The Node.js application exposes three endpoints:

- `GET /`
- `GET /status`
- `POST /database/fail`

---

# Testing

Deploy the infrastructure:

```bash
terraform init

terraform apply
```

Retrieve the cluster credentials:

```powershell
gcloud container clusters get-credentials database-failover-lab --zone europe-west1-b --project devops-cert-labs
```

Trigger the simulated database failure:

```powershell
Invoke-WebRequest -Method POST http://<LOAD_BALANCER_IP>/database/fail
```

The application will:

1. Detect the failure after 5 seconds.
2. Simulate a database outage.
3. Perform a 20-second failover.
4. Restore the service automatically.

The measured values should be similar to:

```
Metric   Value
------   -------------------------------
MTTD     5.7 seconds (~5 minutes)
MTTR     20.3 seconds (~20 minutes)
MTBF     90 days
Impact   33%
```

---

# Commands

```powershell
gcloud container clusters get-credentials database-failover-lab --zone europe-west1-b --project devops-cert-labs

$LB = terraform output -raw load_balancer_ip

kubectl get pods -n chat

kubectl get svc -n chat

kubectl logs -f deployment/chat-api -n chat

Invoke-WebRequest http://$LB/

Invoke-RestMethod http://$LB/status

Invoke-WebRequest -Method POST http://$LB/database/fail
```

---

# Conclusion

This laboratory demonstrates how reliability metrics change when a database failover becomes slower.

Only the **Mean Time To Repair (MTTR)** increases because the new database requires twice as long to complete the failover.

The **Mean Time To Detect (MTTD)** remains the same because failures are still detected within five minutes.

The **Mean Time Between Failures (MTBF)** does not change because failures still occur once every quarter.

Finally, only one of the three availability zones is affected, so the user impact remains approximately **33%**, making **option B** the correct answer.