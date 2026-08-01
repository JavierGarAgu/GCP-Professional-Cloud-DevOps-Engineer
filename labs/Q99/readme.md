# Q99 - Canary vs Blue/Green Deployment

## Overview

This lab focuses on understanding the differences between **Canary Deployment** and **Blue/Green Deployment**.

The infrastructure used for the deployment is the same one created in **Q89**, where Cloud Run, Artifact Registry, Cloud Build, IAM, and the deployment pipeline were provisioned using Terraform.

In **Q89**, the canary rollout is performed **manually** using Cloud Run traffic splitting commands after the deployment. The purpose of this lab is to understand when each deployment strategy should be used and why.

---

# Canary Deployment

A canary deployment releases the new application version to a **small percentage of users** while the stable version continues serving most production traffic.

```text
                    Users
                      |
          +-----------+-----------+
          |                       |
        95%                     5%
          |                       |
          v                       v
+------------------+    +------------------+
| Stable Version   |    | Canary Version   |
|      v1          |    |      v2          |
+------------------+    +------------------+
```

If monitoring shows that the new version is healthy, traffic is increased gradually.

```text
95% / 5%
      |
      v
90% / 10%
      |
      v
50% / 50%
      |
      v
0% / 100%
```

### When to use Canary

Use a canary deployment when:

* The application could not be fully load-tested.
* You want to validate the new version using real production traffic.
* You want to reduce deployment risk.
* You want to monitor latency, error rate, availability, or resource usage before completing the rollout.

### Advantages

* Low deployment risk.
* Progressive rollout.
* Easy rollback.
* Real production validation.

---

# Blue/Green Deployment

A blue/green deployment keeps two complete production environments.

* **Blue** is the current production environment.
* **Green** is the new application version.

Traffic is switched from one environment to the other in a single step.

```text
Before Deployment

        Users
          |
          v
+------------------+
| Blue Environment |
|    Production    |
+------------------+

+------------------+
| Green Environment|
|     Standby      |
+------------------+
```

After the deployment:

```text
        Users
          |
          v
+------------------+
| Green Environment|
|    Production    |
+------------------+

+------------------+
| Blue Environment |
|      Idle        |
+------------------+
```

If a problem occurs, traffic can immediately return to the Blue environment.

### When to use Blue/Green

Use a blue/green deployment when:

* The new version has already been fully tested.
* You need an immediate deployment.
* Fast rollback is required.
* You can maintain two production environments.

### Advantages

* Instant deployment.
* Very fast rollback.
* Minimal downtime.

---

# Comparison

| Feature               | Canary                            | Blue/Green               |
| --------------------- | --------------------------------- | ------------------------ |
| Traffic migration     | Gradual                           | Immediate                |
| Deployment risk       | Low                               | Medium                   |
| Production validation | Yes                               | No (full switch)         |
| Rollback              | Easy                              | Immediate                |
| Infrastructure cost   | Lower                             | Higher                   |
| Typical use case      | New features or uncertain changes | Fully validated releases |

---

# Q89 Relation

The infrastructure for this lab is provided by **Q89**.

The Terraform configuration deploys the Cloud Run service and the CI/CD pipeline.

After the deployment, the canary rollout is performed manually by updating the traffic distribution between Cloud Run revisions.

Example:

```bash
gcloud run services update-traffic frontend \
    --region=europe-west1 \
    --to-tags=new-release=1
```

This command sends a small percentage of production traffic to the new revision while the stable revision continues serving most users.

In a production environment, this traffic shift would normally be automated by a CI/CD pipeline together with Cloud Monitoring metrics.
