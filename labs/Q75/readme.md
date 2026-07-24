# GCP Professional Cloud DevOps Engineer - Postmortem Action Items

## Overview

This lab explains how to assign action items after a production incident. Once the outage is resolved, the team should focus on fixing the root causes to reduce the chance of the same problem happening again.

A good postmortem is **blameless**, meaning the goal is to learn from the incident instead of blaming individuals.

## Best Practice

Each action item should have:

- One clear owner.
- Any required collaborators.
- A target completion date.
- Progress tracking until the task is completed.

Having a single owner makes accountability clear and helps ensure that every improvement is implemented.

## Why Option A Is Correct

**Option A:** *Assign one owner for each action item and any necessary collaborators.*

This is the recommended SRE practice.

The owner is responsible for tracking the action item until it is completed, while collaborators can help with implementation. This creates clear accountability without blaming anyone for the incident.

## Why Option C Is Incorrect

**Option C:** *Assign collaborators but no individual owners to the items to keep the postmortem blameless.*

This option misunderstands the meaning of a blameless postmortem.

A blameless culture does **not** mean that nobody is responsible for the follow-up work. It only means that the incident review focuses on improving systems instead of blaming people.

Without a dedicated owner, action items can easily be forgotten or delayed because no one is accountable for completing them.

## Key Exam Point

Remember the difference:

- **Blameless** = Do not blame people for the incident.
- **Ownership** = Assign one person responsible for completing each action item.

A blameless postmortem still requires clear ownership to ensure that improvements are implemented.