# Q111 - Blue/Green Deployment Rollback in Google Kubernetes Engine

## Scenario

An application is deployed in Google Kubernetes Engine (GKE) using the Blue/Green deployment strategy.

Two deployments exist:

* **app-blue** (stable production version)
* **app-green** (new application version)

The application is exposed through a Kubernetes Service.

Initially, the Service sends all traffic to the Green deployment.

After deployment, monitoring shows that most user requests are failing in production, even though the application worked correctly during testing.

The objective is to restore service for users while allowing developers to continue investigating the Green deployment.

The correct answer is:

**D. Change the selector on the Service to:**

```yaml
selector:
  app: my-app
  version: blue
```

---

# Blue/Green Deployment

Blue/Green deployment keeps two versions of the application running simultaneously.

```text
                Users
                  │
                  ▼
            Kubernetes Service
                  │
        ┌─────────┴─────────┐
        │                   │
        ▼                   ▼
   Blue Deployment     Green Deployment
   Stable Version       New Version
```

Only one deployment receives production traffic.

Changing the Service selector immediately redirects all traffic without restarting the application.

---

# Why Answer D Is Correct

The Service decides which Pods receive traffic.

Initially:

```yaml
selector:
  app: my-app
  version: green
```

If Green is causing production failures, the fastest recovery is to change the selector to Blue.

```yaml
selector:
  app: my-app
  version: blue
```

No new deployment is required.

No Pods are recreated.

Traffic changes immediately.

Developers can continue debugging Green while customers use the stable Blue version.

This minimizes the impact of the incident.

---

# Why the Other Answers Are Incorrect

## A. Update Blue to the New Version

This copies the broken version into Blue.

Instead of fixing the incident, it increases the impact.

---

## B. Roll Back Green

Rolling back Green requires deploying another version.

Although it may eventually solve the problem, it is slower than simply redirecting traffic.

The Service selector can switch traffic almost instantly.

---

## C. Remove the Version Selector

Changing the selector to:

```yaml
app: my-app
```

would send traffic to both Blue and Green Pods.

Since Green is failing, many user requests would still reach the broken version.

The incident would continue.

---

# Lab Architecture

The lab recreates the production environment using GKE.

```text
                        Internet
                            │
                            ▼
                    Kubernetes Service
                    app-svc (Green)
                            │
                    app=my-app
                  version=green
                            │
                            ▼
                  +------------------+
                  |   app-green      |
                  | ImagePullBackOff |
                  +------------------+

                  +------------------+
                  |    app-blue      |
                  |     Running      |
                  +------------------+
```

The Service initially points to Green.

The Green deployment was intentionally configured with an invalid container image.

As a result, the Pods remain in the **ImagePullBackOff** state.

Terraform reports that the deployment cannot complete because no replicas become Ready.

Although this is a simplified simulation, it clearly demonstrates a failed deployment.

---

# Simulating a Failed Deployment

The Green deployment uses an invalid image.

```text
Container Image

nginxdemos/hello-does-not-exist
```

Kubernetes continuously attempts to download the image.

Since the image does not exist, the Pod enters the following state:

```text
ImagePullBackOff
```

This represents a deployment that cannot serve production traffic.

---

# Recovering the Service

Initially, the Service routes requests to Green.

```text
Users
   │
   ▼
Service
   │
version=green
   │
   ▼
Green Pods
```

To restore the application, only the selector is changed.

```yaml
selector:
  app: my-app
  version: blue
```

After the change:

```text
Users
   │
   ▼
Service
   │
version=blue
   │
   ▼
Blue Pods
```

Traffic immediately returns to the stable deployment.

No rollout is required.

No new containers are created.

Only the Service configuration changes.

---

# Commands Used During the Lab

Inspect the deployments:

```bash
kubectl get deployments -n production
```

Inspect the Pods:

```bash
kubectl get pods -n production
```

Example output:

```text
NAME                    READY   STATUS
app-blue-xxxxx          1/1     Running
app-green-xxxxx         0/1     ImagePullBackOff
```

View the Service selector:

```bash
kubectl get svc app-svc -n production -o yaml
```

Switch production traffic back to Blue:

```bash
kubectl patch service app-svc \
-n production \
-p '{"spec":{"selector":{"app":"my-app","version":"blue"}}}'
```

Verify the Service:

```bash
kubectl get svc app-svc -n production -o yaml
```

The selector now points to the Blue deployment.

---

# Key Lesson

Blue/Green deployment separates application deployment from traffic routing.

The application itself is not modified during recovery.

Instead, Kubernetes redirects production traffic by changing the Service selector.

This approach provides one of the fastest rollback mechanisms available in Kubernetes and minimizes downtime while developers investigate the failed deployment.
