COMMANDS
```
#if already exists
terraform import google_app_engine_application.app devops-cert-labs-v2
gcloud app deploy app.yaml
$DEFAULT_HOSTNAME=gcloud app describe --format="value(defaultHostname)"
curl.exe "https://$DEFAULT_HOSTNAME"
curl.exe "https://$DEFAULT_HOSTNAME/health"
curl.exe "https://$DEFAULT_HOSTNAME/metrics"
curl.exe "https://$DEFAULT_HOSTNAME/reset"
change actual app.yaml:

#min_idle_instances: 0

.\hey.exe -n 1000 -c 100 https://$DEFAULT_HOSTNAME/

.\hey.exe -n 5000 -c 100 https://$DEFAULT_HOSTNAME/


#min_idle_instances: 2

try again

gcloud app deploy app.yaml --quiet
```

# README - App Engine Idle Instances Lab (Professional Cloud DevOps Engineer)

## Overview

This lab is based on a real Google Cloud Professional Cloud DevOps Engineer certification scenario.

The objective is to understand how **App Engine automatic scaling** works and why configuring **additional idle instances** is the correct solution when an application suffers high latency after a traffic spike.

Unlike many theoretical exercises, this lab reproduces the behavior of cold starts, allowing you to observe how keeping warm instances improves user experience.

---

# Exam Question

You support a web application that runs on **App Engine** and uses **Cloud SQL** and **Cloud Storage**.

After a short traffic spike, you notice:

* Request latency becomes very high.
* CPU utilization increases.
* More application processes are created.
* Traffic later returns to normal.
* Latency remains high.
* Cloud SQL and Cloud Storage are healthy.
* No application deployment occurred.
* Users do not receive additional errors.

Another traffic spike is expected soon.

What should you do?

**A.** Upgrade Cloud Storage buckets to Multi-Regional.

**B.** Enable High Availability on Cloud SQL.

**C.** Move the application from App Engine to Compute Engine.

**D.** Modify the App Engine configuration to have additional idle instances.

Correct answer:

**D**

---

# Why Answer D Is Correct

App Engine automatically creates and removes instances according to incoming traffic.

When traffic suddenly increases, new instances must start.

Starting a new instance requires:

* Loading the runtime
* Loading the application
* Initializing dependencies
* Opening connections

This process is called a **cold start**.

Cold starts introduce additional latency.

If App Engine removes every idle instance after traffic decreases, the next traffic spike forces App Engine to create new instances again.

The result is increased latency even though the infrastructure itself is healthy.

By configuring:

```yaml
min_idle_instances: 2
```

App Engine always keeps at least two instances running.

When traffic suddenly increases, these instances immediately begin serving requests without waiting for a cold start.

Latency becomes significantly lower.

---

# Why The Other Answers Are Wrong

## Option A

Changing Cloud Storage from Regional to Multi-Regional does not solve the problem.

The latency appears after application scaling.

Cloud Storage is not the bottleneck.

---

## Option B

Cloud SQL High Availability protects against database failures.

The database is healthy.

There are no database failures.

High Availability would increase availability, not reduce cold start latency.

---

## Option C

Moving the application to Compute Engine would require managing your own infrastructure.

The issue is not App Engine itself.

The problem is simply the automatic scaling configuration.

---

# Lab Architecture

Terraform creates:

* App Engine application
* Cloud Storage bucket
* Required Google APIs
* Local application files

Terraform generates:

* app.yaml
* main.py
* requirements.txt

The actual deployment is performed manually using:

```bash
gcloud app deploy app.yaml
```

This approach avoids using local-exec provisioners and keeps infrastructure provisioning separated from application deployment.

---

# Infrastructure Created

Terraform enables:

* App Engine API
* Cloud Storage API

Terraform creates:

* App Engine Application
* Cloud Storage Bucket

Terraform also generates the Flask application locally.

No Cloud SQL instance is created because it is not necessary to demonstrate the scaling behavior being evaluated by the certification exam.

Cloud SQL is only mentioned in the question to provide context.

---

# Flask Application

The application exposes four endpoints.

## /

Main endpoint.

It simulates a cold start.

First request:

* waits 5 seconds

Following requests:

* wait between 50 and 150 milliseconds

The response includes:

* latency
* cold start status
* process ID

Example:

```json
{
  "message":"App Engine Idle Instances Lab",
  "latency_ms":5000,
  "cold_start":true
}
```

---

## /health

Simple health endpoint.

Returns:

```json
{
  "status":"healthy"
}
```

---

## /metrics

Returns instructions about the exercise.

---

## /reset

Forces the next request to become another cold start.

---

# Deployment Procedure

Deploy infrastructure:

```bash
terraform apply
```

Deploy the application:

```bash
gcloud app deploy app.yaml
```

Obtain the application URL:

```bash
gcloud app describe --format="value(defaultHostname)"
```

Store it:

```powershell
$DEFAULT_HOSTNAME = gcloud app describe --format="value(defaultHostname)"
```

Test the application:

```bash
curl https://$DEFAULT_HOSTNAME
```

Health endpoint:

```bash
curl https://$DEFAULT_HOSTNAME/health
```

Metrics endpoint:

```bash
curl https://$DEFAULT_HOSTNAME/metrics
```

Reset cold start:

```bash
curl https://$DEFAULT_HOSTNAME/reset
```

---

# Load Testing

Generate traffic using:

```bash
hey -n 5000 -c 100 https://$DEFAULT_HOSTNAME/
```

The first request usually produces something similar to:

```json
{
    "cold_start": true,
    "latency_ms": 5000
}
```

Subsequent requests:

```json
{
    "cold_start": false,
    "latency_ms": 120
}
```

This demonstrates the effect of a cold start.

---

# Simulating The Exam Solution

Initially, app.yaml contains:

```yaml
automatic_scaling:

  min_idle_instances: 0
```

Deploy:

```bash
gcloud app deploy app.yaml
```

Generate traffic.

Observe latency.

Now modify:

```yaml
automatic_scaling:

  min_idle_instances: 2
```

Deploy again:

```bash
gcloud app deploy app.yaml
```

Generate the same traffic again.

The application now keeps warm instances available.

Future requests experience fewer cold starts.

This reproduces the exact scenario described in the certification exam.

---

# Problems Encountered During Development

Several real issues appeared while building this laboratory.

These are valuable because they are common when working with App Engine.

## App Engine Already Exists

Terraform returned:

```text
Error 409
Application already exists
```

App Engine applications are unique inside a project.

Once created, they cannot be recreated.

The correct solution is importing the resource into Terraform or reusing the existing application.

---

## Cloud SQL Creation Time

Cloud SQL provisioning required several minutes.

Eventually Cloud SQL was removed from the laboratory because it is unrelated to the learning objective.

Keeping the lab focused on App Engine makes deployment much faster.

---

## Incorrect PORT Variable

Initially the generated app.yaml contained:

```yaml
entrypoint: gunicorn -b :\$PORT main:app
```

This caused:

```text
'$PORT' is not a valid port number
```

The issue was caused by escaping the variable incorrectly while generating the file from Terraform.

After correcting the generated configuration, the application deployed successfully.

---

## Reading Old Logs

One confusing problem occurred during troubleshooting.

Even after deploying a corrected version, the logs still displayed:

```text
'$PORT' is not a valid port number
```

At first it appeared that the deployment had failed again.

However, the logs belonged to an older App Engine version.

The current deployment was already working correctly.

This demonstrates why it is important to verify:

* deployed versions
* active traffic
* log timestamps

before assuming that a deployment has failed.

---

# Lessons Learned

This laboratory demonstrates several important Professional Cloud DevOps Engineer concepts:

* App Engine automatic scaling
* Cold starts
* Idle instances
* Warm instances
* Application latency
* Traffic spikes
* Infrastructure as Code
* Terraform resource generation
* Manual application deployment
* Troubleshooting App Engine deployments
* Understanding App Engine logs

Most importantly, it teaches the reasoning behind the certification question instead of simply memorizing the correct answer.

Understanding why idle instances reduce latency makes it much easier to answer similar questions during the exam.
