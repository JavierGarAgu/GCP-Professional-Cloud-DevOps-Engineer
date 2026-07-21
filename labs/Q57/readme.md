# Incident Mitigation After a Bad Release

## Overview

This document explains an SRE incident management scenario from the Google Cloud Professional Cloud DevOps Engineer exam.

The scenario focuses on how to react when a new software release causes performance problems in a production environment.

The main concept tested is the difference between **mitigation** and **investigation** during an incident.

---

# Scenario

You support a web application hosted on Compute Engine.

The application provides a booking service used by thousands of users.

Shortly after releasing a new feature, the monitoring dashboard shows that all users are experiencing latency during the login process.

The objective is to reduce the impact of the incident on users.

The question asks:

**What should you do first?**

Possible answers:

- A. Roll back the recent release.
- B. Review the Stackdriver monitoring.
- C. Upsize the virtual machines running the login services.
- D. Deploy a new release to see whether it fixes the problem.

---

# Correct Answer

## A. Roll back the recent release

The correct action is to rollback the recent deployment.

The problem appeared immediately after a new feature was released, and all users are affected.

This creates a strong indication that the new release introduced a problem.

The priority during a production incident is not to immediately find the root cause.

The first objective is to restore service availability and reduce the impact on customers.

A rollback returns the application to the previous stable version, allowing users to continue using the service while engineers investigate the issue.

---

# Explanation of Incorrect Answers

## B. Review the Stackdriver monitoring

This option is not the best first action.

The monitoring system already detected the problem:

- Login latency increased.
- All users are affected.
- The issue started after a new deployment.

Additional monitoring analysis can help identify the root cause, but it does not immediately reduce the impact.

Monitoring review belongs to the investigation phase after mitigation.

---

## C. Upsize the virtual machines running the login services

Increasing the VM size is not the correct first step.

There is no evidence that the problem is caused by insufficient infrastructure capacity.

The root cause could be:

- Bad application logic.
- Inefficient database queries.
- A broken dependency.
- A configuration problem introduced by the release.

Increasing resources could increase costs without fixing the actual problem.

---

## D. Deploy a new release to see whether it fixes the problem

This is a risky action during an active incident.

Deploying additional changes without understanding the issue can make the outage worse.

During incidents, changes should be limited and focused on restoring stability.

---

# SRE Incident Management Approach

The exam follows the SRE incident response methodology:

```
Detect → Mitigate → Investigate → Fix → Prevent
```

---

# 1. Detect

The monitoring system detects abnormal behavior.

Examples:

- Increased latency.
- High error rate.
- Failed requests.
- Resource problems.

In this scenario:

```
Monitoring dashboard detects login latency
```

---

# 2. Mitigate

The main priority is reducing the impact on users.

Possible mitigation actions:

- Rollback a problematic release.
- Disable a faulty feature.
- Redirect traffic.
- Scale infrastructure if capacity is confirmed as the problem.

For this scenario:

```
New release causes latency
            |
            v
Rollback deployment
            |
            v
Application returns to previous stable version
```

---

# 3. Investigate

After the system is stable, engineers investigate the root cause.

Possible actions:

- Review Cloud Logging.
- Analyze monitoring metrics.
- Check application traces.
- Compare deployment changes.
- Review recent commits.

The objective is understanding why the incident happened.

---

# 4. Fix

After identifying the cause, engineers implement a permanent solution.

Examples:

- Improve application performance.
- Optimize database queries.
- Fix incorrect configurations.
- Add additional testing.

---

# 5. Prevent

The final step is preventing similar incidents.

Examples:

- Implement canary deployments.
- Improve automated testing.
- Add better alerting.
- Define stronger SLOs.
- Automate rollback procedures.

---

# Exam Mentality

Google Cloud DevOps Engineer questions usually test operational thinking rather than technical implementation.

When a production incident affects users:

1. Restore service first.
2. Reduce customer impact.
3. Investigate after stabilization.
4. Implement a permanent fix.
5. Improve the system to prevent repetition.

The wrong approach is spending too much time investigating while users are still affected.

The correct approach is:

```
Incident detected
        |
        v
Reduce impact
        |
        v
Restore service
        |
        v
Find root cause
        |
        v
Prevent future incidents
```

---

# Key Takeaway

The main lesson from this question is:

**During an incident, mitigation has priority over investigation.**

A rollback is the fastest and safest action because it restores the last known good state and minimizes the impact on users.