COMMANDS

```
gcloud compute instances list

$INSTANCE = "production-dghx"

$IP = "34.78.144.61"

curl.exe -v http://${IP}:8080

curl.exe -v http://${IP}:8080/health

gcloud compute ssh $INSTANCE --zone=europe-west1-c

#sudo pkill -9 python3

Start-Sleep -Seconds 90

gcloud compute instances list

curl.exe -v http://${IP}:8080/health
```

# Google Cloud Professional Cloud DevOps Engineer Lab

# Question - Automatically Recover a Crashing Compute Engine Instance

---

## Introduction

This laboratory demonstrates how to improve the reliability of a production service running on Google Cloud.

The original scenario has a single Compute Engine instance running a production application. When the instance crashes, an engineer must manually delete the VM and create a new one from an image.

This manual process creates operational toil and does not follow Site Reliability Engineering (SRE) principles.

The goal is to automate the recovery process by using a **Managed Instance Group (MIG)** with **Health Checks**.

---

# Exam Question

You support a production service that runs on a single Compute Engine instance.

You regularly need to spend time recreating the service by deleting the crashing instance and creating a new instance based on the relevant image.

You want to reduce the time spent performing manual operations while following Site Reliability Engineering principles.

What should you do?

### Options

A. File a bug with the development team so they can find the root cause of the crashing instance.

B. Create a Managed Instance Group with a single instance and use health checks to determine the system status.

C. Add a Load Balancer in front of the Compute Engine instance and use health checks to determine the system status.

D. Create a Monitoring dashboard with SMS alerts to manually recreate the instance faster.

---

# Correct Answer

## Answer B

**Create a Managed Instance Group with a single instance and use health checks to determine the system status.**

---

# Explanation

A Managed Instance Group provides automatic instance lifecycle management.

Instead of manually deleting failed VMs and recreating them, the MIG continuously monitors the instance health.

If the health check detects that the application is unhealthy:

1. The MIG marks the instance as unhealthy.
2. The unhealthy VM is automatically recreated.
3. The service returns to a healthy state without manual intervention.

This reduces operational toil and follows SRE principles such as:

- Automation over manual operations.
- Reliability through self-healing systems.
- Reducing repetitive operational tasks.

---

# Why the Other Answers Are Incorrect

## A. File a bug with the development team

Finding the root cause is important, but it does not solve the immediate reliability problem.

The service still requires manual recovery after every crash.

---

## C. Add a Load Balancer

A Load Balancer improves availability by distributing traffic between multiple backends.

However, the problem is not traffic distribution.

The problem is that the VM itself must be automatically recreated after failure.

A Load Balancer alone does not recreate Compute Engine instances.

---

## D. Create Monitoring alerts

Monitoring alerts only notify engineers about failures.

This still requires manual intervention.

A SRE approach prefers automatic remediation when possible.

---

# Lab Architecture

The implemented solution contains:
