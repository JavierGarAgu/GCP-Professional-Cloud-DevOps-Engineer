COMMANDS

```
$URL = gcloud run services describe reliability-lab `
  --region=europe-west1 `
  --format="value(status.url)"

#D CORRECT
gcloud scheduler jobs list --location=europe-west1

gcloud scheduler jobs run synthetic-user-check --location=europe-west1

curl $URL
curl $URL
curl $URL

#E CORRECT
gcloud logging read \
'resource.type="cloud_run_revision" AND logName:"requests"' \
--limit=20
```

# Q41 - Measure Application Reliability Without Engineering Changes

## Scenario

A high-traffic web application is running on Google Cloud Platform (GCP). The goal is to measure application reliability from the user's perspective **without modifying the application code**.

The correct answers are:

- **D. Create new synthetic clients to simulate a user journey using the application.**
- **E. Use current and historic Request Logs to trace customer interaction with the application.**

This lab demonstrates both solutions using Cloud Run, Cloud Scheduler and Cloud Logging.

---

# Architecture

```
                +--------------------+
                |  Cloud Scheduler   |
                | Synthetic Client   |
                +---------+----------+
                          |
                     HTTP Request
                          |
                          v
                 +------------------+
                 |    Cloud Run     |
                 | Web Application  |
                 +---------+--------+
                           |
                  Automatic Request Logs
                           |
                           v
                  +-------------------+
                  |  Cloud Logging    |
                  | Request Logs      |
                  +-------------------+
```

The application is deployed on Cloud Run.

Cloud Scheduler acts as a synthetic client by sending HTTP requests every five minutes.

Cloud Logging automatically stores every request, including response status, latency, request URL and timestamps.

---

# Terraform Resources

## Provider

The provider configures the Google Cloud project and the default location.

```hcl
provider "google" {
  project = "devops-cert-labs"
  region  = "europe-west1"
  zone    = "europe-west1-b"
}
```

---

## Google Project Services

The following APIs are enabled:

- Cloud Run API
- Cloud Scheduler API
- Cloud Logging API

These services are required to deploy the application and collect logs.

---

## Cloud Run

A simple public web application is deployed using the official Cloud Run Hello container.

Cloud Run automatically generates HTTP Request Logs, so no application changes are required.

---

## IAM

The application is publicly accessible.

A Service Account is also created so Cloud Scheduler can invoke the Cloud Run service securely.

---

## Cloud Scheduler

Cloud Scheduler sends a GET request every five minutes.

This simulates a real user accessing the application and continuously verifies that it is available.

This resource represents the **synthetic client** mentioned in the exam question.

---

# Verification

Deploy the infrastructure.

```powershell
terraform init

terraform apply -auto-approve
```

Get the application URL.

```powershell
gcloud run services describe reliability-lab `
--region=europe-west1 `
--format="value(status.url)"
```

Run the synthetic client manually.

```powershell
gcloud scheduler jobs run synthetic-user-check --location=europe-west1
```

Generate additional user requests.

```powershell
curl $URL

curl $URL

curl $URL
```

Read the Request Logs.

```powershell
gcloud logging read `
'resource.type="cloud_run_revision" AND logName:"requests"' `
--limit=20 `
--format="table(timestamp,httpRequest.requestMethod,httpRequest.requestUrl,httpRequest.status,httpRequest.latency)"
```

Display complete request information.

```powershell
gcloud logging read `
'resource.type="cloud_run_revision"' `
--limit=20
```

---

# Expected Results

The Request Logs should contain information similar to:

- HTTP Method
- Request URL
- Status Code
- Latency
- Timestamp
- Remote IP
- User Agent

Cloud Scheduler should appear as a successful request, and the manual requests generated with `curl` should also be visible.

---

# Why D is Correct

Cloud Scheduler creates automatic HTTP requests that simulate real users.

This is a synthetic client used to verify application availability and reliability without changing the application.

---

# Why E is Correct

Cloud Logging stores current and historical Request Logs automatically.

These logs allow engineers to analyze user traffic, response times and failures without modifying the application code.

This follows Site Reliability Engineering (SRE) practices by measuring reliability from the user's perspective while avoiding engineering changes.