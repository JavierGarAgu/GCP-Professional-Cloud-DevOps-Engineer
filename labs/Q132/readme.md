# SRE Theory Lab - Actionable Alerts

```text
   _____ ____  ______
  / ____|  _ \|  ____|
 | (___ | |_) | |__
  \___ \|  _ <|  __|
  ____) | |_) | |____
 |_____/|____/|______|

 Actionable Alerts
```

## Objective

Understand why Site Reliability Engineering (SRE) recommends sending alerts only when human intervention is required.

## Scenario

Production systems occasionally become unhealthy. They automatically recover by restarting within one minute, and no engineer needs to take any action.

The goal is to reduce alert fatigue and prevent staff burnout.

## Correct Answer

**A. Eliminate alerts that are not actionable**

## Explanation

An alert should only notify engineers when they must perform an action. If a system automatically recovers without affecting users or requiring manual intervention, sending an alert only creates unnecessary noise.

Repeated non-actionable alerts lead to alert fatigue, making engineers more likely to ignore important incidents. Eliminating these alerts is a core SRE practice that improves on-call quality and reduces burnout.

## Why the Other Answers Are Incorrect

- **B. Redefine the related SLO so that the error budget is not exhausted**
  - Changing the SLO does not solve the problem of unnecessary alerts.

- **C. Distribute the alerts to engineers in different time zones**
  - This only spreads the workload without reducing alert noise.

- **D. Create an incident report for each of the alerts**
  - Incident reports should be reserved for significant events, not routine automatic recoveries.

## Key SRE Principle

```text
System fails
      |
      v
Automatic recovery
      |
      +--> No human action needed
               |
               v
        Do NOT send an alert

System fails
      |
      v
Automatic recovery fails
      |
      v
Human intervention required
      |
      v
Send an alert
```

## Takeaways

- Alerts must always be actionable.
- Avoid alert fatigue by removing unnecessary notifications.
- Automatic recovery should not wake the on-call engineer.
- Focus on alerts that require human intervention.
- This is a fundamental SRE principle frequently tested in the Google Professional Cloud DevOps Engineer exam.