terraform init
terraform apply -auto-approve

gcloud compute instances list

gcloud compute ssh logging-lab --zone=europe-west1-b

sudo systemctl status google-cloud-ops-agent

journalctl | grep "Hello from Terraform Logging Lab"

journalctl -f

gcloud logging read 'textPayload:"Hello from Terraform Logging Lab"' --limit=10

terraform destroy -auto-approve



TESTING STARTUP SCRIPT

systemctl status google-startup-scripts.service --no-pager

sudo google_metadata_script_runner startup


# Google Cloud Professional Cloud DevOps Engineer Lab

# Question - Cloud Logging Best Practices

---

# Introduction

This repository contains a small hands-on lab created while preparing for the **Google Cloud Professional Cloud DevOps Engineer** certification.

The objective of this lab is to understand how Google recommends collecting and viewing application logs running on **Compute Engine**.

Instead of creating custom scripts or complicated logging pipelines, Google provides a managed service that automatically collects logs and stores them in **Cloud Logging**.

This lab reproduces that recommendation using a minimal infrastructure created with Terraform.

---

# Exam Question

> You have a pool of application servers running on Compute Engine.
>
> You need to provide a secure solution that requires the least amount of configuration and allows developers to easily access application logs for troubleshooting.
>
> **How would you implement the solution on Google Cloud?**

### A ✅

- Deploy the Cloud Ops Agent (formerly Stackdriver Logging Agent) to the application servers.
- Give developers the **Logs Viewer** IAM role.

### B

- Deploy the Cloud Ops Agent.
- Give developers the **Logs Private Logs Viewer** IAM role.

### C

- Deploy the Cloud Monitoring Agent.
- Give developers the **Monitoring Viewer** IAM role.

### D

- Upload logs periodically to Cloud Storage using `gsutil` and a cron job.

---

# Why is A the correct answer?

The question is asking for a solution that is:

- Secure
- Easy to manage
- Requires the least amount of configuration
- Allows developers to troubleshoot application logs

Google Cloud already provides **Cloud Logging**, a fully managed logging platform.

By installing the **Cloud Ops Agent**, application and system logs are automatically collected from the Compute Engine instances and sent to Cloud Logging.

Developers only need the **Logs Viewer** IAM role (`roles/logging.viewer`) to search and read those logs.

This solution follows the **principle of least privilege**, because developers can read logs without receiving unnecessary permissions.

It also avoids creating custom scripts, cron jobs or manual uploads, reducing operational complexity.

---

# Lab Architecture

```
                    Compute Engine VM
                           │
                           │
                   Cloud Ops Agent
                           │
                 Collect application logs
                           │
                           ▼
                    Cloud Logging
                           │
               Logs Viewer IAM Role
                           │
                           ▼
                     Developers
```

---

# Infrastructure

Terraform creates:

- One VPC Network
- Firewall rule for SSH
- Compute Engine VM
- Service Account for the VM
- Service Account for the developer
- IAM role `roles/logging.logWriter` for the VM
- IAM role `roles/logging.viewer` for the developer
- Startup script that automatically installs the Cloud Ops Agent

The infrastructure is intentionally very small because the objective is understanding the logging workflow instead of building a production environment.

---

# Logging Flow

When the VM starts, Terraform executes a startup script.

The startup script installs the **Cloud Ops Agent** automatically.

Once installed, the agent continuously monitors the system logs and application logs.

Whenever an application writes a message using Linux `logger`, the Cloud Ops Agent collects it and sends it to **Cloud Logging**.

Developers can immediately search those logs using the Google Cloud Console or the `gcloud` CLI.

---

# IAM Permissions

Two different service accounts are used.

## VM Service Account

The Compute Engine instance receives:

```
roles/logging.logWriter
```

This permission allows the VM to send logs to Cloud Logging.

It does not grant permissions to read or modify logs.

---

## Developer Service Account

The developer receives:

```
roles/logging.viewer
```

This permission allows developers to search and read logs for troubleshooting.

Because the role is read-only, it follows the principle of least privilege.

---

# Lab Steps

## 1. Deploy the infrastructure

```bash
terraform init

terraform apply -auto-approve
```

Terraform creates the VM and automatically installs the Cloud Ops Agent during startup.

---

## 2. Connect to the VM

```bash
gcloud compute ssh logging-vm --zone=europe-west1-b
```

---

## 3. Generate an application log

```bash
logger "Hello from Compute Engine"
```

This simulates an application writing a log message.

---

## 4. Verify the log

From the local machine:

```powershell
gcloud logging read `
'textPayload:"Hello from Compute Engine"' `
--limit=5
```

The log should appear almost immediately.

This confirms that the Cloud Ops Agent successfully collected and exported the log.

---

# Why not the other options?

## Option B

The Cloud Ops Agent is correct.

However, **Logs Private Logs Viewer** grants access to private logs, including sensitive audit logs that normal developers do not need.

This gives more permissions than required and does not follow the principle of least privilege.

---

## Option C

Cloud Monitoring collects **metrics**, not logs.

CPU usage, memory usage and network traffic are examples of metrics.

The question is asking developers to troubleshoot **application logs**, so Monitoring is not the correct service.

---

## Option D

Uploading log files to Cloud Storage using `gsutil` works, but it is not the Google recommended solution.

This approach requires:

- Custom scripts
- Cron jobs
- Manual maintenance
- Delayed log uploads

Cloud Logging already provides a fully managed logging service, making this solution unnecessarily complex.

---

# Google Cloud Services Used

- Compute Engine
- Cloud Logging
- Cloud Ops Agent
- IAM
- Terraform

---

# Concepts Practiced

- Infrastructure as Code
- Cloud Logging
- Cloud Ops Agent
- Compute Engine
- IAM Roles
- Principle of Least Privilege
- Application Troubleshooting

---

# What I Learned

After completing this lab, it became much easier to understand why **Answer A** is the correct choice.

Google recommends using the **Cloud Ops Agent** because it automatically collects and sends logs to Cloud Logging without requiring custom scripts or additional maintenance.

Developers only need the **Logs Viewer** role to investigate application problems.

This keeps the environment secure while making troubleshooting simple and efficient.

---

# Conclusion

This lab demonstrates Google's recommended logging architecture for Compute Engine.

Instead of creating a custom logging solution, the Cloud Ops Agent automatically exports logs to Cloud Logging, where developers can search them using the **Logs Viewer** role.

The solution is simple, secure and easy to maintain.

For the certification exam, the important idea is remembering that **Cloud Logging is the managed logging platform**, the **Cloud Ops Agent** performs log collection automatically, and developers only need **Logs Viewer** permissions to troubleshoot application issues.

---

# Verification

```bash
terraform init

terraform apply -auto-approve

gcloud compute ssh logging-vm --zone=europe-west1-b

logger "Hello from Compute Engine"

exit

gcloud logging read \
'textPayload:"Hello from Compute Engine"' \
--limit=5

terraform destroy -auto-approve
```

