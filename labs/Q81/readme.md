# SRE Postmortem and Future Prevention

## Exam Question

A software change caused a serious incident that affected users. You are writing the postmortem and want to prevent similar incidents in the future.

**Correct Answer:** **B** - Ensure that test cases that catch errors of this type are run successfully before new software releases.

## Why B is Correct

The goal of an SRE postmortem is to prevent the same incident from happening again.

If the incident was caused by a software change, the best solution is to create automated test cases for that type of error.

Before every new release, these tests must run successfully.

If the same problem appears again, the tests will detect it before the software reaches production.

This improves the deployment process and reduces the risk of future incidents.

## Why the Other Answers Are Wrong

**A.** Incorrect.

SRE uses blameless postmortems. The goal is to improve the system, not to find people to blame.

**C.** Incorrect.

Telling engineers to be more careful is not a reliable solution. People can always make mistakes.

**D.** Incorrect.

Calling engineers and managers helps manage an incident, but it does not prevent the same incident from happening again.

## Key SRE Concept

After an incident, SRE focuses on improving the system.

The best solution is to automate prevention by adding tests and improving the deployment process, instead of blaming people or depending on manual actions.
