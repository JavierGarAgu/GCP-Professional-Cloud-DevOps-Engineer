COMMANDS (INSIDE THE LOGGING MACHINE)
```
curl -fsSL https://toolbelt.treasuredata.com/sh/install-debian-bookworm-fluent-package5-lts.sh | sudo sh

sudo mkdir -p /var/log/demo

cat <<'EOF' | sudo tee /var/log/demo/app.log
{"user":"john","email":"john@example.com","phone":"600123456","credit_card":"4111111111111111","action":"login"}
EOF

cat <<'EOF' | sudo tee /etc/fluent/fluent.conf
<source>
  @type tail
  path /var/log/demo/app.log
  pos_file /var/log/demo/app.pos
  tag demo.logs
  format json
</source>

<filter demo.logs>
  @type record_transformer
  remove_keys email,phone,credit_card
</filter>

<match demo.logs>
  @type stdout
</match>
EOF

sudo systemctl stop fluentd 2>/dev/null || true

sudo /opt/fluent/bin/fluentd -c /etc/fluent/fluent.conf &

sleep 5

echo '{"user":"alice","email":"alice@test.com","phone":"123456789","credit_card":"4111111111111111","action":"payment"}' | sudo tee -a /var/log/demo/app.log

sleep 3

sudo pkill -f '/opt/fluent/bin/fluentd'
```

# Lab: Preventing PII Leakage in Cloud Logging with Fluentd Record Transformer

## Overview

This lab demonstrates how to prevent Personally Identifiable Information (PII) from reaching Google Cloud Logging by filtering sensitive fields before log records leave the virtual machine. The solution reproduces the scenario evaluated in the Google Professional Cloud DevOps Engineer certification, where the objective is to sanitize log entries as early as possible in the logging pipeline.

The infrastructure is deployed with Terraform and consists of a custom Virtual Private Cloud (VPC), a Compute Engine virtual machine, a dedicated service account, IAM permissions, and the required Google Cloud APIs. Inside the virtual machine, Fluentd is configured to monitor a log file, remove sensitive fields using the `record_transformer` filter plugin, and forward only the sanitized records.

---

# Exam Question

You are running an application on Compute Engine and collecting logs through Stackdriver. You discover that some personally identifiable information (PII) is leaking into certain log entry fields. You want to prevent these fields from being written in new log entries as quickly as possible.

**Correct answer: A**

> Use the filter-record-transformer Fluentd filter plugin to remove the fields from the log entries in flight.

The key phrase in the question is **"in flight"**. The objective is not to modify historical logs or wait for the application to be fixed, but to intercept new log records while they are being processed by the logging agent. This approach ensures that Cloud Logging never receives the sensitive information.

---

# Terraform Infrastructure

## Provider Configuration

The configuration uses the Google provider version 5.x and targets the `devops-cert-labs-v3` project in the `europe-west1` region.

This establishes the deployment environment and guarantees compatibility with the resources created throughout the lab.

---

## Required APIs

Several Google Cloud services are enabled before any infrastructure is provisioned.

* Compute Engine API
* Cloud Logging API
* Cloud Monitoring API
* IAM API
* Service Usage API

Enabling these services through Terraform guarantees that the deployment is completely reproducible without requiring manual preparation of the project.

---

## Service Account

A dedicated service account is created for the virtual machine instead of using the default Compute Engine service account.

The account receives the following permissions:

* `roles/logging.logWriter`
* `roles/monitoring.metricWriter`

Using a dedicated identity follows the principle of least privilege and isolates the permissions required by the logging workload.

---

## Networking

The lab deploys a custom VPC instead of relying on the default network.

The network includes:

* Custom VPC
* Custom subnet
* Public external IP
* Firewall rule allowing SSH access

Creating a dedicated network reproduces a production-like deployment where networking resources are explicitly managed rather than inherited from Google's default configuration.

---

## Compute Engine Instance

The Compute Engine instance represents an application server producing log records containing sensitive information.

The startup script performs the initial operating system preparation and creates a sample log file located at:

```text
/var/log/demo/app.log
```

The log contains fields such as:

* user
* email
* phone
* credit_card
* action

This intentionally simulates an application leaking personal information into its logs.

---

# Fluentd Configuration

Fluentd monitors the application log using the Tail input plugin.

```text
Application

↓

/var/log/demo/app.log

↓

Fluentd Tail Source
```

Every new JSON record is parsed and enters Fluentd's processing pipeline.

---

## Record Transformer Filter

The most important component of the lab is the filter configuration.

```text
<filter demo.logs>
  @type record_transformer
  remove_keys email,phone,credit_card
</filter>
```

This filter removes the sensitive fields before the log record reaches its destination.

The original log generated by the application is:

```json
{
  "user":"alice",
  "email":"alice@test.com",
  "phone":"123456789",
  "credit_card":"4111111111111111",
  "action":"payment"
}
```

After Fluentd processes the record, the forwarded log becomes:

```json
{
  "user":"alice",
  "action":"payment"
}
```

The original application log file remains unchanged because Fluentd does not edit source files. Instead, it transforms each record in memory while it is being processed.

---

## Output Plugin

For demonstration purposes, the lab uses the `stdout` output plugin.

```text
<match demo.logs>
  @type stdout
</match>
```

This allows the transformed records to be displayed directly in the terminal.

In a production Google Cloud environment, this output would typically be replaced by Cloud Logging, meaning that only the sanitized log entries would be stored centrally.

---

# Logging Pipeline

The complete processing pipeline implemented in this lab is:

```text
Application

↓

Log File

↓

Fluentd Tail Source

↓

Record Transformer Filter

↓

Sensitive Fields Removed

↓

Cloud Logging
```

The filtering stage occurs before Cloud Logging receives the record, ensuring that confidential information never reaches the centralized logging platform.

---

# Why Option A Is Correct

Option A applies filtering directly inside the logging agent.

Because the sensitive fields are removed before transmission, every new log entry arriving at Cloud Logging is already sanitized.

This solution provides immediate mitigation without requiring application modifications or additional processing stages.

---

# Why Option B Is Incorrect

The `fluent-plugin-record-reformer` plugin is designed to modify or restructure records rather than serving as the recommended mechanism for removing sensitive fields in this scenario.

The exam specifically evaluates the use of the Fluentd filter plugin responsible for removing fields while records are being processed.

---

# Why Option C Is Incorrect

Waiting for developers to modify the application does not solve the immediate security problem.

Until a new application version is deployed, every new log entry continues exposing sensitive information.

This approach increases compliance risks and allows confidential data to continue being stored.

---

# Why Option D Is Incorrect

Storing log entries in Cloud Storage before sanitizing them introduces unnecessary complexity.

The sensitive information is already written to Cloud Storage before the Cloud Function removes it, meaning the exposure has already occurred.

In addition, this architecture increases latency, operational complexity, and infrastructure costs compared to filtering directly inside the logging agent.

---

# Technical Conclusion

This lab demonstrates one of the fundamental principles of secure observability: sanitize telemetry as close as possible to its source.

By configuring Fluentd with the `record_transformer` filter, sensitive fields are removed while log records are still in transit between the application and the logging backend. As a result, Cloud Logging only stores sanitized records, reducing compliance risks and preventing accidental exposure of personal information.

This implementation directly matches the architecture evaluated in the Google Professional Cloud DevOps Engineer certification and explains why **Option A** is the correct answer.

