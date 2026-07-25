# SRE Postmortem - Blameless Culture

## Exam Question

A new release caused a service outage because it exhausted the available memory. The release was rolled back successfully, and now you must write the postmortem following Site Reliability Engineering (SRE) practices.

**Correct Answer:** **B** - Focus on identifying the contributing causes of the incident rather than the individual responsible for the cause.

## Why B is Correct

SRE promotes **blameless postmortems**. The goal is to understand **why** the incident happened, not **who** caused it.

In this case, the release used too much memory. The postmortem should identify the technical and process failures, such as:

* No memory usage testing before deployment.
* Missing monitoring or alerts.
* Deployment process did not detect the problem.
* Rollback was the correct mitigation.

The objective is to improve the system and prevent the same outage from happening again.

## Why the Other Answers Are Wrong

**A.** Incorrect.

Ignoring the incident and only developing new features increases the risk of future outages.

**C.** Incorrect.

SRE does not focus on finding the person responsible. Private meetings to assign blame are against the blameless culture.

**D.** Incorrect.

Punishing the engineer who made the commit does not solve the real problem. The system and deployment process should be improved instead.

## Key SRE Concept

A good SRE postmortem is **blameless**. It focuses on learning from the incident, finding the root causes, and creating action items that reduce the chance of the problem happening again.
