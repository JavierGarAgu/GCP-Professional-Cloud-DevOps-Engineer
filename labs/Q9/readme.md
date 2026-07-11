# Blue/Green Deployment Lab

This lab shows a very basic example of a **Blue/Green deployment** using **Terraform** and **Google Kubernetes Engine (GKE)**.

The goal is to understand how this deployment strategy can reduce the **Mean Time To Recovery (MTTR)** when a new release has problems.

## Infrastructure

Terraform creates:

* A GKE cluster
* One node pool
* A Kubernetes namespace
* One **Blue** deployment (stable version)
* One **Green** deployment (new version)
* One LoadBalancer Service

Both application versions are running at the same time, but the Service only sends traffic to one of them.

## How it works

At the beginning, the Service selector points to the **Blue** deployment.

```text
Users
  │
  ▼
Service
  │
  ▼
Blue
```

When a new release is ready, we only change the selector:

```terraform
selector = {

  version = "green"

}
```

After running:

```bash
terraform apply
```

Traffic is now sent to the Green version.

```text
Users
  │
  ▼
Service
  │
  ▼
Green
```

## Rollback

If the new version has a bug, we don't need to recreate the infrastructure.

We simply change the selector back to:

```terraform
selector = {

  version = "blue"

}
```

Run again:

```bash
terraform apply
```

The Service starts sending traffic to the stable version again in a few seconds.

This is why **Blue/Green deployments reduce the Mean Time To Recovery (MTTR)**. Recovering from a bad deployment is much faster because both versions already exist.

## Relation with the exam question

This lab represents the correct answer:

* **B** → Use **Blue/Green Deployment** to make rollback almost immediate.
* **E** → In a real environment, a **CI server** should execute automated unit tests before deploying the Green version. This lab only focuses on the deployment strategy, but normally it would be combined with CI testing before the release.

TEST

curl.exe -s http://34.62.15.91 | findstr "homepage"
<p><span>Server&nbsp;name:</span> <span>homepage-blue-b6df94557-hb52w</span></p>

Change resource "kubernetes_service" "homepage" 

    selector = {

      version = "green"

      # cambiar a "green" para desplegar
      # volver a "blue" si hay problemas

    }

curl.exe -s http://34.62.15.91 | findstr "homepage"
Server name: homepage-green-7859759d78-bb96r

