# Terraform Remote State with Cloud Storage

## Question

You are using Terraform to manage infrastructure as code within a CI/CD pipeline. You notice that multiple copies of the entire infrastructure stack exist in your Google Cloud project, and a new copy is created each time a change to the existing infrastructure is made.

You need to optimize your cloud spend by ensuring that only a single instance of your infrastructure stack exists at a time.

**Correct answer:** **B** - Confirm that the pipeline is storing and retrieving the `terraform.tfstate` file from Cloud Storage with the Terraform `gcs` backend.

---

## Why?

Terraform keeps information about the infrastructure in a **state file** (`terraform.tfstate`).

If every pipeline execution starts without the previous state, Terraform believes that no resources exist and creates a new infrastructure stack.

Using a **Cloud Storage (GCS) backend** allows every pipeline run to use the same shared state file.

This lets Terraform compare the current infrastructure with the desired configuration and update existing resources instead of creating new ones.

---

## Architecture

```text
                Git Repository
                      |
                      |
               CI/CD Pipeline
                      |
          terraform init/apply
                      |
        +-------------+-------------+
        |                           |
        |                    GCS Backend
        |                 terraform.tfstate
        |                           |
        +-------------+-------------+
                      |
               Google Cloud
        Existing Infrastructure
```

---

## Workflow

```text
Pipeline starts
       |
       v
Read terraform.tfstate
from Cloud Storage
       |
       v
Compare desired state
with current state
       |
       v
Create / Update / Delete
only required resources
       |
       v
Save updated state
to Cloud Storage
```

---

## Why the other answers are wrong

| Option | Explanation |
|---------|-------------|
| A | Deleting old infrastructure is unnecessary if Terraform manages the same state correctly. |
| B | Correct. A shared GCS backend keeps one state file for all pipeline executions. |
| C | Storing the state file in source control is not recommended because the state changes frequently and may contain sensitive information. |
| D | Destroying and recreating the infrastructure on every deployment increases downtime and costs. |

---

## Key Points

- Terraform uses `terraform.tfstate` to track resources.
- Store the state remotely with the **GCS backend**.
- Every pipeline execution must use the same state file.
- Terraform updates existing resources instead of creating duplicates.
- This is the recommended Google Cloud practice.