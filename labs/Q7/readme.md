# Spinnaker - Basic Notes

## What is Spinnaker?

Spinnaker is a **Continuous Delivery (CD)** platform.

Its job is **not** to build the application.

Its job is **not** to create Docker images.

Its job is to **control and automate deployments**.

Think of Spinnaker as the **manager** of the deployment process.

---

# What does Spinnaker do?

Spinnaker decides:

- What version to deploy.
- Where to deploy it.
- When to deploy it.
- If the deployment is successful.
- If it must rollback.

---

# Example

Without Spinnaker:

```
GitHub

↓

Cloud Build

↓

Build Docker image

↓

Push image

↓

kubectl apply

↓

Done
```

With Spinnaker:

```
GitHub

↓

Cloud Build

↓

Docker Image

↓

Deploy Canary

↓

Wait 10 minutes

↓

Check metrics

↓

Everything OK?

↓

YES

↓

Deploy to Production
```

Spinnaker controls the deployment step.

---

# What can Spinnaker do?

- Canary Deployments
- Blue/Green Deployments
- Rolling Updates
- Automatic Rollbacks
- Manual Approvals
- Multi-cloud Deployments
- Deployment Pipelines

---

# Canary Deployment

A canary deployment sends the new version to only a small number of users.

```
100 Users

│

├── 95 → Current Version

└── 5 → Canary Version
```

If everything is OK, Spinnaker deploys the new version to everyone.

If something is wrong, Spinnaker rolls back automatically.

---

# What is Canary Analysis?

Canary Analysis compares two versions of the application.

Example:

```
Current Version

VS

Canary Version
```

Spinnaker checks metrics like:

- Response time
- CPU usage
- Memory usage
- Error rate
- Request latency

If the canary has good metrics, the deployment continues.

If the metrics are bad, Spinnaker stops the deployment.

---

# Why is Answer A correct?

Question:

> Your application has an in-memory cache that loads objects at startup.

The production application has been running for a long time.

Its cache is already full.

```
Production

Cache = Warm
```

The canary has just started.

Its cache is empty.

```
Canary

Cache = Cold
```

This is not a fair comparison.

Instead, Spinnaker deploys **another copy of the current production version**.

```
Current Production (running)

↓

New Deployment (same version)

↓

Compare

↓

Canary
```

Now both applications start with an empty cache.

The comparison is fair.

This is why the correct answer is:

**A. Compare the canary with a new deployment of the current production version.**

---

# Simple Car Example

Imagine two cars.

Car A has been driving for one hour.

The engine is already warm.

Car B has just started.

The engine is still cold.

If you compare fuel consumption now, the comparison is unfair.

Instead, start another Car A at the same time.

Now both engines are cold.

This is the same idea as a production baseline in Spinnaker.

---

# Easy Definition for the Exam

**Spinnaker is a Continuous Delivery platform that automates application deployments.**

It can:

- Deploy applications.
- Compare canary and production versions.
- Check metrics.
- Continue the deployment if everything is OK.
- Rollback automatically if something fails.

#######################################################
#
# CONNECT TO GKE
#
#######################################################

gcloud container clusters get-credentials spinnaker-canary-lab \
    --zone=europe-west1-b \
    --project=devops-cert-labs

#######################################################
#
# VERIFY NAMESPACE
#
#######################################################

# Check that the production namespace exists.

kubectl get namespaces

#######################################################
#
# VERIFY DEPLOYMENTS
#
#######################################################

# Check the three deployments created by Terraform.

kubectl get deployments -n production

#######################################################
#
# VERIFY PODS
#
#######################################################

# Check that one Pod is running for each deployment.

kubectl get pods -n production

#######################################################
#
# VERIFY IMAGES
#
#######################################################

# Current production version.

kubectl describe deployment production-current -n production

# Expected image:
# nginx:1.25

#######################################################

# New deployment of the current production version.
# This is the production baseline.

kubectl describe deployment production-baseline -n production

# Expected image:
# nginx:1.25

#######################################################

# Canary deployment.
# This is the new application version.

kubectl describe deployment canary -n production

# Expected image:
# nginx:1.26

#######################################################
#
# VERIFY LABELS
#
#######################################################

# Display labels for all Pods.

kubectl get pods -n production --show-labels

#######################################################
#
# VERIFY EVERYTHING
#
#######################################################

kubectl get all -n production

#######################################################
#
# EXAM SIMULATION
#
#######################################################

# Current Production
#
# Image:
# nginx:1.25
#
# Running for a long time.
#
# Cache = Warm

#######################################################

# Production Baseline
#
# Image:
# nginx:1.25
#
# New deployment.
#
# Cache = Cold

#######################################################

# Canary
#
# Image:
# nginx:1.26
#
# New deployment.
#
# Cache = Cold

#######################################################
#
# CANARY ANALYSIS (CONCEPT)
#
#######################################################

# WRONG

production-current

VS

canary

# The comparison is unfair because:
#
# Production cache = Warm
# Canary cache = Cold

#######################################################
#
# CORRECT
#
#######################################################

production-baseline

VS

canary

# Both applications have:
#
# Cold cache
# Fresh startup
# Same initial conditions
#
# This is a fair comparison.

#######################################################
#
# CORRECT EXAM ANSWER
#
#######################################################

# A
#
# Compare the canary with a new deployment
# of the current production version.