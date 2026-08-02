COMMANDS

```
$LOG_BUCKET = terraform output -raw log_bucket

$SINK = terraform output -raw sink_name

gcloud logging buckets describe $LOG_BUCKET `
--location=global

gcloud logging buckets describe $LOG_BUCKET `
--location=global `
--format="value(retentionDays)"

gcloud logging sinks list

gcloud logging sinks describe $SINK

gcloud logging write client-demo "Cloud Run log test 1"

gcloud logging write client-demo "Cloud Run log test 2"

gcloud logging write client-demo "Cloud Run log test 3"

gcloud logging read 'logName="projects/devops-cert-labs-v4/logs/client-demo"' --limit=5

gcloud logging buckets describe $LOG_BUCKET `
--location=global
```

# Q117 - Export Cloud Run and Cloud Functions Logs with Cloud Logging Buckets

## Overview

This lab demonstrates the recommended Google Cloud solution for retaining application logs for one year without modifying application code.

The scenario is based on applications running in Cloud Run and Cloud Functions. These services automatically write logs to Cloud Logging. Instead of changing the application to send logs somewhere else, Cloud Logging exports every log entry into a dedicated Logging Bucket that keeps the logs for 365 days.

This approach minimizes operational overhead because the applications continue using the native Google Cloud logging system.

## Question

You are building and running client applications in Cloud Run and Cloud Functions. Your client requires that all logs must be available for one year so that the client can import the logs into their logging service. You must minimize required code changes.

**What should you do?**

**A.** Update all Cloud Run services and Cloud Functions to send logs to both Cloud Logging and the client's logging service.

**B.** Export all logs to Pub/Sub and let the client consume them.

**C.** Store logs directly in Cloud Storage by modifying every application.

**D.** Create a Cloud Logging Bucket with 365-day retention and configure a Logging Sink to export logs into that bucket.

## Correct Answer

**D**

Cloud Run and Cloud Functions already integrate with Cloud Logging automatically.

Instead of changing application code, create a Logging Bucket with the required retention period and configure a Logging Sink that exports all logs into that bucket.

The client can later access the bucket using IAM permissions.

This solution:

- requires no application changes
- uses managed Google Cloud services
- keeps logs for one year
- minimizes operational overhead

## Architecture

```text
                    +----------------------+
                    |   Cloud Run Service  |
                    +----------+-----------+
                               |
                               |
                    +----------v-----------+
                    | Cloud Functions      |
                    +----------+-----------+
                               |
                               |
                               v
                  +---------------------------+
                  |     Cloud Logging         |
                  +-------------+-------------+
                                |
                         Logging Sink
                                |
                                v
                +-------------------------------+
                | Cloud Logging Bucket          |
                | Retention: 365 Days           |
                +---------------+---------------+
                                |
                                |
                                v
                     Client reads exported logs
```

## Terraform Resources

The Terraform configuration creates:

- Logging API
- Cloud Logging Bucket
- 365-day retention policy
- Project Logging Sink
- Outputs for bucket and sink verification

## Verification Steps

Generate several log entries.

```bash
gcloud logging write client-demo "Cloud Run log test 1"

gcloud logging write client-demo "Cloud Run log test 2"

gcloud logging write client-demo "Cloud Run log test 3"
```

Verify the logs exist.

```bash
gcloud logging read 'logName="projects/devops-cert-labs-v4/logs/client-demo"' --limit=5
```

Verify the Logging Bucket.

```bash
gcloud logging buckets describe client-log-archive \
--location=global
```

Verify the retention period.

```bash
gcloud logging buckets describe client-log-archive \
--location=global \
--format="value(retentionDays)"
```

Expected output:

```text
365
```

Verify the Logging Sink.

```bash
gcloud logging sinks describe client-log-export
```

## Why the Other Answers Are Incorrect

### A

Incorrect.

Applications should not be modified to send logs to multiple destinations. Cloud Logging already receives logs automatically.

### B

Incorrect.

Pub/Sub is useful for streaming logs, but it is not intended for long-term retention.

### C

Incorrect.

Updating every application to write files into Cloud Storage increases maintenance and violates the requirement to minimize code changes.

## Key Learning Points

- Cloud Run automatically sends logs to Cloud Logging.
- Cloud Functions automatically send logs to Cloud Logging.
- Logging Buckets provide managed log retention.
- Logging Sinks export logs without modifying applications.
- IAM controls who can access exported logs.
- This is the recommended solution when long-term log retention is required with minimal operational overhead.