# Q116 - Blue/Green Rollback on Google Kubernetes Engine

## Question

You are building the CI/CD pipeline for an application deployed to Google Kubernetes Engine (GKE). The application is deployed by using a Kubernetes Deployment, Service, and Ingress. The application team asked you to deploy the application by using the blue/green deployment methodology.

You need to implement the rollback actions.

**Correct answer: C**

> Update the Kubernetes Service to point to the previous Kubernetes Deployment.

---

## Why Option C is Correct

In a blue/green deployment, two independent versions of the application exist at the same time.

* Blue = Stable production version
* Green = New version

Users never connect directly to either Deployment. Instead, all traffic goes through a Kubernetes Service.

The Service decides which Deployment receives production traffic by using label selectors.

If the new Green version starts failing after deployment, the fastest rollback is simply changing the Service selector back to the Blue Deployment.

This immediately restores the previous stable version without recreating Pods, rebuilding images, or restarting the application.

---

## Why the Other Answers Are Incorrect

### A. Run `kubectl rollout undo`

This command is designed for Rolling Update deployments where a single Deployment is updated.

Blue/Green deployments use two separate Deployments, so there is no Deployment history to roll back.

---

### B. Delete the new image and delete the Pods

Deleting Pods or images does not restore production traffic.

The Green Deployment should remain available so developers can investigate the problem while users continue using the Blue version.

---

### D. Scale the new Deployment to zero

Scaling Green to zero removes the Pods, but if the Service still points to Green, users will receive errors because no healthy endpoints exist.

Traffic must be redirected back to Blue.

---

# Lab Reuse

This question is fully covered by the **Q9 Blue/Green Deployment laboratory**.

The same infrastructure created in Q9 is used here.

That lab already includes:

* A GKE cluster
* Blue Deployment
* Green Deployment
* Kubernetes Service
* Load Balancer
* Blue/Green deployment model

The only rollback action required is changing the Service selector from Green back to Blue.

No additional infrastructure is needed.

---

## Architecture

```text
                 Internet
                     |
                     |
             LoadBalancer Service
                     |
        selector = version: blue
                     |
          +----------+----------+
          |                     |
          |                     |
   Blue Deployment      Green Deployment
    Stable Version        New Version
```

During deployment:

```text
Service
   |
   +-------> Green Deployment
```

If problems are detected:

```text
Service
   |
   +-------> Blue Deployment
```

The rollback only changes the Service selector.

The Deployments remain running.

---

## Key Takeaways

* Blue/Green deployments use two independent Deployments.
* The Kubernetes Service controls production traffic.
* Rollback is performed by changing the Service selector.
* No Pods need to be recreated.
* No images need to be rebuilt.
* Q9 already demonstrates the complete solution required for this exam question.
