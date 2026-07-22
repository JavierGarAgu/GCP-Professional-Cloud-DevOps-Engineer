# Defining Service Level Objectives (SLOs) for Web Application Latency

## Overview

This scenario focuses on choosing the most appropriate **Service Level Objective (SLO)** for the latency of a high-traffic, multi-region web application.

The application is already running successfully, and customers are satisfied with its current performance. The challenge is to publish an SLO that represents a realistic and sustainable objective instead of simply copying the current measurements.

---

## Exam Question

A company operates a high-traffic multi-region web application.

Customers expect:

- High availability
- Fast response times

Current monitoring over the last 28 days shows:

- 90th percentile latency: **120 ms**
- 95th percentile latency: **275 ms**

Customers are currently happy with the application's performance.

Which latency SLO should be published?

### Options

**A**

- P90 = 100 ms
- P95 = 250 ms

**B**

- P90 = 120 ms
- P95 = 275 ms

**C**

- P90 = 150 ms
- P95 = 300 ms

**D**

- P90 = 250 ms
- P95 = 400 ms

Correct answer according to Google:

**C**

---

# Understanding SLOs

A **Service Level Objective (SLO)** is a target that defines the expected level of service delivered to users.

It should:

- Represent a good user experience.
- Be achievable over time.
- Leave enough room for normal performance fluctuations.
- Be useful for measuring service reliability.

An SLO is not simply a copy of today's monitoring values.

---

# Why Option B Looks Correct

Many engineers would initially choose **Option B**.

The reasoning is simple:

- Customers are already satisfied.
- Current latency is:
  - P90 = 120 ms
  - P95 = 275 ms

Therefore, using exactly those numbers seems reasonable because they already represent a user experience that customers accept.

From a practical engineering perspective, this argument is completely valid.

---

# Why Google Chooses Option C

Google's SRE philosophy recommends that SLOs should be **ambitious but achievable**.

If today's measurements are exactly:

- P90 = 120 ms
- P95 = 275 ms

and the published SLO is identical, even a very small increase could immediately violate the objective.

For example:

Current measurement:

- P90 = 120 ms

Published SLO:

- P90 ≤ 120 ms

Tomorrow's measurement:

- P90 = 121 ms

The SLO is already broken, even though users probably do not notice any difference.

Because of this, Google recommends publishing an objective with a small operational margin.

Option C does exactly that.

It still guarantees excellent performance while allowing for normal day-to-day variation.

---

# Why Option A Is Wrong

Option A makes the latency target stricter than the current system performance.

There is no evidence that the application can consistently achieve:

- P90 = 100 ms
- P95 = 250 ms

Publishing unrealistic objectives creates unnecessary SLO violations.

---

# Why Option D Is Wrong

Option D is too relaxed.

If the application currently delivers:

- P90 = 120 ms

and the SLO allows:

- P90 = 250 ms

performance could degrade significantly before anyone notices.

An SLO should protect the user experience, not hide performance problems.

---

# Exam Mentality

For the Professional Cloud DevOps Engineer exam, remember this rule:

- Do not choose an SLO that is stricter than current performance.
- Do not choose an SLO that is much more relaxed than current performance.
- Do not simply copy the current measurements.
- Choose an SLO that is slightly more relaxed while still representing a good user experience.

This is why Google expects **Option C** instead of **Option B**.

---

# Key Takeaways

- SLOs define the expected level of service for users.
- They should reflect customer expectations.
- They must be achievable over long periods.
- Small operational margins help avoid unnecessary violations caused by normal system variability.
- Google's exams usually prefer realistic and sustainable objectives instead of exact copies of current measurements.

---

# Final Answer

**Correct answer: C**

- 90th percentile latency ≤ **150 ms**
- 95th percentile latency ≤ **300 ms**

Although many engineers could reasonably defend **Option B** in a real production environment, Google's SRE philosophy prefers an SLO that includes a small performance margin while maintaining a high-quality user experience.