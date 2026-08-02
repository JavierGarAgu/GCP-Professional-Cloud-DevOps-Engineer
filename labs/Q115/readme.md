COMMANDS
```
$BUCKET = terraform output -raw bucket_name

gcloud logging sinks list

gcloud logging sinks describe archive-all-logs

gcloud storage buckets describe gs://$BUCKET

gcloud logging write terraform-demo "Compliance log test 1"

gcloud logging write terraform-demo "Compliance log test 2"

gcloud logging write terraform-demo "Compliance log test 3"

gcloud logging read 'logName="projects/devops-cert-labs-v4/logs/terraform-demo"' --limit=5

gcloud storage ls gs://$BUCKET

gcloud storage ls --recursive gs://$BUCKET

gcloud storage buckets describe gs://$BUCKET --format="value(retentionPolicy.retentionPeriod)"

gcloud storage buckets describe gs://$BUCKET
```

# Q115 - Long-Term Log Retention with Cloud Logging and Cloud Storage

## Overview

This lab demonstrates how to build a centralized log archival solution using Google Cloud managed services.

The original certification question requires storing organization logs for seven years while minimizing operational overhead and preventing accidental deletion.

In a personal Google Cloud project, it is not possible to create an Organization-level aggregated sink. Instead, this lab reproduces the same architecture at the project level while keeping the same design principles.

The solution uses:

* Cloud Logging
* Logging Sink
* Cloud Storage
* Retention Policy
* Bucket Lock (prepared but not enabled)

## Certification Question

Your company operates in a highly regulated environment and must keep every log for seven years.

The solution must:

* Use managed services.
* Minimize operational complexity.
* Prevent accidental deletion of stored logs.
* Protect against future configuration mistakes.

The correct answer is:

**B. Configure an aggregated sink at the organization level to export all logs into Cloud Storage with a seven-year retention policy and Bucket Lock.**

## Lab Architecture

```text
                  Google Cloud Project
                          │
                          │
                  Cloud Logging
                          │
                          ▼
                Project Logging Sink
                          │
                          ▼
            Cloud Storage Bucket
          (7-Year Retention Policy)
                          │
                          ▼
               Bucket Lock Ready
```

Real certification architecture:

```text
                   Organization
                        │
                        ▼
               Aggregated Logging Sink
                        │
                        ▼
                Cloud Storage Bucket
                        │
                        ▼
               7-Year Retention
                        │
                        ▼
                  Bucket Lock
```

## Infrastructure Created

Terraform creates the following resources:

* Cloud Logging API
* Cloud Storage API
* Cloud Storage bucket
* Seven-year retention policy
* Logging sink
* IAM permission allowing the sink to write into the bucket

## Log Flow

```text
Application
      │
      ▼
Cloud Logging
      │
      ▼
Logging Sink
      │
      ▼
Cloud Storage Bucket
      │
      ▼
Long-Term Archive
```

## Why Cloud Storage?

Cloud Storage is designed for durable long-term storage.

Advantages include:

* Low operational overhead
* High durability
* Retention policies
* Bucket Lock support
* Native integration with Cloud Logging

## Why Not BigQuery?

BigQuery is useful for querying logs.

This question focuses on compliance and long-term archival rather than analytics.

Cloud Storage is therefore the correct destination.

## Why Bucket Lock?

A retention policy can be modified by an administrator.

Bucket Lock makes the retention policy permanent.

Once locked:

* Retention cannot be reduced.
* Objects cannot be removed before the retention period expires.
* Compliance requirements are easier to satisfy.

For this lab, Bucket Lock is intentionally not enabled because it is irreversible.

## Lab Validation

The lab verifies:

* A Cloud Storage bucket is created.
* A Logging Sink exports logs to the bucket.
* The sink receives its own writer identity.
* IAM permissions allow the sink to write objects.
* The bucket uses a seven-year retention policy.

During testing, exported log files may not appear immediately.

Cloud Logging exports logs asynchronously and groups entries into batches before writing objects into Cloud Storage. In projects with very little log activity, this process can take several minutes.

## Key Learning Points

* Cloud Logging collects application and infrastructure logs.
* Logging Sinks export logs to external destinations.
* Cloud Storage is the preferred service for compliance archives.
* Retention Policies define how long logs must remain stored.
* Bucket Lock prevents accidental or intentional removal of retained logs.
* Organization-level Aggregated Sinks are the recommended design for enterprise environments, while this lab demonstrates the same concepts at the project level.

## Conclusion

This lab reproduces the architecture required by the certification question using resources available in a personal Google Cloud project.

Although it uses a project-level sink instead of an organization-level aggregated sink, it demonstrates the same operational concepts:

* Centralized log export
* Managed storage
* Seven-year retention
* Immutable archive design through Bucket Lock
