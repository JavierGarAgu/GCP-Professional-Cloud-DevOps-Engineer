# Q114 - Terraform create_before_destroy with Managed Instance Groups

## Scenario

An application is deployed on Compute Engine by using a Managed Instance Group (MIG).

Terraform manages the infrastructure, and every infrastructure change is executed automatically through a CI/CD pipeline.

The Managed Instance Group uses an Instance Template to define the virtual machine configuration.

One day, the machine type must be updated from `e2-micro` to `e2-small`.

The Terraform pipeline fails during the `terraform apply` stage.

The objective is to update the infrastructure while minimizing service disruption and avoiding multiple pipeline executions.

The correct answer is:

**D. Set the create_before_destroy meta-argument to true in the lifecycle block on the instance template.**

---

# Why the Pipeline Fails

Instance Templates are immutable resources.

When an immutable property such as the machine type changes, Terraform cannot modify the existing template.

Instead, Terraform must replace it.

Without any lifecycle configuration, Terraform follows its default behavior:

1. Destroy the old resource.
2. Create the new resource.

However, the old Instance Template is still being used by the Managed Instance Group.

Google Cloud prevents the template from being deleted while it is still referenced.

As a result, the deployment fails.

---

# Infrastructure

```text
                    Terraform
                        │
                        │
                        ▼
              Instance Template
                        │
                        ▼
         Managed Instance Group
                        │
                        ▼
               Compute Engine VM
```

---

# Default Terraform Behavior

Without `create_before_destroy`, Terraform executes the following order:

```text
Old Instance Template
        │
        ▼
Destroy Template
        │
        ▼
Create New Template
```

The problem is that the Managed Instance Group is still using the old template.

```text
               MIG
                │
                ▼
      Instance Template v1

Terraform

Delete Template v1
        │
        ▼
Google Cloud

Error

Template is currently in use.
```

The pipeline stops before creating the new template.

---

# Using create_before_destroy

The lifecycle meta-argument changes the execution order.

```hcl
lifecycle {

  create_before_destroy = true

}
```

Terraform now performs these operations:

```text
Create Template v2
        │
        ▼
Update Managed Instance Group
        │
        ▼
Delete Template v1
```

Both templates exist temporarily.

```text
Step 1

MIG
 │
 ├── Template v1
 └── Template v2


Step 2

MIG
 │
 └── Template v2


Step 3

Template v1 removed
```

Because the Managed Instance Group always references a valid template, the deployment completes successfully.

---

# Laboratory

The lab creates:

* Compute Engine API
* Firewall rule
* Instance Template
* Regional Managed Instance Group
* One virtual machine

Initially, the Instance Template uses:

```text
machine_type = "e2-micro"
```

After the first deployment, the machine type is changed to:

```text
machine_type = "e2-small"
```

This forces Terraform to replace the Instance Template.

The lab then demonstrates how enabling `create_before_destroy` allows Terraform to complete the replacement without deleting the active template first.

---

# Deployment Flow

```text
terraform apply
        │
        ▼
Template v1 created
        │
        ▼
Managed Instance Group created
        │
        ▼
Application running
        │
        ▼
Machine type modified
        │
        ▼
Terraform creates Template v2
        │
        ▼
Managed Instance Group updated
        │
        ▼
Template v1 removed
```

---

# Benefits of create_before_destroy

Using `create_before_destroy` provides several advantages:

* Reduces deployment downtime.
* Prevents dependency errors.
* Allows a single successful Terraform apply.
* Works well in CI/CD pipelines.
* Avoids deleting resources that are still in use.
* Improves deployment reliability.

---

# Why the Other Answers Are Incorrect

## A. Delete the Managed Instance Group

Deleting the Managed Instance Group causes unnecessary downtime.

The application becomes unavailable until the infrastructure is recreated.

---

## B. Create a New Instance Template Manually

Creating a new template manually works, but it requires multiple deployment steps.

The question asks for the solution that minimizes both disruption and pipeline executions.

---

## C. Remove the Resource from the Terraform State

Changing the Terraform state does not solve the infrastructure dependency.

It only changes Terraform's internal tracking and increases operational complexity.

---

# Key Lesson

Some Google Cloud resources are immutable.

When an immutable resource must be replaced and another resource depends on it, the replacement order becomes critical.

The `create_before_destroy` lifecycle rule tells Terraform to create the new resource first, update all dependencies, and only then delete the old resource.

This approach minimizes downtime, prevents dependency errors, and allows infrastructure changes to complete successfully in a single CI/CD pipeline execution.
