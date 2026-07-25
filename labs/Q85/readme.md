COMMANDS
```
#if policy already exists
gcloud beta compute instances ops-agents policies delete ops-agents-policy
#test if the vm have ops-agent
sudo journalctl -u google-osconfig-agent --no-pager -n 50
sudo systemctl status google-cloud-ops-agent
```

# GCP Professional Cloud DevOps Engineer Lab 85

## Agent Policies for Google Cloud Ops Agent

This lab demonstrates how to centrally manage the Google Cloud Ops Agent by using an **Ops Agent Policy** instead of installing the agent manually on each Compute Engine VM.

The objective is to ensure that every current and future VM automatically installs the Ops Agent and keeps it updated.

---

# Exam Question

> Your organization wants to collect system logs that will be used to generate dashboards in Cloud Operations for their Google Cloud project. You need to configure all current and future Compute Engine instances to collect the system logs, and you must ensure that the Ops Agent remains up to date.

Which solution should you choose?

- A. Use the gcloud CLI to install the Ops Agent on every VM.
- B. Install the agent manually from the Cloud Operations console.
- C. Create an Agent Policy.
- D. Install the Ops Agent by using a startup script.

Correct answer:

**C**

---

# Why C is Correct

An **Agent Policy** is the official Google Cloud mechanism for centrally managing the Google Cloud Ops Agent.

Instead of installing the agent manually on every VM, the policy is evaluated by the **OS Config Agent** running inside Compute Engine instances.

When a VM matches the policy:

- the Ops Agent is installed automatically
- upgrades are handled automatically
- new VMs receive the agent without additional configuration
- management is centralized

This is exactly what the question requires.

---

# Why D is Wrong

A startup script only executes when a VM boots.

Although it can install the Ops Agent, it has important limitations:

- existing VMs are not managed automatically
- agent upgrades are not handled
- changing the installation requires modifying the startup script
- there is no centralized lifecycle management

Startup scripts are useful for bootstrapping machines, but they are **not** a replacement for Agent Policies.

---

# Architecture

```text
                     +---------------------------+
                     |     Google Cloud Project  |
                     +-------------+-------------+
                                   |
                                   |
                        Agent Policy (Ops Agent)
                                   |
                  +----------------+----------------+
                  |                                 |
                  | Guest Policy                    |
                  |                                 |
        +---------v---------+             +---------v---------+
        | Compute Engine VM |             | Compute Engine VM |
        +-------------------+             +-------------------+
                  |                                 |
                  |                                 |
          Google OS Config Agent            Google OS Config Agent
                  |                                 |
                  +---------------+-----------------+
                                  |
                                  |
                    Automatically installs and updates
                         Google Cloud Ops Agent
                                  |
                     +------------+------------+
                     |                         |
                     |                         |
             Cloud Logging              Cloud Monitoring
                     |                         |
                     +------------+------------+
                                  |
                         Cloud Operations
```

---

# Terraform Resources

The Terraform configuration performs the following steps.

## 1. Enable Required APIs

Terraform enables:

- Compute Engine API
- OS Config API
- Cloud Logging API
- Cloud Monitoring API

These services are required before creating the policy.

---

## 2. Grant IAM Permissions

The Compute Engine default service account receives:

- roles/logging.logWriter
- roles/monitoring.metricWriter

These permissions allow the installed Ops Agent to write logs and metrics to Cloud Operations.

Without these IAM roles, the policy is created successfully, but the installation never completes.

---

## 3. Create the Agent Policy

Terraform executes:

```bash
gcloud beta compute instances ops-agents policies create ...
```

The policy contains:

- automatic upgrades enabled
- Debian 12 operating system
- europe-west1-b zone
- label selector

```text
ops-agent=true
```

Only VMs with this label receive the policy.

---

## 4. Create the Compute Engine VM

The VM includes:

- Debian 12
- enable-osconfig=TRUE metadata
- label

```text
ops-agent=true
```

The metadata starts the Google OS Config Agent.

---

# Installation Flow

```text
Terraform Apply
       |
       |
       v
Enable APIs
       |
       v
Create Agent Policy
       |
       v
Create VM
       |
       v
OS Config Agent starts
       |
       v
Downloads Guest Policy
       |
       v
Installs Google Cloud Ops Agent
       |
       v
Starts Google Cloud Ops Agent
       |
       v
Cloud Logging
Cloud Monitoring
```

---

# Verification

First, verify that the policy exists.

```bash
gcloud beta compute instances ops-agents policies list
```

Describe the policy.

```bash
gcloud beta compute instances ops-agents policies describe ops-agents-policy
```

Verify that the VM contains the correct label.

```bash
gcloud compute instances describe ops-agent-vm \
    --zone=europe-west1-b \
    --format="yaml(labels)"
```

Check that the OS Config Agent is running.

```bash
sudo systemctl status google-osconfig-agent
```

Finally, verify that the Google Cloud Ops Agent has been installed.

```bash
sudo systemctl status google-cloud-ops-agent
```

Expected result:

```text
Active: active (exited)
```

The installation log should contain messages similar to:

```text
Installing packages [google-cloud-ops-agent]

Installing software recipe set-ops-agent-version-0

All steps completed successfully
```

---

# Troubleshooting

Initially, the OS Config Agent produced the following error:

```text
LookupEffectiveGuestPolicies:
code: "NotFound"
```

The Agent Policy already existed, but the VM could not successfully complete the installation.

The issue was resolved by assigning the following IAM roles to the Compute Engine default service account:

- roles/logging.logWriter
- roles/monitoring.metricWriter

After applying these permissions, the OS Config Agent successfully:

- downloaded the Guest Policy
- installed the Google Cloud Ops Agent
- started the service automatically

The final logs confirmed a successful deployment.

---

# Exam Tip

Remember the difference between startup scripts and Agent Policies.

If the question mentions:

- automatic installation
- automatic updates
- centralized management
- current and future Compute Engine instances

the correct answer is almost always **Agent Policy**.

Startup scripts only execute during VM boot and do not provide centralized lifecycle management.