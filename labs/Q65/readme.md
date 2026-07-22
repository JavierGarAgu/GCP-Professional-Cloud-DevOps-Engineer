# Managing Reliability with SLOs and Error Budget Policies

# Error Budget Inverse SLO

## Overview

This scenario explains one of the most important concepts in **Site Reliability Engineering (SRE)**: balancing service reliability and feature development using **Service Level Objectives (SLOs)** and an **Error Budget Policy**.

Instead of making decisions during an incident, Google recommends defining clear rules before problems occur. This allows both development and operations teams to know exactly how to react when service reliability decreases.

---

# Exam Question

You support a large service with a well-defined Service Level Objective (SLO).

The development team deploys new releases multiple times every week.

If a major incident causes the service to miss its SLO, you want the development team to stop focusing on new features and instead improve service reliability.

What should you do **before** a major incident occurs?

### Options

**A**

Develop an appropriate **Error Budget Policy** in cooperation with all service stakeholders.

**B**

Negotiate with the product team to always prioritize service reliability over releasing new features.

**C**

Reduce the release frequency to no more than one deployment per week.

**D**

Add a Jenkins plugin that automatically blocks deployments whenever the service is outside its SLO.

**Correct Answer: A**

---

# What Is an SLO?

A **Service Level Objective (SLO)** is a measurable target that defines the level of service users should receive.

Examples include:

- 99.9% availability
- 95% of requests completed in less than 300 ms
- Less than 0.1% failed requests

An SLO represents the expected quality of the service from the user's perspective.

It is one of the core concepts of Site Reliability Engineering.

---

# What Is an Error Budget?

An **Error Budget** is the amount of unreliability that is acceptable while still meeting the SLO.

For example:

- SLO = 99.9% availability
- Allowed downtime = approximately 43 minutes per month

Those 43 minutes are the service's error budget.

As long as the service stays within this budget, the development team can continue releasing new features.

If the budget is exhausted, reliability becomes the highest priority until the service returns to a healthy state.

---

# What Is an Error Budget Policy?

An **Error Budget Policy** is a documented agreement that explains what happens when the error budget is consumed.

The policy is created before incidents occur and is agreed upon by all stakeholders, including:

- Development teams
- Operations teams
- Product managers
- Business stakeholders

A typical policy may define:

- When feature releases should stop
- When engineers should focus on fixing reliability issues
- Who approves emergency releases
- When normal development can continue

The policy removes uncertainty because everyone already knows the rules.

---

# Why Option A Is Correct

The question asks what should be done **before a major incident occurs**.

The correct action is to prepare an Error Budget Policy together with all stakeholders.

When an incident happens, nobody needs to negotiate what to do because the process has already been defined.

This is exactly how Google recommends balancing innovation and reliability.

---

# Why Option B Is Wrong

Option B says that service reliability should **always** be more important than releasing new features.

This is not Google's SRE philosophy.

Google does not recommend always choosing reliability over innovation.

Instead, reliability and development should remain balanced.

As long as the service is meeting its SLO and has remaining error budget, the team should continue delivering new features.

Only after the error budget has been exhausted should reliability become the main priority.

This balance is the purpose of the Error Budget.

---

# Why Option C Is Wrong

Reducing deployments to once per week does not solve the problem.

Google generally encourages:

- Small releases
- Frequent deployments
- Continuous delivery

Changing the release schedule is not part of Error Budget management.

---

# Why Option D Is Wrong

Automatically blocking deployments with Jenkins may be one way to enforce a policy, but it is not the policy itself.

The exam asks what should be done before incidents occur.

The correct answer is to define the Error Budget Policy first.

Automation can be added later if the organization decides to enforce the policy automatically.

---

# Google's SRE Philosophy

Google's Site Reliability Engineering model is based on balancing two goals:

- Deliver new features quickly.
- Maintain a reliable service.

Without an Error Budget, development teams may always push for more features while operations teams always push for more stability.

The Error Budget creates an objective rule that both teams agree on before incidents happen.

If the service is healthy:

- Continue releasing features.

If the service exceeds the allowed error budget:

- Pause feature development.
- Focus on improving reliability.
- Resume normal releases after the service returns within its SLO.

This approach removes conflicts between teams and provides a predictable decision-making process.

---

# Exam Tip

Whenever an exam question mentions:

- SLO
- Reliability
- Feature releases
- Error Budget

Think about Google's standard workflow:

1. Define the Service Level Objective (SLO).
2. Calculate the Error Budget.
3. Create an Error Budget Policy with all stakeholders.
4. Follow that policy whenever the error budget is exhausted.

Questions containing these concepts almost always expect the Error Budget Policy as the correct answer.

---

# Key Takeaways

- An SLO defines the expected level of service.
- The Error Budget is the amount of failure that is acceptable while still meeting the SLO.
- The Error Budget Policy explains what actions should be taken when the budget is consumed.
- The policy should be agreed upon before incidents occur.
- Google recommends balancing reliability and feature development instead of always prioritizing one over the other.

---

# Final Answer

**Correct Answer: A**

Develop an appropriate **Error Budget Policy** in cooperation with all service stakeholders before any major incident occurs. This ensures that everyone understands when to stop feature development and focus on improving service reliability after the service exceeds its allowed error budget.