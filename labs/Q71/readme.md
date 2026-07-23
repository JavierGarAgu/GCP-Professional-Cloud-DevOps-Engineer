# GCP Professional Cloud DevOps Engineer - Postmortem Best Practices

## Exam Question

**Question**

You are writing a postmortem for an incident that severely affected users. You want to prevent similar incidents in the future.

Which two sections should be included in the postmortem?

**Correct answers:**
- A. An explanation of the root cause of the incident.
- C. A list of action items to prevent a recurrence of the incident.

---

## Why A is Correct

A good postmortem explains **what really caused the incident**.

The root cause analysis helps everyone understand why the failure happened instead of only describing the symptoms. This knowledge allows the team to improve the system and avoid making the same mistake again.

---

## Why C is Correct

Every postmortortem should finish with **clear action items**.

These actions should reduce the chance of the incident happening again. Examples include:

- Improve monitoring.
- Add automated tests.
- Update deployment procedures.
- Improve documentation.
- Add alerts.

The goal is continuous improvement.

---

## Why the Other Answers Are Wrong

**B. A list of employees responsible**

Incorrect.

Modern SRE and DevOps use a **blameless postmortem**. The objective is to learn from the incident, not blame individuals.

---

**D. Your opinion about the incident**

Incorrect.

A postmortem should contain facts and evidence, not personal opinions.

---

**E. Design documents**

Incorrect.

Design documents may be useful as references, but they are not a required section of a postmortem.

---

## Exam Tip

Remember this simple idea:

A good postmortem answers two questions:

1. Why did the incident happen? (Root cause)
2. What are we going to do so it does not happen again? (Action items)

The focus is learning and improving the system, not finding someone to blame.