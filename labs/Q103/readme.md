````markdown
# Service Account Key Creation Policy Lab

This lab simulates a common Google Cloud security scenario related to **Organization Policies** and **Service Account Keys**.

## Scenario

A third-party application requires a Service Account Key to authenticate.

However, the following Organization Policy is enforced:

```text
iam.disableServiceAccountKeyCreation = TRUE
```

As a result, creating new Service Account Keys is blocked.

```
                Organization

      iam.disableServiceAccountKeyCreation
                   = TRUE
                       │
                       │ inherited
                       ▼

             +--------------------+
             |      Project       |
             +--------------------+

          Service Account Key
                Creation

                 BLOCKED
```

## Goal

Allow the third-party application to use a Service Account Key without removing the security policy for the entire organization.

## Solution

Instead of disabling the policy globally, create a **project-level exception**.

```text
Organization
      │
      │ Policy enforced
      ▼

+----------------------+
|      Project         |
+----------------------+

Override Policy

iam.disableServiceAccountKeyCreation

enforced = false
```

Only this project is allowed to create Service Account Keys.

```
                Organization

      Key Creation Disabled
               │
               │
      +--------+--------+
      |                 |
      ▼                 ▼

 Project A         Project B
 (Override)        (Default)

  ALLOWED          BLOCKED
```

After applying the override, Terraform can create the Service Account Key.

## Terraform Resources

This lab creates:

- A Service Account
- A project-level Organization Policy override
- A Service Account Key

## Why Answer D?

Answer D is correct because it follows Google's security best practices.

- The organization policy remains enabled.
- Only the required project receives an exception.
- Other projects continue to block Service Account Key creation.

## Why the Other Answers Are Incorrect?

**A**

Enabling or downloading the default key is not possible while the policy is enforced.

**B**

Removing the policy at the organization level weakens security for every project.

**C**

Disabling the policy at the folder level affects multiple projects instead of only the required one.

## Exam Tip

Always follow the principle of least privilege.

```
Organization
      │
      ▼

 Keep security enabled

      │
      ▼

Create the smallest possible exception

      │
      ▼

Project

      │
      ▼

Create the Service Account Key
```

For Organization Policy questions, prefer the most restrictive solution that solves the problem without affecting other projects.
````
