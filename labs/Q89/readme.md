COMMANDS (execute pre trigger and post trigger to see the differences)
```
gcloud run revisions list --region=europe-west1
gcloud run services describe frontend --region=europe-west1 --format="yaml(status.traffic)"

#And end simulating that we add gradual rollout
gcloud run services update-traffic frontend --region=europe-west1 --to-tags=new-release=1
```

# Cloud Run Tagged Revision Deployment

## Overview

This lab demonstrates how to deploy a new version of an application to Google Cloud Run using **tagged revisions** and **no traffic**. The new revision can be tested independently before gradually receiving production traffic.

This deployment strategy minimizes the impact on users while allowing developers to validate a release in both staging and production.

The infrastructure is created with Terraform, while Cloud Build deploys a new Cloud Run revision.

---

# Exam Question

> You are building and deploying a microservice on Cloud Run for your organization. Your service is used by many applications internally. You are deploying a new release, and you need to test the new version extensively in the staging and production environments. You must minimize user and developer impact. What should you do?

**A**

Deploy the new version of the service to the staging environment. Split the traffic, and allow 1% of traffic through to the latest version. Test the latest version. If the test passes, gradually roll out the latest version to the staging and production environments.

**B**

Deploy the new version of the service to the staging environment. Split the traffic, and allow 50% of traffic through to the latest version. Test the latest version. If the test passes, send all traffic to the latest version. Repeat for the production environment.

**C**

Deploy the new version of the service to the staging environment with a new-release tag without serving traffic. Test the new-release version. If the test passes, gradually roll out this tagged version. Repeat for the production environment.

**D**

Deploy a new environment with the green tag to use as the staging environment. Deploy the new version of the service to the green environment and test the new version. If the tests pass, send all traffic to the green environment and delete the existing staging environment. Repeat for the production environment.

**Correct answer: C**

---

# Why C is Correct

Cloud Run supports multiple revisions of the same service.

A new revision can be deployed using:

- a unique tag
- no production traffic

Developers can test the revision using its own URL while production users continue using the stable revision.

Only after validation should production traffic be gradually moved to the new revision.

This approach minimizes risk and follows Google's recommended deployment strategy for Cloud Run.

---

# Why the Other Answers are Wrong

## A

Incorrect.

The application starts receiving production traffic before testing is complete.

Google recommends testing a tagged revision first.

---

## B

Incorrect.

Sending 50% of production traffic immediately is risky.

A gradual rollout should start with a very small percentage.

---

## D

Incorrect.

This is closer to a Blue/Green deployment.

Blue/Green performs a complete traffic switch between two environments.

The question explicitly requires gradual traffic migration.

---

# Architecture

```

                           Git Push
                               │
                               │
                     Cloud Build Trigger
                               │
                               ▼
                      Cloud Build Pipeline
                               │
                               │
                gcloud run deploy --no-traffic
                               │
                               ▼
                    Cloud Run Service
                               │
                ┌──────────────┴──────────────┐
                │                             │
                │                             │
        Revision 1                     Revision 2
          Stable                      new-release
        100% Traffic                  0% Traffic
                │                             │
                │                             │
         Production Users             Developers/Testers

```

---

# Initial Deployment

After Terraform creates the infrastructure, Cloud Run contains a single revision.

```

                     Cloud Run

                frontend Service
                       │
                       ▼

             frontend-00001
               Stable Version

                  100%
                    │
                    ▼
                 Users

```

Command:

```powershell
gcloud run revisions list --region=europe-west1
```

Example:

```
frontend-00001
```

---

# Pipeline Deployment

Cloud Build creates a new revision.

```

Cloud Build

        │

        ▼

gcloud run deploy
--tag=new-release
--no-traffic

        │

        ▼

Cloud Run

        │

        ├───────────────┐

        ▼               ▼

Revision 1         Revision 2
Stable             new-release

100%                  0%

```

Command:

```powershell
gcloud run revisions list --region=europe-west1
```

Example:

```
frontend-00001
frontend-00002
```

---

# Tagged Revision

The new revision receives its own URL.

```

Production URL

frontend.a.run.app

        │

        ▼

Revision 1

100%




Testing URL

new-release---frontend.a.run.app

        │

        ▼

Revision 2

0%

```

Developers can test the new version without affecting production users.

---

# Traffic Rollout

After testing, production traffic is gradually moved.

```

Step 1

Stable          New

99%              1%




Step 2

Stable          New

90%             10%




Step 3

Stable          New

50%             50%




Final

Stable          New

0%             100%

```

Commands:

```powershell
gcloud run services update-traffic frontend --region=europe-west1 --to-tags=new-release=1
```

```powershell
gcloud run services update-traffic frontend --region=europe-west1 --to-tags=new-release=10
```

```powershell
gcloud run services update-traffic frontend --region=europe-west1 --to-tags=new-release=50
```

```powershell
gcloud run services update-traffic frontend --region=europe-west1 --to-tags=new-release=100
```

---

# Infrastructure Created by Terraform

The `main.tf` creates:

- Cloud Run Service
- Artifact Registry repository
- Cloud Build API
- Cloud Run API
- IAM API
- Artifact Registry API
- Cloud Run Service Account
- Cloud Build Service Account
- IAM permissions
- Cloud Build Trigger

Terraform creates the infrastructure only once.

Cloud Build is responsible for creating new revisions.

---

# Deployment Flow

```

Terraform Apply

        │

        ▼

Cloud Infrastructure

        │

        ▼

Cloud Run Service

        │

        ▼

Initial Revision

        │

        ▼

Git Push

        │

        ▼

Cloud Build Trigger

        │

        ▼

Cloud Build

        │

        ▼

New Revision

(No Traffic)

        │

        ▼

Testing

        │

        ▼

Traffic Split

        │

        ▼

100% Production

```

---

# Useful Commands

List revisions

```powershell
gcloud run revisions list --region=europe-west1
```

Show traffic allocation

```powershell
gcloud run services describe frontend --region=europe-west1 --format="yaml(status.traffic)"
```

Update traffic

```powershell
gcloud run services update-traffic frontend --region=europe-west1 --to-tags=new-release=10
```

---

# Conclusion

This lab demonstrates Google's recommended deployment strategy for Cloud Run.

Instead of exposing users to an untested version, a new tagged revision is deployed without receiving production traffic. Developers validate the new release using its dedicated URL, and only after successful testing is traffic gradually shifted to the new revision.

This approach provides safer deployments, easier validation, and minimal impact on production users.