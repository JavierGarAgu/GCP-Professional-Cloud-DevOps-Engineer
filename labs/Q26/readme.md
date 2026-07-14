# Google Cloud Professional Cloud DevOps Engineer Lab

# Question - Production Readiness Review (PRR) and Service Level Objectives (SLOs)

---

## Introduction

This repository contains a hands-on lab created while preparing for the **Google Cloud Professional Cloud DevOps Engineer** certification.

The purpose of this lab is to simulate a **Production Readiness Review (PRR)** following **Site Reliability Engineering (SRE)** principles.

The deployed application is intentionally unreliable and cannot meet its Service Level Objectives (SLOs). During the PRR, the SRE team evaluates the service before it is handed over by the Development Team.

The goal is to understand the correct decision when a service does not satisfy its reliability requirements.

---

# Exam Question

> You are part of an organization that follows SRE practices and principles. You are taking over the management of a new service from the Development Team, and you conduct a Production Readiness Review (PRR). After the PRR analysis phase, you determine that the service cannot currently meet its Service Level Objectives (SLOs). You want to ensure that the service can meet its SLOs in production. What should you do next?

### A

Adjust the SLO targets to be achievable by the service so you can bring it into production.

### B

Notify the development team that they will have to provide production support for the service.

### C

Identify recommended reliability improvements to the service to be completed before handover.

### D

Bring the service into production with no SLOs and build them when you have collected operational data.

---

# Correct Answer

✅ **Answer C — Identify recommended reliability improvements to the service to be completed before handover.**

---

# Why Answer C is Correct

A Production Readiness Review (PRR) is performed before a service is accepted into production by the SRE team.

The objective of the PRR is to verify that the application is reliable enough to meet its defined Service Level Objectives (SLOs).

If the service cannot currently achieve its SLOs, the correct action is **not** to accept the service into production.

Instead, the SRE team should:

- Identify the reliability problems.
- Document the required improvements.
- Return the findings to the Development Team.
- Repeat the PRR after the improvements have been completed.

Only after the service satisfies the required reliability standards should it be handed over to the SRE team.

This follows Google's Site Reliability Engineering practices.

---

# Why the Other Answers are Incorrect

## Answer A

Lowering the SLO only to make the service appear successful defeats the purpose of SLOs.

SLOs should represent the business reliability requirements, not the current limitations of the application.

The service should improve to meet the SLO, not the opposite.

---

## Answer B

The Development Team may still need to implement improvements, but simply asking them to continue supporting the service does not solve the reliability problems.

The objective of the PRR is to identify what must be fixed before production handover.

---

## Answer D

Bringing an unreliable service into production without defined SLOs is against SRE principles.

SLOs should already exist before production so the service reliability can be measured correctly.

---

# Terraform Resources

This lab deploys:

- Compute Engine VM
- Python Flask application
- HTTP firewall rule
- Production Readiness Review report

The application intentionally behaves unreliably.

Approximately 80% of the requests return:

```text
503 Service Unavailable
```

This simulates a service that cannot satisfy its expected availability target.

Terraform also generates a local PRR report containing the recommended improvements before production handover.

---

# Deployment

Initialize Terraform.

```bash
terraform init
```

Create the execution plan.

```bash
terraform plan
```

Deploy the infrastructure.

```bash
terraform apply
```

---

# Validation

## 1. Verify the Virtual Machine

```bash
gcloud compute instances list
```

Expected instance:

```text
production-readiness-review
```

---

## 2. Open the Service

Terraform outputs the service URL.

Example:

```text
http://<EXTERNAL-IP>:8080
```

Refresh the page several times.

Most requests will return:

```text
503 Service Unavailable
```

Some requests will return:

```text
OK
```

This demonstrates that the service is unreliable.

---

## 3. Test the Availability

Run several HTTP requests.

Example:

```bash
for i in {1..20}
do
curl http://<EXTERNAL-IP>:8080
echo
done
```

The success rate is much lower than a typical production SLO such as **99.9% availability**.

---

## 4. Review the PRR Report

Terraform creates the following file:

```text
production-readiness-review.txt
```

The report includes:

- Current service status
- Expected SLO
- Observed reliability
- Recommended improvements
- Final PRR decision

The report concludes that the service should **not** be handed over until the reliability issues are resolved.

---

# Production Readiness Review Process

```text
Development Team
        │
        ▼
Production Readiness Review
        │
        ▼
Can the service meet its SLO?
        │
        ├────────────── Yes ──────────────► Production Handover
        │
        ▼
        No
        │
        ▼
Identify Reliability Improvements
        │
        ▼
Development Team fixes the service
        │
        ▼
Repeat the PRR
```

---

# Architecture

```text
                +----------------------+
                | Development Team     |
                +----------+-----------+
                           |
                           ▼
            Deploy Unreliable Application
                           |
                           ▼
                +----------------------+
                | Compute Engine VM    |
                | Flask Application    |
                +----------+-----------+
                           |
                           ▼
          Production Readiness Review (PRR)
                           |
                           ▼
          Service Fails to Meet the SLO
                           |
                           ▼
      Recommend Reliability Improvements
                           |
                           ▼
          Development Team Fixes Service
                           |
                           ▼
                 Repeat the PRR Process
```

---

# Conclusion

This lab demonstrates the purpose of a **Production Readiness Review** in a Site Reliability Engineering environment.

The deployed application intentionally fails to meet its expected Service Level Objectives.

Instead of lowering the SLO or moving the application directly into production, the correct approach is to identify the required reliability improvements and complete them before the production handover.

This follows Google's SRE best practices and makes **Answer C** the correct solution.