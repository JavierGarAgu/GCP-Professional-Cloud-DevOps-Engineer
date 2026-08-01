# Q90 - Reduce Toil and Improve SRE Efficiency

## Scenario

The service has an availability target (SLO) of **99%**.

This month, the service achieved **99.5% availability**, which is better than the target.

The company has limited engineering resources, wants to launch new features, reduce technical debt, and lower operational costs.

## Correct Answer

**B. Identify, measure, and eliminate toil by automating repetitive tasks.**

## Why B is Correct

The service is already performing better than its availability target.

According to Google Site Reliability Engineering (SRE) practices, when reliability is good enough, engineers should spend time reducing **toil**. Toil is manual, repetitive work that can be automated.

Automating repetitive tasks gives several benefits:

* Saves engineering time.
* Reduces operational costs.
* Lowers technical debt.
* Allows engineers to focus on new features.
* Makes operations more reliable.

This is exactly what Google recommends.

## Why the Other Answers Are Wrong

### A. Add N+1 redundancy

The service already exceeds its availability target.

Adding more infrastructure would increase costs without solving the real problem.

### C. Minimize the remaining error budget

The purpose of an error budget is to balance reliability and feature development.

Google does **not** recommend trying to eliminate all remaining error budget because that usually slows innovation.

### D. Allocate engineers only to feature development

Although the service meets its SLO, ignoring operational improvements creates more technical debt and more manual work over time.

Google recommends balancing feature development with operational improvements such as reducing toil.

## Key Exam Idea

If a service already meets or exceeds its SLO, Google recommends improving engineering efficiency instead of increasing reliability even more.

Reducing toil through automation is one of the main principles of Site Reliability Engineering (SRE).
