# Google Cloud Professional Cloud DevOps Engineer Lab

# Question - Reduce Compute Engine Costs for a Long-Term Stable Workload

---

## Introduction

This repository contains a hands-on lab created while preparing for the **Google Cloud Professional Cloud DevOps Engineer** certification.

The objective of this lab is to understand how to reduce the cost of a long-running Compute Engine workload without affecting performance or availability.

The lab deploys several virtual machines that simulate a stable production environment running continuously for months.

---

# Exam Question

> You need to run a business-critical workload on a fixed set of Compute Engine instances for several months. The workload is stable with the exact amount of resources allocated to it. You want to lower the costs for this workload without any performance implications. What should you do?

### A

Purchase Committed Use Discounts.

### B

Migrate the instances to a Managed Instance Group.

### C

Convert the instances to preemptible virtual machines.

### D

Create an Unmanaged Instance Group for the instances used to run the workload.

---

# Correct Answer

✅ **Answer A — Purchase Committed Use Discounts**

---

# Why Answer A is Correct

The workload is described as:

- Business-critical.
- Running for several months.
- Using a fixed number of Compute Engine instances.
- Having stable resource usage.

This is exactly the scenario where **Committed Use Discounts (CUDs)** provide the greatest benefit.

A Committed Use Discount is a billing commitment where you agree to use a certain amount of Compute Engine resources for **1 year or 3 years**.

In return, Google Cloud provides significant discounts compared to the standard pay-as-you-go price.

The important advantage is that:

- Performance does not change.
- The virtual machines continue running normally.
- No infrastructure changes are required.
- Only the billing model changes.

This makes Committed Use Discounts the recommended solution for long-term, predictable workloads.

---

# Why the Other Answers are Incorrect

## Answer B

Managed Instance Groups improve availability, scaling, and automated management.

However, they do **not** reduce Compute Engine costs by themselves.

The workload already has a fixed number of instances, so migrating to a Managed Instance Group does not solve the problem described in the question.

---

## Answer C

Preemptible (Spot) VMs are much cheaper, but Google Cloud can stop them at almost any time.

A business-critical workload cannot depend on instances that may be terminated unexpectedly.

Although Spot VMs reduce costs, they also reduce availability and reliability.

This introduces performance and operational risks.

---

## Answer D

An Unmanaged Instance Group only groups existing virtual machines.

It does not provide discounts or reduce Compute Engine pricing.

It is simply an administrative grouping feature.

---

# Terraform Resources

This lab creates a stable production environment.

The infrastructure includes:

- Compute Engine API
- Three Compute Engine virtual machines
- SSH firewall rule
- Startup script that simulates a long-running workload

The startup script continuously generates CPU activity using **stress-ng**, representing a production application running for several months.

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

## 1. Verify the Virtual Machines

List all Compute Engine instances.

```bash
gcloud compute instances list
```

Expected output:

```text
business-workload-1
business-workload-2
business-workload-3
```

These instances simulate a fixed production environment.

---

## 2. Connect to a Virtual Machine

```bash
gcloud compute ssh business-workload-1 --zone=europe-west1-b
```

Verify that the workload is running.

```bash
ps aux | grep stress-ng
```

Expected result:

```text
stress-ng --cpu 2 --cpu-load 60
```

---

## 3. Verify Resource Stability

Open Cloud Monitoring.

```
https://console.cloud.google.com/monitoring
```

CPU utilization should remain relatively constant because the workload is stable.

This matches the scenario described in the exam.

---

## 4. Purchase a Committed Use Discount

Terraform cannot purchase Committed Use Discounts because they are part of **Google Cloud Billing**, not Compute Engine.

To complete the optimization in a real environment:

1. Open **Billing**.
2. Navigate to **Committed Use Discounts**.
3. Select Compute Engine.
4. Purchase a 1-year or 3-year commitment matching the workload.

No changes to the virtual machines are required.

---

# Important Note

This lab simulates the infrastructure that benefits from Committed Use Discounts.

The discount itself cannot be created using Terraform because it is a billing commitment rather than an infrastructure resource.

The purpose of the lab is to recognize when a stable workload should use Committed Use Discounts instead of changing the infrastructure.

---

# Architecture

```text
                +-----------------------+
                |  Business Application |
                +-----------+-----------+
                            |
                            |
                            ▼
         +----------------------------------------+
         |      Compute Engine Virtual Machines    |
         |                                        |
         |  business-workload-1                   |
         |  business-workload-2                   |
         |  business-workload-3                   |
         +------------------+---------------------+
                            |
                            |
                            ▼
               Stable Resource Consumption
                            |
                            ▼
          Purchase Committed Use Discounts
                            |
                            ▼
              Lower Cost Without Performance Loss
```

---

# Conclusion

This lab demonstrates the best Google Cloud cost optimization strategy for long-term Compute Engine workloads.

Because the application runs continuously with predictable resource usage, **Committed Use Discounts** provide significant savings while maintaining the same infrastructure and performance.

Managed Instance Groups improve management, Spot VMs reduce reliability, and Unmanaged Instance Groups only organize resources.

For a stable business-critical workload running over several months, **Answer A** is the correct solution.