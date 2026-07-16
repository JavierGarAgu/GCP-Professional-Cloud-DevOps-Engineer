# Lab Q42 - Export Logs with Cloud Logging IAM Roles

## Scenario

An application is writing logs to **Google Cloud Logging** (formerly Stackdriver Logging). Some members of the operations team need permission to create and manage log exports.

The goal is to assign the correct IAM role without giving unnecessary permissions.

---

## Question

> You manage an application that is writing logs to Stackdriver Logging. You need to give some team members the ability to export logs. What should you do?

**A.** Grant the team members the IAM role of `logging.configWriter` on Cloud IAM.

**B.** Configure Access Context Manager to allow only these members to export logs.

**C.** Create and grant a custom IAM role with the permissions `logging.sinks.list` and `logging.sinks.get`.

**D.** Create an Organizational Policy in Cloud IAM to allow only these members to create log exports.

---

# Correct Answer

**A. Grant the team members the IAM role of `roles/logging.configWriter`.**

The **Logging Configuration Writer** role allows users to manage the configuration of Cloud Logging resources, including:

- Creating log sinks
- Updating log sinks
- Deleting log sinks
- Managing log exclusions

These permissions are required to export logs from Cloud Logging to another destination such as Cloud Storage, BigQuery or Pub/Sub.

The other answers are incorrect because:

- **B** uses Access Context Manager, which controls access based on security perimeters instead of IAM permissions.
- **C** only allows users to view log sinks, not create or modify them.
- **D** Organization Policies enforce organization-wide rules but do not grant IAM permissions.

---

# IAM Configuration

The most important part of this lab is assigning the correct IAM role.

```hcl
resource "google_project_iam_member" "logging_config_writer" {

  project = "devops-cert-labs"

  role = "roles/logging.configWriter"

  member = "serviceAccount:${google_service_account.logging_admin.email}"

}
```

This resource gives the service account permission to configure Cloud Logging resources, including log exports.

---

# Lab Architecture

```
                +----------------------+
                |   Compute Engine VM  |
                +----------+-----------+
                           |
                     Ops Agent
                           |
                           v
                 Cloud Logging
                           |
                  Log Sink (Export)
                           |
                           v
                Cloud Storage Bucket

        Logging Config Writer
                |
                v
      Can create and manage exports
```

The VM continuously generates application logs.

The Google Cloud Ops Agent collects these logs and sends them to Cloud Logging.

A Log Sink exports the collected logs to a Cloud Storage bucket.

A separate service account receives the `roles/logging.configWriter` IAM role, allowing it to manage the log export configuration.

---

# Terraform Resources

## Provider

The provider connects Terraform to the Google Cloud project and defines the default region and zone.

---

## Enable APIs

The following APIs are enabled:

- Compute Engine API
- Cloud Logging API
- Cloud Storage API

These services are required to create the VM, send logs and export them.

---

## Cloud Storage Bucket

A Cloud Storage bucket is created as the destination for exported logs.

```text
Cloud Logging
      │
      ▼
Cloud Storage Bucket
```

---

## Service Accounts

The lab creates two different service accounts.

### VM Service Account

Used by the virtual machine.

Permissions:

- Logging Writer
- Monitoring Metric Writer

This account only sends logs and metrics.

---

### Logging Configuration Service Account

This account represents the operations team.

It receives the following role:

```
roles/logging.configWriter
```

This allows it to manage Cloud Logging configuration.

---

## Virtual Machine

A Debian 12 virtual machine is deployed.

During startup it:

- Installs the Google Cloud Ops Agent
- Configures log collection
- Creates an application log file
- Continuously writes log entries

Example log:

```
INFO Application running
```

These logs are automatically uploaded to Cloud Logging.

---

## Log Sink

Terraform creates a Cloud Logging Log Sink.

```text
Cloud Logging
      │
      ▼
Cloud Storage
```

The sink exports all Compute Engine logs into the Cloud Storage bucket.

---

## Bucket IAM Permission

The Log Sink has its own service account.

Terraform grants it permission to write objects into the storage bucket.

Without this permission, the export would fail.

---

## Outputs

Terraform prints useful information after deployment:

- VM external IP
- Storage bucket name
- Log Sink name
- Logging Configuration service account

---

# Deployment

Initialize Terraform.

```bash
terraform init
```

Review the execution plan.

```bash
terraform plan
```

Deploy the infrastructure.

```bash
terraform apply
```

---

# Verification

Verify that the VM is running.

```bash
gcloud compute instances list
```

Check that logs are arriving.

```bash
gcloud logging read \
'resource.type="gce_instance"' \
--limit=10
```

List existing Log Sinks.

```bash
gcloud logging sinks list
```

Describe the Log Sink.

```bash
gcloud logging sinks describe application-export
```

Verify the Storage bucket.

```bash
gcloud storage buckets list
```

List exported log files.

```bash
gcloud storage ls gs://devops-cert-export-logs-demo
```

---

# What I Learned

In this lab I learned how Cloud Logging exports work and which IAM role is required to manage them.

I deployed a virtual machine that continuously generated logs, collected them with the Google Cloud Ops Agent and stored them in Cloud Logging.

Then I created a Log Sink to export those logs to a Cloud Storage bucket.

Finally, I granted the `roles/logging.configWriter` IAM role to a dedicated service account, demonstrating the correct permission required to create and manage log exports according to Google Cloud best practices.