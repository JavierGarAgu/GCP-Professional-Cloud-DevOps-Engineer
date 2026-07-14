SIMULATION COMMANDS

```
1..20 | ForEach-Object {
    $status = curl.exe -s -o NUL -w "%{http_code}" http://$(terraform output -raw external_ip):8080

    if ($status -eq "200") {
        "Healthy"
    }
    elseif ($status -eq "503") {
        "Not Healthy"
    }
    else {
        "HTTP $status"
    }
}
```

# Google Cloud Professional Cloud DevOps Engineer Lab

# Question - Incident Management Communication During a Major Outage

---

## Introduction

This repository contains a small hands-on lab created while preparing for the **Google Cloud Professional Cloud DevOps Engineer** certification.

The goal of this lab is to simulate a **large production incident** where a critical infrastructure service becomes unavailable and affects many dependent systems. Although the real exam question focuses on **Site Reliability Engineering (SRE) incident management**, this Terraform project creates a simple environment that allows us to reproduce a failing service and understand the incident response workflow.

---

# Architecture

```
                Users
                  │
                  │ HTTP
                  ▼
        +-------------------+
        | Compute Engine VM |
        | Flask Application |
        +-------------------+
                  │
                  ▼
        Random Healthy / Failed
          (200 or 503 Response)
```

The application randomly returns:

- **HTTP 200** → Service Healthy
- **HTTP 503** → Service Unavailable

This simulates a production service where most user requests fail.

---

# Files

```
.
└── main.tf
```

Everything is deployed from a single Terraform file.

---

# What Terraform Creates

The deployment creates:

- Google Compute Engine VM
- Debian 12 operating system
- Python virtual environment
- Flask application
- Startup script
- Firewall rule
- Public IP address

---

# Infrastructure Explained

## Provider

The provider configures Terraform to deploy resources into Google Cloud.

```terraform
provider "google" {
  project = "devops-cert-labs"
  region  = "europe-west1"
  zone    = "europe-west1-b"
}
```

---

## Required API

Terraform enables the Compute Engine API before creating the VM.

```terraform
google_project_service
```

Without this API the virtual machine cannot be created.

---

## Compute Engine

Terraform creates one small virtual machine.

```terraform
machine_type = "e2-micro"
```

The VM is enough for this simple simulation.

---

## Startup Script

When the VM starts, the startup script automatically performs several tasks.

### 1. Update the operating system

```bash
apt-get update
```

---

### 2. Install Python

```bash
python3
python3-pip
python3-venv
```

A virtual environment is created because Debian 12 does not allow installing Python packages directly into the system environment.

---

### 3. Install Flask

Inside the virtual environment:

```bash
pip install Flask
```

Flask provides a lightweight HTTP server.

---

### 4. Create the application

The startup script creates a Python file.

The application exposes two endpoints.

```
/
```

Main application.

```
/health
```

Simple health endpoint.

---

### 5. Start the service

Finally the application starts automatically in the background.

```
nohup python service.py
```

No manual configuration is required.

---

# Application Logic

The application intentionally behaves like an unstable production service.

Every request waits for two seconds.

```python
time.sleep(2)
```

Then a random number is generated.

Most requests return:

```
503 Service Unavailable
```

Some requests return:

```
200 Service Healthy
```

This simulates a service suffering from an ongoing production incident.

---

# Testing the Service

Terraform prints the VM public IP.

Example:

```bash
terraform output -raw external_ip
```

Then test the application.

```powershell
curl.exe http://VM_IP:8080
```

For repeated checks:

```powershell
while ($true) {

    $status = curl.exe -s -o NUL -w "%{http_code}" http://$(terraform output -raw external_ip):8080

    if ($status -eq "200") {
        Write-Host "Healthy"
    }
    elseif ($status -eq "503") {
        Write-Host "Not Healthy"
    }

    Start-Sleep 1
}
```

The output continuously changes depending on the simulated service state.

Example:

```
Healthy
Healthy
Not Healthy
Not Healthy
Healthy
```

---

# Simulated Incident

Imagine the following production scenario.

- A critical infrastructure service begins failing.
- Hundreds of thousands of users are affected.
- Many dependent services also fail.
- You are the on-call engineer.

Following Google's SRE incident management process, you immediately assign:

- Incident Commander (IC)
- Operations Lead (OL)
- Communications Lead (CL)

Now the incident response officially begins.

---

# Exam Question

**What should you do next?**

A. Look for ways to mitigate user impact and deploy mitigations.

B. Contact affected service owners.

C. Establish a communication channel where responders and incident leads can coordinate.

D. Start writing the postmortem.

---

# Correct Answer

**✅ C — Establish a communication channel where incident responders and leads can communicate with each other.**

---

# Why?

After assigning the Incident Commander, Operations Lead and Communications Lead, the next priority is making sure everyone involved can coordinate efficiently.

Without a dedicated communication channel:

- responders may duplicate work
- important updates can be lost
- mitigation efforts become disorganized
- stakeholders receive inconsistent information

A communication channel (Google Chat, Slack, Microsoft Teams, Meet, etc.) becomes the central place where all responders coordinate during the incident.

Only after communication is established should the Operations Lead begin investigating and deploying mitigations.

---

# Why the Other Answers Are Incorrect

## A

Mitigating the incident is important, but effective coordination must exist first.

The Operations Lead performs technical mitigation after the incident structure has been established.

---

## B

The Communications Lead is responsible for informing stakeholders.

Contacting every affected service owner is not the immediate next action after assigning the incident roles.

---

## D

A blameless postmortem is written **after** the incident has been resolved.

It is never started during the initial response.

---

# SRE Incident Timeline

```
Alert Triggered
        │
        ▼
Declare Incident
        │
        ▼
Assign IC
        │
        ▼
Assign OL
        │
        ▼
Assign CL
        │
        ▼
Establish Communication Channel
        │
        ▼
Investigate
        │
        ▼
Mitigate
        │
        ▼
Recover Service
        │
        ▼
Write Blameless Postmortem
```

---

# Conclusion

This lab demonstrates the first steps of Google's Site Reliability Engineering incident response process.

Although the infrastructure consists of only one virtual machine, it recreates the behavior of an unstable production service and allows practicing the decision-making process expected in the Professional Cloud DevOps Engineer exam.

The key lesson is that **effective incident management begins with clear roles and reliable communication before technical mitigation starts.**

In addition to incident response training, it helps to prepare for an incident beforehand. Use the following tips and strategies to be better prepared.
Decide on a communication channel
Decide and agree on a communication channel (Slack, a phone bridge, IRC, HipChat, etc.) beforehand.
Keep your audience informed
Unless you acknowledge that an incident is happening and actively being addressed, people will automatically assume nothing is being done to resolve the issue. Similarly, if you forget to call off the response once the issue has been mitigated or resolved, people will assume the incident is ongoing. You can preempt this dynamic by keeping your audience informed throughout the incident with regular status updates. Having a prepared list of contacts (see the next tip) saves valuable time and ensures you don’t miss anyone.
https://sre.google/workbook/incident-response/