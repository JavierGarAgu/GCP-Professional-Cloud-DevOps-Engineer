# Q36 - Troubleshooting a Cloud Build Pipeline

## Question

A Cloud Build CI/CD pipeline stopped creating new Docker images after modifying the `cloudbuild.yaml` file. The goal is to solve the problem following Site Reliability Engineering (SRE) principles.

## Correct Answer

**D - Run a Git compare between the previous and current Cloud Build configuration files to find and fix the bug.**

## Explanation

The pipeline stopped working after a configuration change. Since the project uses Git, the fastest and safest way to identify the problem is to compare the current `cloudbuild.yaml` with the previous working version.

Git makes it easy to see exactly what changed, allowing the engineer to quickly locate the incorrect configuration and restore the pipeline.

This approach follows SRE principles because it uses version control to investigate configuration changes instead of disabling automation or introducing unnecessary services.

## Why the Other Options Are Incorrect

* **A:** Disabling CI/CD and building images manually removes automation and goes against SRE best practices.
* **B:** Changing from Docker Hub to Container Registry does not solve the configuration error.
* **C:** Uploading the YAML file to Cloud Storage and using Error Reporting is unnecessary because the issue is caused by a configuration change, not an application runtime error.

## Key Takeaway

When a CI/CD pipeline fails after a configuration update, always compare the previous and current versions stored in Git. Version control is the primary tool for identifying configuration mistakes quickly and safely.
