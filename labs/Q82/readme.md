# Replacing the Change Advisory Board (CAB)

## Exam Question

Your company uses a Change Advisory Board (CAB) to approve every change before deployment. You want to remove the negative impact of this process on software delivery performance.

**Correct Answers:** **C** and **E**

## Why C is Correct

Instead of using a CAB, use a peer-review process.

Developers review each other's Pull Requests before the code is merged.

Automated tests also run during the check-in process.

This provides quality control without slowing down software delivery.

## Why E is Correct

Developers should receive fast feedback after making changes.

Automated tests, code analysis, and CI/CD pipelines quickly detect problems.

Finding issues early makes them easier and cheaper to fix.

## Why the Other Answers Are Wrong

**A.** Incorrect.

Replacing the CAB with a manager still creates a manual approval process and slows down deployments.

**B.** Incorrect.

Automatic rollback is useful, but it does not replace code reviews and automated testing.

**D.** Incorrect.

Large and infrequent releases increase risk. DevOps and SRE recommend small and frequent deployments.

## Key Exam Concept

When an exam question mentions a **CAB**, think about replacing manual approvals with automation.

Typical SRE and DevOps solutions are:

* Pull Request peer reviews.
* Automated tests.
* CI/CD pipelines.
* Fast feedback for developers.

The goal is to improve software delivery speed while keeping high quality and reliability.
