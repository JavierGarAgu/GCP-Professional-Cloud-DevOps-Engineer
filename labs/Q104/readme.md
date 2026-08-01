# Google SRE - Postmortem Triggers

## Correct Answers

- **B. Data is lost due to an incident.**
- **C. An internal stakeholder requests a postmortem.**

## Explanation

This question is about **Google Site Reliability Engineering (SRE)** practices.

The keyword is **triggers**.

In this context, **triggers are the conditions that decide when a postmortem document must be written**. They are **not** actions used to fix the incident or recover the service.

According to the Google SRE book, examples of postmortem triggers include:

- Data loss caused by an incident.
- A request from an internal stakeholder.
- Other serious incidents defined by the organization's policy.

## Why the Other Answers Are Incorrect

### A. An external stakeholder asks for a postmortem.

Incorrect.

In real companies, a customer may ask for a Root Cause Analysis (RCA) or an explanation after an incident. However, according to Google SRE practices, the decision to write a postmortem is an **internal process**. An external request is not a standard trigger defined in the postmortem policy.

### D. The monitoring system detects that one of the instances for your application has failed.

Incorrect.

A single instance failure is usually expected in a distributed system. Monitoring detects the failure, but it does not automatically mean that a postmortem is required.

### E. The CD pipeline detects an issue and rolls back a problematic release.

Incorrect.

An automatic rollback is part of the deployment process. If the rollback prevents customer impact, there is usually no need for a postmortem.

## Exam Tip

When you see the word **trigger** in this question, think:

> "What event activates the requirement to write a postmortem document?"

Do **not** think about actions that detect, fix, or recover from an incident.

**Correct answers: B and C.**