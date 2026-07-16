# QXX - SRE Postmortem and Incident Prevention

## Question

Your company follows Site Reliability Engineering (SRE) principles. You are writing a postmortem for an incident, triggered by a software change, that severely affected users. You want to prevent severe incidents from happening in the future.

**Correct answer: B**

> Ensure that test cases that catch errors of this type are run successfully before new software releases.

---

## Explanation

According to Google SRE principles, postmortems should be **blameless**. The goal is not to find who made the mistake, but to understand why the incident happened and improve the system.

Because the incident was caused by a software change, the best long-term solution is to add automated tests that detect the same problem before a new release reaches production.

Running these tests in the CI/CD pipeline reduces the risk of repeating the incident and improves software reliability.

---

## Why the Other Answers Are Incorrect

**A. Identify engineers responsible for the incident**

This goes against the idea of blameless postmortems. SRE focuses on improving systems, not blaming people.

**C. Follow up with employees who reviewed the changes**

Reviewing the process can help, but it does not guarantee that the same issue will be detected in future releases.

**D. Require on-call teams to immediately call engineers and management**

This improves incident response, but it does not prevent similar incidents from happening again.

---

## Laboratory

No laboratory is required for this question.

This is a theoretical SRE question about postmortems and continuous improvement. There is no Google Cloud service or Terraform infrastructure needed to demonstrate the concept.

---

## Key Takeaways

- SRE promotes blameless postmortems.
- Focus on improving the system instead of blaming people.
- Add automated tests to prevent the same failure from reaching production.
- CI/CD pipelines should validate software before every release.