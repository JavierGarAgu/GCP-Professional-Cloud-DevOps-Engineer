COMMANDS
```
tail -f /var/log/startup.log

80 failed 20 success

1..20 | ForEach-Object {

    $status = curl.exe -s -o NUL -w "%{http_code}" $(terraform output -raw application_url)

    if ($status -eq "200") {
        "Canary Healthy"
    }
    elseif ($status -eq "500") {
        "Canary Failed (500)"
    }
    else {
        "HTTP $status"
    }

}

#activate rollback_url
curl $(terraform output -raw rollback_url)

ALL SUCCESS

1..20 | ForEach-Object {

    $status = curl.exe -s -o NUL -w "%{http_code}" $(terraform output -raw application_url)

    if ($status -eq "200") {
        "Canary Healthy"
    }
    elseif ($status -eq "500") {
        "Canary Failed (500)"
    }
    else {
        "HTTP $status"
    }

}
```

# Google Cloud Professional Cloud DevOps Engineer Lab

# Question - Roll Back a Failing Canary Release

---

## Introduction

This repository contains a hands-on lab created while preparing for the **Google Cloud Professional Cloud DevOps Engineer** certification.

The goal of this lab is to understand the correct action when a **canary deployment** starts affecting production users.

The deployed application simulates a canary release that introduces increased latency and a high number of HTTP 500 errors. The objective is to identify the correct first action following Google's Site Reliability Engineering (SRE) principles.

---

# Exam Question

> You are running an experiment to see whether your users like a new feature of a web application. Shortly after deploying the feature as a canary release, you receive a spike in the number of 500 errors sent to users, and your monitoring reports show increased latency. You want to quickly minimize the negative impact on users. What should you do first?

### A

Roll back the experimental canary release.

### B

Start monitoring latency, traffic, errors, and saturation.

### C

Record data for the postmortem document of the incident.

### D

Trace the origin of 500 errors and the root cause of increased latency.

---

# Correct Answer

✅ **Answer A — Roll back the experimental canary release.**

---

# Why Answer A is Correct

The question clearly states that:

- Users are already receiving HTTP 500 errors.
- Monitoring reports show increased latency.
- The objective is to **quickly minimize the negative impact on users**.

According to Google's SRE practices, the first priority during an incident is to restore the service.

Because the problem started immediately after deploying the canary version, the fastest and safest action is to roll back the deployment.

After the rollback, the team can investigate the root cause, analyze logs, and prepare the postmortem without continuing to affect users.

The general incident response process is:

```text
Detect Incident
        │
        ▼
Reduce User Impact
        │
        ▼
Restore Service
        │
        ▼
Investigate Root Cause
        │
        ▼
Write Postmortem
```

---

# Why the Other Answers are Incorrect

## Answer B

Monitoring latency, traffic, errors, and saturation is important.

However, the monitoring system has already detected the problem.

Continuing to monitor without restoring the service allows more users to experience failures.

---

## Answer C

A postmortem is written after the incident has been resolved.

It is not the first action during an active production problem.

---

## Answer D

Finding the root cause is an important step, but it should happen after restoring service.

Users should not continue receiving errors while the engineering team investigates the issue.

---

# Terraform Resources

This lab deploys:

- Compute Engine virtual machine
- Python Flask application
- HTTP firewall rule

The Flask application simulates two application versions.

## Canary Version

The initial deployment is the canary release.

Characteristics:

- Around 70% of requests return HTTP 500.
- Every request waits approximately two seconds before responding.
- This simulates increased latency and application failures.

## Stable Version

The stable version always returns:

```text
Stable Version
```

without artificial latency.

The application also exposes two additional endpoints:

| Endpoint | Description |
|----------|-------------|
| `/status` | Shows whether the Canary or Stable version is active. |
| `/rollback` | Simulates rolling back the canary deployment. |

---

# Deployment

Initialize Terraform.

```bash
terraform init
```

Create the execution plan.

```bash
terraform plan
```

Deploy the infrastructure.

```bash
terraform apply
```

---

# Validation

## 1. Verify the Virtual Machine

```bash
gcloud compute instances list
```

Expected output:

```text
canary-release-lab
```

---

## 2. Verify the Current Deployment

Open:

```text
http://<EXTERNAL-IP>:8080/status
```

Expected response:

```text
Current deployment: CANARY
```

---

## 3. Generate Traffic

Run multiple requests.

PowerShell example:

```powershell
1..20 | ForEach-Object {

    $result = curl.exe -s -o NUL `
        -w "HTTP %{http_code} - %{time_total}s`n" `
        $(terraform output -raw application_url)

    $result

}
```

Typical output:

```text
HTTP 500 - 2.00s
HTTP 500 - 2.01s
HTTP 200 - 2.00s
HTTP 500 - 2.00s
HTTP 200 - 2.01s
```

This demonstrates:

- High error rate.
- Increased latency.
- Canary deployment affecting users.

---

## 4. Roll Back the Canary Release

Execute:

```powershell
curl $(terraform output -raw rollback_url)
```

Expected output:

```text
Rollback completed. Stable version active.
```

---

## 5. Verify the Rollback

Open:

```text
http://<EXTERNAL-IP>:8080/status
```

Expected response:

```text
Current deployment: STABLE
```

---

## 6. Test Again

Run the same traffic test.

Example output:

```text
HTTP 200 - 0.00s
HTTP 200 - 0.00s
HTTP 200 - 0.00s
HTTP 200 - 0.00s
```

The rollback removes both:

- HTTP 500 errors
- Artificial latency

The service is healthy again.

---

# Architecture

```text
                +----------------------+
                |      Users           |
                +----------+-----------+
                           |
                           ▼
                +----------------------+
                |  Canary Deployment   |
                +----------+-----------+
                           |
            +--------------+--------------+
            |                             |
            ▼                             ▼
      HTTP 500 Errors             High Latency
            |                             |
            +--------------+--------------+
                           |
                           ▼
               Roll Back Canary Release
                           |
                           ▼
                +----------------------+
                |   Stable Version     |
                +----------+-----------+
                           |
                           ▼
                  Healthy User Requests
```

---

# SRE Incident Response Workflow

```text
Canary Deployment
        │
        ▼
Users Receive Errors
        │
        ▼
Monitoring Detects Problem
        │
        ▼
Rollback Canary
        │
        ▼
Service Restored
        │
        ▼
Root Cause Analysis
        │
        ▼
Postmortem
```

---

# Conclusion

This lab demonstrates one of the most important incident response principles in Site Reliability Engineering.

When a canary deployment causes production errors and increased latency, the first priority is to reduce the impact on users.

Rolling back the canary release immediately restores the stable version and minimizes downtime.

Only after the service has recovered should the engineering team investigate the root cause and prepare the postmortem.

For this reason, **Answer A** is the correct solution.