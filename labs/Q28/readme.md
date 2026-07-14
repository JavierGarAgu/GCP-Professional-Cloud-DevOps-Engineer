REPO USED: https://github.com/JavierGarAgu/Q28-TEST

TESTING

```
git checkout main
git pull origin main

git config user.name "RenaultMegane"
git config user.email "renaultmegane@q28.com"

git checkout -b feature/paco-firewall

git config user.name "Paco"
git config user.email "paco@q28.com"

Add-Content README.md "`n## Paco implemented firewall rules"
git add README.md
git commit -m "Paco - Add firewall configuration"

git checkout main

git config user.name "RenaultMegane"
git config user.email "renaultmegane@q28.com"

git merge --no-ff feature/paco-firewall -m "Merge feature/paco-firewall"
git push origin main

git checkout -b feature/juan-monitoring

git config user.name "Juan"
git config user.email "juan@q28.com"

Add-Content README.md "`n## Juan added monitoring"
git add README.md
git commit -m "Juan - Add monitoring"

git checkout main

git config user.name "RenaultMegane"
git config user.email "renaultmegane@q28.com"

git merge --no-ff feature/juan-monitoring -m "Merge feature/juan-monitoring"
git push origin main

git checkout -b feature/lapampara-logging

git config user.name "LaPampara"
git config user.email "lapampara@q28.com"

Add-Content README.md "`n## LaPampara configured logging"
git add README.md
git commit -m "LaPampara - Add logging"

git checkout main

git config user.name "RenaultMegane"
git config user.email "renaultmegane@q28.com"

git merge --no-ff feature/lapampara-logging -m "Merge feature/lapampara-logging"
git push origin main

git branch -d feature/paco-firewall
git branch -d feature/juan-monitoring
git branch -d feature/lapampara-logging

git config user.name "RenaultMegane"
git config user.email "renaultmegane@q28.com"

git log --graph --decorate --oneline --all

git status
```

TESTING 2
```
git init -b main

git config user.name "RenaultMegane"
git config user.email "renaultmegane@q28.com"

@'
terraform {

  required_providers {

    google = {
      source  = "hashicorp/google"
      version = "~> 5.0"
    }

  }

}

provider "google" {

  project = "devops-cert-labs"
  region  = "europe-west1"

}
'@ | Set-Content main.tf

'variable "project_id" {}' | Set-Content variables.tf

'output "project" { value = var.project_id }' | Set-Content outputs.tf

'terraform { required_version = ">= 1.5.0" }' | Set-Content versions.tf

'project_id = "devops-cert-labs"' | Set-Content terraform.tfvars

"# Terraform Collaboration Lab" | Set-Content README.md

terraform fmt

git add .
git commit -m "Initial Terraform infrastructure"

git checkout -b feature/paco-firewall

git config user.name "Paco"
git config user.email "paco@q28.com"

Add-Content README.md "`n## Paco implemented firewall rules"

git add .
git commit -m "Paco - Add firewall configuration"

git checkout main

git config user.name "RenaultMegane"
git config user.email "renaultmegane@q28.com"

git merge feature/paco-firewall --no-ff -m "Merge feature/paco-firewall"

git checkout -b feature/juan-monitoring

git config user.name "Juan"
git config user.email "juan@q28.com"

Add-Content README.md "`n## Juan added monitoring"

git add .
git commit -m "Juan - Add monitoring"

git checkout main

git config user.name "RenaultMegane"
git config user.email "renaultmegane@q28.com"

git merge feature/juan-monitoring --no-ff -m "Merge feature/juan-monitoring"

git checkout -b feature/lapampara-logging

git config user.name "LaPampara"
git config user.email "lapampara@q28.com"

Add-Content README.md "`n## LaPampara configured logging"

git add .
git commit -m "LaPampara - Add logging"

git checkout main

git config user.name "RenaultMegane"
git config user.email "renaultmegane@q28.com"

git merge feature/lapampara-logging --no-ff -m "Merge feature/lapampara-logging"

git branch -d feature/paco-firewall
git branch -d feature/juan-monitoring
git branch -d feature/lapampara-logging

git branch

git log --graph --oneline --decorate --all

git status
```

# Google Cloud Professional Cloud DevOps Engineer Lab

# Question - Collaborating on Terraform Infrastructure with Version Control

---

## Introduction

This repository contains a hands-on lab created while preparing for the **Google Cloud Professional Cloud DevOps Engineer** certification.

The purpose of this lab is to understand how multiple engineers should collaborate when developing Infrastructure as Code (IaC) with Terraform.

The objective is to prevent developers from overwriting each other's work while ensuring that the latest validated version of the infrastructure is always available.

---

# Exam Question

> You are responsible for creating and modifying the Terraform templates that define your Infrastructure. Because two new engineers will also be working on the same code, you need to define a process and adopt a tool that will prevent you from overwriting each other's code. You also want to ensure that you capture all updates in the latest version. What should you do?

### A

- Store your code in a Git-based version control system.
- Allow developers to merge their own changes at the end of each day.
- Upload the latest version to a versioned Cloud Storage bucket.

### B

- Store your code in a Git-based version control system.
- Establish a process that includes peer code reviews and testing before integration.
- The fully integrated repository becomes the latest master version.

### C

- Store Terraform files in Google Drive.
- Organize them using folders.
- Rename folders every day to create versions.

### D

- Store Terraform files in Google Drive.
- Compress them into ZIP files.
- Upload ZIP archives to Cloud Storage.

---

# Correct Answer

✅ **Answer B**

---

# Why Answer B is Correct

Terraform templates are source code.

Like any other software project, Infrastructure as Code should follow modern software engineering practices.

Google recommends using a **Git-based version control system** together with a collaborative development workflow.

Each engineer develops changes in an independent branch, where modifications can be reviewed and validated before being merged into the main branch.

This process prevents developers from overwriting each other's work while ensuring that only tested infrastructure definitions become part of the production codebase.

A typical workflow is:

```text
Developer
      │
      ▼
 Feature Branch
      │
      ▼
Terraform Validate
      │
      ▼
Peer Code Review
      │
      ▼
Merge into Main
      │
      ▼
Main becomes the latest version
```

This workflow guarantees:

- Version history.
- Safe collaboration.
- Code review.
- Infrastructure validation.
- A single source of truth.

---

# Why the Other Answers are Incorrect

## Answer A

Git is the correct tool, but allowing developers to merge directly without code reviews or validation is not considered a good DevOps practice.

Uploading copies to Cloud Storage does not replace version control.

Cloud Storage cannot manage branches, commits, merge history, or collaborative development.

---

## Answer C

Google Drive is not a version control system.

Although file versioning exists, it does not provide:

- Branches
- Merge requests
- Code reviews
- Commit history
- Conflict resolution

It is not suitable for Infrastructure as Code.

---

## Answer D

Creating ZIP archives is only manual file versioning.

It does not support collaborative development and does not provide the features required for modern DevOps workflows.

---

# Lab Overview

This lab simulates multiple engineers working on the same Terraform repository.

Each developer works independently using a dedicated feature branch.

The changes are validated before being merged into the main branch.

Finally, the main branch becomes the latest production-ready version.

---

# Simulated Workflow

```text
                 Git Repository

                      main
                       │
        ┌──────────────┼──────────────┐
        │              │              │
        ▼              ▼              ▼
 feature/paco   feature/juan   feature/lapampara
        │              │              │
        ▼              ▼              ▼
     Commit         Commit         Commit
        │              │              │
        └───────┬──────┴──────┬───────┘
                │             │
                ▼             ▼
          Code Review & Validation
                │
                ▼
          Merge into main
                │
                ▼
      Latest Stable Terraform Code
```

---

# Repository Structure

Example structure used during the lab:

```text
terraform-project/
│
├── main.tf
├── variables.tf
├── outputs.tf
├── versions.tf
├── terraform.tfvars
├── README.md
└── .gitignore
```

---

# Validation Steps

The following commands are commonly executed before integrating Terraform code:

Format the files:

```bash
terraform fmt
```

Validate the configuration:

```bash
terraform validate
```

Review infrastructure changes:

```bash
terraform plan
```

Only after these checks should the code be merged into the main branch.

---

# Best Practices

Google recommends following these DevOps principles:

- Store Infrastructure as Code in Git.
- Create a branch for every new feature.
- Review code before merging.
- Validate Terraform configurations.
- Keep the main branch stable.
- Use the repository as the single source of truth.

---

# Architecture

```text
                +----------------------+
                |     Developer        |
                +----------+-----------+
                           |
                           ▼
                  Feature Branch
                           |
                           ▼
               Terraform Validation
                           |
                           ▼
                 Peer Code Review
                           |
                           ▼
                  Merge into Main
                           |
                           ▼
             Stable Infrastructure Code
```

---

# Conclusion

This lab demonstrates how Infrastructure as Code should be managed in a collaborative environment.

Git provides version control, branching, merge history, and conflict resolution, while peer reviews and validation ensure that infrastructure changes are safe before becoming part of the production codebase.

This workflow prevents engineers from overwriting each other's work and guarantees that the latest integrated version is always available.

For these reasons, **Answer B** is the correct solution.

