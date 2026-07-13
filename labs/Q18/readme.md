COMMANDS

```
terraform init

terraform plan

terraform apply -auto-approve

gcloud compute instances list
NAME                                                 ZONE            MACHINE_TYPE  PREEMPTIBLE  INTERNAL_IP    EXTERNAL_IP    STATUS
development-environment                              europe-west1-b  e2-medium                  10.132.0.10    34.38.139.225  RUNNING
testing-environment                                  europe-west1-b  e2-medium                  10.132.0.14    34.62.0.171    RUNNING
```

Your company experiences bugs, outages, and slowness in its production systems. Developers use the production environment for new feature development and bug fixes. Configuration and experiments are done in the production environment, causing outages for users. Testers use the production environment for load testing, which often slows the production systems. You need to redesign the environment to reduce the number of bugs and outages in production and to enable testers to toad test new features. What should you do?

D
Create a development environment for writing code and a test environment for configurations, experiments, and load testing.

# Google Cloud Professional Cloud DevOps Engineer Lab

# Question - Separate Development and Testing Environments

---

## Introduction

This repository contains a small hands-on lab created while preparing for the **Google Cloud Professional Cloud DevOps Engineer** certification.

The goal of this lab is to understand why production environments should never be used for development, testing, or experimentation. Instead, dedicated environments must be created so each team can work independently without affecting production services.

This scenario focuses on one of the most important DevOps principles: **environment separation**.

---

## Scenario

A company is experiencing frequent production incidents.

Developers are writing new features and fixing bugs directly in the production environment. At the same time, testers execute load tests against production systems.

As a result:

- Production becomes unstable.
- Users experience outages.
- Performance decreases during load tests.
- Configuration changes introduce unexpected bugs.

The company wants to redesign its infrastructure following DevOps best practices.

The correct answer is:

> **Create a development environment for writing code and a test environment for configurations, experiments, and load testing.**

---

# Architecture

The Terraform configuration creates two independent Google Compute Engine virtual machines.

```
                 Google Cloud

        +-------------------------+
        | Development Environment |
        |-------------------------|
        | Developers write code   |
        | Bug fixes               |
        | New features            |
        +-------------------------+

                    |

          Changes validated first

                    |

        +-------------------------+
        |    Testing Environment  |
        |-------------------------|
        | Load testing            |
        | Experiments             |
        | Configuration testing   |
        +-------------------------+

                    |

          Only validated changes

                    |

             Production Environment
```

Production is intentionally **not modified** during this lab because its purpose is to demonstrate that development and testing activities should happen outside production.

---

# Terraform Resources

The lab deploys two Compute Engine instances.

## Development Environment

Purpose:

- Feature development
- Bug fixing
- Code validation

Configuration:

- Debian 12
- e2-medium
- 20 GB boot disk
- Public IP
- Labels identifying the VM as a development environment

Terraform resource:

```terraform
google_compute_instance.development
```

---

## Testing Environment

Purpose:

- Load testing
- Configuration validation
- Experiments before production deployment

Configuration:

- Debian 12
- e2-medium
- 20 GB boot disk
- Public IP
- Labels identifying the VM as a testing environment

Terraform resource:

```terraform
google_compute_instance.testing
```

---

# Deploy the Infrastructure

Initialize Terraform.

```bash
terraform init
```

Review the execution plan.

```bash
terraform plan
```

Deploy both virtual machines.

```bash
terraform apply -auto-approve
```

---

# Verify the Deployment

After deployment, verify that both instances were created successfully.

```bash
gcloud compute instances list
```

Example output:

```text
NAME                         ZONE            MACHINE_TYPE   STATUS
development-environment      europe-west1-b  e2-medium      RUNNING
testing-environment          europe-west1-b  e2-medium      RUNNING
```

Both environments should appear in the **RUNNING** state.

---

# Why Is This the Correct Answer?

The main problem is that multiple teams are sharing the production environment.

Developers introduce unfinished code directly into production, while testers perform load tests against live systems. This creates instability, affects real users, and increases the number of incidents.

Creating separate development and testing environments solves these problems because each team can work independently without impacting production.

This approach provides several benefits:

- Production remains stable.
- Developers can safely implement new features.
- Testers can execute load tests without affecting users.
- Configuration changes can be validated before deployment.
- Bugs are detected earlier in the software lifecycle.

This follows one of the core DevOps practices: **production should only run tested and validated software**.

---

# Learning Objectives

After completing this lab, you should understand how to:

- Create isolated environments using Terraform.
- Deploy multiple Compute Engine instances.
- Separate development and testing workloads.
- Reduce production risks by isolating experiments.
- Apply DevOps environment separation best practices.

---

# Technologies Used

- Google Cloud Platform (GCP)
- Google Compute Engine
- Terraform
- Debian 12
- Google Cloud CLI

---

# Conclusion

This lab demonstrates a simple but important DevOps principle: **never use the production environment for development or testing activities**.

By creating dedicated development and testing environments, teams can work more safely, reduce outages, improve software quality, and protect production systems from unnecessary risks. This separation is considered a fundamental best practice for reliable cloud infrastructure and is commonly evaluated in the **Google Cloud Professional Cloud DevOps Engineer** certification.
