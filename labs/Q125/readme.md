# Google Cloud Deploy - Reduce Toil in Deployment Pipelines

```
+------------------------------------------------+
|        DEVOPS PIPELINE OPTIMIZATION            |
+------------------------------------------------+

Developer
    |
    v
Build Process
    |
    v
Automated Deployment
    |
    v
Testing Environment
    |
    v
Production Environment
```

## Overview

This question focuses on DevOps and SRE concepts, especially the concept of **toil**.

Toil is repetitive manual work that consumes time but does not provide significant engineering value. DevOps teams try to reduce toil by automating repetitive processes and removing unnecessary human intervention.

Examples of toil:

- Manual deployment steps.
- Manual approvals.
- Repeated configuration tasks.
- Manual environment preparation.

The goal is to create faster, more reliable, and more automated deployment pipelines.

---

## Correct Answers

## B - Divide the automation steps into smaller tasks

Breaking automation steps into smaller tasks helps improve the deployment pipeline.

Benefits:

- Easier maintenance.
- Faster troubleshooting.
- Better pipeline organization.
- More opportunities for automation.

A large and complex process is harder to manage. Smaller independent steps make the pipeline easier to optimize.

Example:

Before:

```
Large deployment process
        |
        v
Difficult to maintain
```

After:

```
Build
 |
 v
Test
 |
 v
Security Scan
 |
 v
Deploy
```

Each step can be controlled and improved independently.

---

## E - Automate promotion approvals from the development environment to the test environment

Manual approvals create delays in deployment pipelines.

Before:

```
Development
      |
      v
Waiting for human approval
      |
      v
Testing
```

After:

```
Development
      |
      v
Automatic validation
      |
      v
Testing
```

Automating promotions reduces waiting time and removes unnecessary manual work.

---

# Why the Other Answers Are Incorrect

## A - Create a trigger to notify the required team when manual intervention is required

Notifications improve communication, but they do not remove toil.

The pipeline still depends on a person completing the next step.

Example:

```
Pipeline stops
      |
      v
Notification sent
      |
      v
Human action required
```

The manual work still exists.

---

## C - Use a script to automate the creation of the deployment pipeline

This only automates pipeline creation.

It does not reduce the execution time of deployments or remove manual actions during the deployment process.

---

## D - Add more engineers to finish the manual steps

Adding more engineers does not solve the root problem.

DevOps practices focus on automation instead of increasing manual effort.

---

# Exam Concept

When a Google Cloud DevOps Engineer question mentions:

- Reduce toil.
- Minimize deployment time.
- Reduce manual intervention.

Think about:

```
Manual repetitive work
          |
          v
      Automation
          |
          v
 Faster and reliable deployments
```

The correct answers are usually the ones that eliminate repetitive human actions.

Correct Answer:

```
B + E
```