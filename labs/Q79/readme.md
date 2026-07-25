# SRE Error Budget

## Exam Question

A user-facing application has used less than 5% of its error budget during the last six months. The business confirms that the current SLO is appropriate. What should you do?

**Correct Answers:** **B** and **E**

## Why B is Correct

The application has a lot of unused error budget.

This means the service is more reliable than required.

You can release new versions more often or accept a little more risk because you still have enough error budget.

The goal is to increase development velocity while staying inside the SLO.

## Why E is Correct

The application has unused error budget.

If maintenance is needed, you can plan downtime and inform users before it happens.

This uses part of the available error budget in a controlled way.

Users know about the maintenance, and the business still accepts the current SLO.

## Why the Other Answers Are Wrong

**A.** Incorrect.

Adding more capacity makes the service even more reliable, but reliability is already much higher than required.

**C.** Incorrect.

The question says that the business has confirmed the current SLO is appropriate.

There is no reason to make the SLO stricter.

**D.** Incorrect.

Adding more SLIs can provide more information, but it does not solve the problem of having too much unused error budget.

## Key SRE Concept

If you have a lot of unused error budget:

* You can release changes more frequently.
* You can use planned maintenance when necessary.
* You do not need to increase reliability because the current SLO already meets the business needs.
