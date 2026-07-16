COMMANDS

```
#maybe is necesary to restart the agent service if race condition appears
sudo systemctl restart google-cloud-ops-agent
```

# Q38 - Protecting PII Logs with Cloud Logging

## Question

You are running an application on Compute Engine and collecting logs through Cloud Logging. Some Personally Identifiable Information (PII) is accidentally written to the logs. Every sensitive log starts with the text **userinfo**.

You want to store these sensitive logs in a secure Cloud Storage bucket for later review while preventing them from appearing in Cloud Logging.

**Correct answer: C**

* Create an **advanced log filter** matching `userinfo`.
* Create a **Cloud Storage log sink** using that filter.
* Create a **log exclusion** using the same filter.

> **Note:** In the real Google Cloud platform, log exclusions are applied during log ingestion. This means excluded logs are not stored in Cloud Logging and are not exported by sinks. The exam answer follows Google's recommended design, although the real behavior is different.

---

# Laboratory Overview

This lab creates a complete logging environment on Google Cloud.

Terraform performs the following tasks:

* Enables the Compute Engine, Cloud Logging and Cloud Storage APIs.
* Creates a Cloud Storage bucket to store sensitive logs.
* Creates a dedicated service account for the VM.
* Grants the VM permission to write logs (`roles/logging.logWriter`).
* Grants the VM permission to publish metrics (`roles/monitoring.metricWriter`).
* Deploys a Debian Compute Engine VM.
* Installs the Google Cloud Ops Agent automatically.
* Configures the Ops Agent to monitor `/var/log/application.log`.
* Starts a simple script that continuously writes normal logs and random **userinfo** entries.
* Creates a Cloud Logging sink that exports matching logs to Cloud Storage.
* Creates a log exclusion that filters out `userinfo` entries from Cloud Logging.

---

# Main.tf Explanation

## APIs

The project enables:

* Compute Engine
* Cloud Logging
* Cloud Storage

These services are required before any infrastructure is created.

---

## Storage Bucket

A Cloud Storage bucket is created to store sensitive log entries exported by the logging sink.

---

## Service Account

A dedicated service account is attached to the VM.

It receives:

* `roles/logging.logWriter`
* `roles/monitoring.metricWriter`

These permissions allow the Ops Agent to send logs and metrics.

---

## Compute Engine VM

Terraform deploys a Debian virtual machine.

During startup it:

* Installs the Google Cloud Ops Agent.
* Configures the agent to monitor `/var/log/application.log`.
* Creates a simple Bash script that continuously writes application logs.
* Randomly generates PII entries beginning with:

```
userinfo
```

Example:

```
INFO Application running normally
INFO userinfo email=user@example.com
```

---

## Log Sink

A Cloud Logging sink is created with the filter:

```
textPayload:"userinfo"
```

The destination is the Cloud Storage bucket.

---

## Log Exclusion

A project exclusion is also created with the same filter:

```
textPayload:"userinfo"
```

This prevents matching entries from remaining inside Cloud Logging.

---

# Useful Commands

## Check application log

```bash
sudo tail -f /var/log/application.log
```

---

## Verify Ops Agent status

```bash
sudo systemctl status google-cloud-ops-agent
```

---

## Verify Ops Agent configuration

```bash
sudo cat /etc/google-cloud-ops-agent/config.yaml
```

---

## Verify the log generator

```bash
ps aux | grep log-generator
```

---

## Verify the VM service account

```bash
curl -H "Metadata-Flavor: Google" \
http://metadata.google.internal/computeMetadata/v1/instance/service-accounts/default/email
```

---

## Check IAM roles

```powershell
gcloud projects get-iam-policy devops-cert-labs --flatten="bindings[].members" --filter="bindings.members:logging-demo@devops-cert-labs.iam.gserviceaccount.com"
```

---

## Verify the logging sink

```powershell
gcloud logging sinks describe pii-storage
```

---

## Verify the exclusion in Terraform

```powershell
terraform state show google_logging_project_exclusion.exclude_pii
```

---

## Search for PII logs

```powershell
gcloud logging read "textPayload:userinfo" --limit=1 --format=json
```

Expected result:

```
[]
```

because the exclusion removes the matching entries.

---

## Check the Cloud Storage bucket

```powershell
gcloud storage ls -r gs://devops-cert-pii-logs-demo
```

---

# Conclusion

This lab demonstrates how Cloud Logging filters can identify sensitive log entries and how Terraform automates the deployment of the required infrastructure.

It also shows an important real-world behavior: when a log exclusion matches an entry, the log is removed during ingestion. As a result, those entries are not available in Cloud Logging and are not exported by the logging sink, even though the certification exam considers option **C** to be the correct answer.
