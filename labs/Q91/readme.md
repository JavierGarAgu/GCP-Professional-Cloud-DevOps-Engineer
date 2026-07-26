Q9 LAB IS ESSENCIALY THE SAME
# Q91 - Deployment Strategy and Testing Strategy

## Scenario

You need a deployment strategy that:

* Reduces deployment complexity.
* Makes rollbacks very fast.
* Tests real production traffic.
* Gradually increases the number of affected users.

## Correct Answer

**B. Blue/green deployment and canary testing**

## Why B is Correct

This option combines two best practices.

### Blue/Green Deployment

Blue/green deployment keeps two identical environments:

* **Blue** = current production.
* **Green** = new version.

When the new version is ready, traffic is switched from Blue to Green.

If a problem appears, rollback is very simple because traffic is switched back to Blue almost immediately.

Benefits:

* Very fast rollback.
* Minimal downtime.
* Lower deployment risk.

### Canary Testing

Canary testing sends the new version to a small percentage of real users first.

For example:

* 5% of users
* 20%
* 50%
* 100%

If monitoring shows everything is healthy, traffic is increased gradually.

Benefits:

* Uses real production traffic.
* Detects problems before affecting all users.
* Reduces deployment risk.

Together, Blue/Green deployment and Canary testing satisfy every requirement in the question.

## Why the Other Answers Are Wrong

### A. Recreate deployment and canary testing

Recreate deployment stops the old version before starting the new one.

This causes downtime and makes rollback slower.

### C. Rolling update deployment and A/B testing

Rolling updates replace instances gradually, but rollback is slower than Blue/Green because the old version is replaced step by step.

A/B testing is designed to compare different application versions or features, not mainly to validate deployment safety.

### D. Rolling update deployment and shadow testing

Shadow testing copies production traffic to the new version without affecting users.

It is useful for validation, but it does **not** gradually expose real users to the new version as required.

## Key Exam Idea

Remember these common deployment strategies:

| Strategy       | Best Use                                     |
| -------------- | -------------------------------------------- |
| Blue/Green     | Fast deployment and instant rollback         |
| Canary         | Gradually release to real users              |
| Rolling Update | Replace instances with little or no downtime |
| Recreate       | Simple deployment but causes downtime        |
| Shadow         | Test with mirrored production traffic        |
| A/B Testing    | Compare different versions or features       |

For Google Cloud DevOps exam questions:

* **Need fast rollback → Blue/Green**
* **Need gradual release to real users → Canary**
* **Need both → Blue/Green + Canary**
