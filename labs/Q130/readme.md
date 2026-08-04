COMMANDS
```
# Outputs
$LOGGING_PROJECT = terraform output -raw logging_project
$APP1_PROJECT    = terraform output -raw app1_project
$APP2_PROJECT    = terraform output -raw app2_project
$BUCKET          = terraform output -raw bucket_name

# Sink writer identities
$APP1_WRITER = (gcloud logging sinks describe central-sink --project=$APP1_PROJECT --format="value(writerIdentity)")
$APP2_WRITER = (gcloud logging sinks describe central-sink --project=$APP2_PROJECT --format="value(writerIdentity)")

# Grant bucket writer on destination project
gcloud projects add-iam-policy-binding $LOGGING_PROJECT `
    --member="$APP1_WRITER" `
    --role="roles/logging.bucketWriter"

gcloud projects add-iam-policy-binding $LOGGING_PROJECT `
    --member="$APP2_WRITER" `
    --role="roles/logging.bucketWriter"

# Wait for IAM propagation
Start-Sleep -Seconds 60

# Generate logs
gcloud logging write app-log "Hello from APP1" --project=$APP1_PROJECT
gcloud logging write app-log "Hello from APP2" --project=$APP2_PROJECT

Start-Sleep -Seconds 60

# Create Team A Log View
gcloud logging views create team-a `
    --project=$LOGGING_PROJECT `
    --location=global `
    --bucket=$BUCKET `
    --log-filter="resource.labels.project_id=\"$APP1_PROJECT\""

# Create Team B Log View
gcloud logging views create team-b `
    --project=$LOGGING_PROJECT `
    --location=global `
    --bucket=$BUCKET `
    --log-filter="resource.labels.project_id=\"$APP2_PROJECT\""

# List views
gcloud logging views list `
    --project=$LOGGING_PROJECT `
    --location=global `
    --bucket=$BUCKET

# Read Team A
gcloud logging read "*" `
    --project=$LOGGING_PROJECT `
    --location=global `
    --bucket=$BUCKET `
    --view=team-a `
    --limit=10 `
    --freshness=24h

# Read Team B
gcloud logging read "*" `
    --project=$LOGGING_PROJECT `
    --location=global `
    --bucket=$BUCKET `
    --view=team-b `
    --limit=10 `
    --freshness=24h

# Read All Logs
gcloud logging read "*" `
    --project=$LOGGING_PROJECT `
    --location=global `
    --bucket=$BUCKET `
    --view=_AllLogs `
    --limit=50 `
    --freshness=24h

# Verify sink configuration
gcloud logging sinks describe central-sink --project=$APP1_PROJECT
gcloud logging sinks describe central-sink --project=$APP2_PROJECT
```

# Q130 - Centralized Cloud Logging with Log Views

This lab demonstrates how to centralize logs from multiple Google Cloud projects into a dedicated Logging project while restricting access through Log Views. This matches the recommended solution for scenarios where each application team should only access its own logs, while the Operations team can access every log.

```
                    +----------------------+
                    |   Logging Project    |
                    |----------------------|
                    |  Log Bucket          |
                    |  central-logs        |
                    |                      |
                    |  +---------------+   |
                    |  | Team A View   |   |
                    |  +---------------+   |
                    |                      |
                    |  +---------------+   |
                    |  | Team B View   |   |
                    |  +---------------+   |
                    |                      |
                    |  +---------------+   |
                    |  | _AllLogs View |   |
                    |  +---------------+   |
                    +----------^-----------+
                               |
                 Log Sinks     |
            +------------------+------------------+
            |                                     |
            |                                     |
+------------------------+           +------------------------+
|      APP1 Project      |           |      APP2 Project      |
|------------------------|           |------------------------|
| Application Logs       |           | Application Logs       |
|                        |           |                        |
|  Central Log Sink      |           |  Central Log Sink      |
+------------------------+           +------------------------+
```

---

## Architecture

Three Google Cloud projects are created.

- Logging Project
- Application Project 1
- Application Project 2

The logging project contains a custom Log Bucket named:

```
central-logs
```

Both application projects create a Logging Sink that exports every log entry into this central bucket.

Each sink uses its own service account (Writer Identity), which receives the following IAM permission on the destination project:

```
roles/logging.bucketWriter
```

---

## Infrastructure

Terraform creates:

- Three Google Cloud projects
- Logging API
- Central Log Bucket
- Two Project Log Sinks
- IAM permissions for sink writer identities
- Terraform outputs

---

## Testing

Test logs are generated from both application projects.

```
APP1
 │
 ├── Hello from APP1
 │
 ▼
 Central Sink
 │
 ▼
 central-logs

APP2
 │
 ├── Hello from APP2
 │
 ▼
 Central Sink
 │
 ▼
 central-logs
```

---

## Log Views

Two custom Log Views are created.

### Team A

Only displays logs generated by APP1.

```
resource.labels.project_id="APP1_PROJECT"
```

### Team B

Only displays logs generated by APP2.

```
resource.labels.project_id="APP2_PROJECT"
```

Operations can use:

```
_AllLogs
```

to access every log stored in the bucket.

---

## Verification

The lab verifies:

- Sink creation
- Writer identities
- IAM permissions
- Log Bucket
- Custom Log Views
- Reading logs through Team A View
- Reading logs through Team B View
- Reading all logs through `_AllLogs`

---

## Exam Concept

This lab demonstrates why the correct answer is:

**C**

Create Log Views for each project team so they only see their own application logs, while granting the Operations team access to the `_AllLogs` view inside the centralized Logging project.

This solution provides centralized logging, enforces least privilege, minimizes administrative overhead, and avoids additional storage costs such as exporting logs to BigQuery.