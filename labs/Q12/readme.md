# Google Cloud Professional Cloud DevOps Engineer Lab

# Question - Incident Summary and Blameless Post-Mortems

---

## Introduction

This repository contains a small hands-on lab created while preparing for the **Google Cloud Professional Cloud DevOps Engineer** certification.

The purpose of this lab is to understand what should happen **after an incident has been resolved**.

Unlike many labs that focus on infrastructure or deployments, this exercise focuses on one of the core principles of **Google Site Reliability Engineering (SRE)**: learning from incidents through **blameless post-mortems**.

To simulate an outage, this repository references **Question 3**, where a simple Node.js application can be placed into an incident state and later recovered.

---

# Exam Question

> You encountered a major service outage that affected all users of the service for multiple hours. After several hours of incident management, the service returned to normal, and user access was restored.
>
> You need to provide an incident summary to relevant stakeholders following the Site Reliability Engineering recommended practices.
>
> **What should you do first?**

### A

Call individual stakeholders to explain what happened.

### B ✅

Develop a post-mortem to be distributed to stakeholders.

### C

Send the Incident State Document to all the stakeholders.

### D

Require the engineer responsible to write an apology email to all stakeholders.

---

# Why is B correct?

The most important part of the question is:

> **The service returned to normal, and user access was restored.**

The incident is already over.

According to Google's Site Reliability Engineering practices, the next step is to create a **blameless post-mortem**.

A post-mortem is a document that explains:

* What happened
* What was the impact
* What caused the incident
* How the problem was detected
* How the service was restored
* What improvements should be implemented

The purpose is not to blame anyone.

Instead, the goal is to help the engineering organization learn from the incident and reduce the chance of similar problems in the future.

After the document is completed, it should be shared with the relevant stakeholders.

---

# Why are the other answers incorrect?

### A - Call individual stakeholders

Calling stakeholders may be useful for communication, but it does not create a permanent record of the incident.

A post-mortem documents the incident in a structured way so everyone can learn from it.

---

### C - Send the Incident State Document

The Incident State Document is mainly used **while the incident is still active**.

It keeps stakeholders informed about the current situation.

Once the service has been restored, the next recommended step is creating the post-mortem.

---

### D - Require the engineer responsible to apologize

This goes against Google's SRE culture.

Google recommends **blameless post-mortems**.

The objective is improving systems and processes, not blaming individuals.

Most incidents are caused by multiple contributing factors rather than a single person's mistake.

---

# Lab Workflow

```
Application Running

        │

        ▼

Incident Starts

        │

        ▼

Service Unavailable

        │

        ▼

Incident Response

        │

        ▼

Service Restored

        │

        ▼

Blameless Post-Mortem

        │

        ▼

Action Items

        │

        ▼

System Improvements
```

---

# Simulating an Incident

This repository focuses on the post-mortem process.

To simulate an application failure, you can use the infrastructure created in **Question 3**.

That lab allows you to:

* Start an incident
* Generate HTTP 500 responses
* Restore the application
* Simulate a real production outage

Once the service has been restored, you can use the timeline to write a post-mortem following Google's recommendations.

---

# What should a post-mortem include?

A good post-mortem normally contains:

* Summary
* Customer Impact
* Timeline
* Root Cause
* Trigger
* Detection
* Resolution
* Action Items
* Lessons Learned

The document should describe facts and improvements instead of assigning blame.

---

# Example

Using the incident simulated in Question 3:

**Summary**

The application returned HTTP 500 errors for all users.

**Impact**

Users could not access the service during the incident.

**Trigger**

The incident started after the application entered an unhealthy state.

**Detection**

The increase in HTTP 500 responses was detected by monitoring.

**Resolution**

The application was restored and started responding normally again.

**Action Items**

* Add better monitoring
* Configure automatic alerts
* Improve health checks
* Document the recovery procedure

---

# Google Cloud Services Used

This repository focuses on SRE practices rather than Google Cloud services.

The incident simulation can be performed using:

* Compute Engine
* Terraform
* Node.js

---

# Concepts Practiced

* Site Reliability Engineering (SRE)
* Incident Management
* Blameless Post-Mortems
* Root Cause Analysis
* Continuous Improvement
* Operational Excellence

---

# What I Learned

After completing this lab I better understand why the correct answer is **B**.

Fixing the incident is not the end of the process.

Google recommends documenting every major incident with a **blameless post-mortem**.

The document helps engineers understand what happened, improve the system, and prevent similar incidents in the future.

---

# Conclusion

This lab demonstrates an important Site Reliability Engineering practice that is frequently tested in the Google Cloud Professional Cloud DevOps Engineer certification.

The key is understanding the timeline.

The incident has already been resolved.

The question is asking what should happen **next**.

According to Google's SRE recommendations, the first step is to create a **blameless post-mortem** and share it with the relevant stakeholders.

This promotes learning, improves reliability, and helps prevent future incidents.
