# Terraform Code Versioning Best Practice

## Overview

This exercise is based on a conceptual question from the Google Cloud Professional Cloud DevOps Engineer certification.

The goal is to understand the recommended way to manage Terraform code when multiple Infrastructure DevOps Engineers work on the same project.

## Question

Our team of Infrastructure DevOps Engineers is growing, and you are starting to use Terraform to manage infrastructure. You need a way to implement code versioning and to share code with other team members.

**Correct answer:**

**A.** Store the Terraform code in a version-control system. Establish procedures for pushing new versions and merging with the master.

## Explanation

Terraform files are source code and should be managed like any other software project.

A version-control system such as Git provides:

* Complete change history
* Branches for parallel development
* Code reviews using pull requests
* Safe merge operations
* Rollback to previous versions
* Collaboration between multiple engineers

This is the standard approach for Infrastructure as Code (IaC).

The other options are not recommended because shared folders, Cloud Storage buckets, and Google Drive do not provide proper source code management or collaboration features.

## Lab

This question is conceptual and does not require Google Cloud resources.

A practical demonstration would simply consist of:

1. Creating a Git repository.
2. Adding Terraform files.
3. Creating a feature branch.
4. Modifying the infrastructure code.
5. Committing the changes.
6. Merging the branch into the main branch.

This demonstrates how Terraform projects are managed in real DevOps environments.

## Conclusion

The purpose of this exercise is to understand that Terraform code should always be stored in a version-control system.

Using Git-based repositories is the industry standard because they provide version history, collaboration, review processes, and safe code integration for Infrastructure as Code projects.
