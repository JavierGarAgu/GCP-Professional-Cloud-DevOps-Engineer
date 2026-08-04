# Q131 - SRE Postmortem Best Practices

```text
   ____  ___ ____  _____
  / __ \/ _ / __ \/ ___/
 / /_/ / __ / /_/ (__  )
 \____/_/ |_\____/____/

 Google Cloud Professional Cloud DevOps Engineer
```

## Objective

Understand the key principles of a good SRE postmortem according to Google's Site Reliability Engineering (SRE) practices.

## Question

Your CTO has asked you to implement a postmortem policy on every incident for internal use. You want to define what a good postmortem is to ensure that the policy is successful at your company.

**Choose two.**

- A. Ensure that all postmortems include what caused the incident, identify the person or team responsible for causing the incident, and how to prevent a future occurrence of the incident.
- B. Ensure that all postmortems include what caused the incident, how the incident could have been worse, and how to prevent a future occurrence of the incident.
- C. Ensure that all postmortems include the severity of the incident, how to prevent a future occurrence of the incident, and what caused the incident without naming internal system components.
- D. Ensure that all postmortems include how the incident was resolved and what caused the incident without naming customer information.
- E. Ensure that all incident participants in postmortem authoring and share postmortems as widely as possible.

## Correct Answers

- **C**
- **E**

## Explanation

Google promotes **blameless postmortems**, where the objective is to improve systems and processes rather than assigning blame.

A good postmortem should include:

- Incident severity and impact.
- Root cause analysis.
- Preventive actions to avoid future incidents.
- Collaboration from everyone involved.
- Broad internal sharing so other teams can learn from the incident.

### Why not the other answers?

### A

Incorrect because it focuses on identifying the person or team responsible. Google SRE postmortems are **blameless**.

### B

Although evaluating how an incident could have been worse may be useful in some organizations, it is **not a required element** of Google's postmortem process.

### D

Describing the resolution and protecting customer information are important, but this option does not require documenting preventive actions, which is one of the primary goals of a postmortem.

## Key Exam Notes

- Use **blameless postmortems**.
- Focus on improving systems instead of blaming people.
- Record severity, root cause, and corrective actions.
- Share lessons learned across the organization.
- Encourage participation from everyone involved in the incident.

## Exam Tip

Whenever a Google Cloud exam question mentions **postmortems**, immediately think of these principles:

- Blameless culture.
- Root cause analysis.
- Preventive actions.
- Shared learning across teams.