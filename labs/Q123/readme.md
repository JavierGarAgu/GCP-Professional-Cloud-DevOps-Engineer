COMMANDS
```
#save json as utf-8 NO BOM
$json = [System.Text.Encoding]::UTF8.GetString(
    [System.Convert]::FromBase64String((terraform output -raw private_key))
)

[System.IO.File]::WriteAllText(
    "security-team.json",
    $json,
    (New-Object System.Text.UTF8Encoding($false))
)

gcloud auth activate-service-account security-team@devops-cert-labs-v4.iam.gserviceaccount.com --key-file=security-team.json
gcloud logging read "logName=projects/devops-cert-labs-v4/logs/cloudaudit.googleapis.com%2Fdata_access" --limit=10
#0 resources, so the role without logging private doesnt work
```

# Q123 - Grant Read-Only Access to Data Access Audit Logs

```
+-----------------------------------------------------------+
|                  Google Cloud Logging Lab                 |
|                                                           |
|         Data Access Audit Logs - Least Privilege          |
+-----------------------------------------------------------+
```

## Goal

This lab reproduces the exam scenario where a security team needs read-only access to **Data Access audit logs** while following Google's recommended practices and the principle of least privilege.

The correct solution is:

* Create a group for the security team.
* Assign the **roles/logging.privateLogViewer** role to the group.

Although this lab uses a Service Account instead of a Google Group, it demonstrates the permission difference between Logging Viewer and Private Log Viewer.

---

```
                +----------------------+
                |   Security Team      |
                +----------+-----------+
                           |
                           |
                   Read Audit Logs
                           |
                           v
                +----------------------+
                | Cloud Logging        |
                +----------------------+
```

## Why is Logging Viewer not enough?

Google Cloud stores different types of audit logs.

```
                     Audit Logs
                          |
        +-----------------+-----------------+
        |                                   |
        |                                   |
 Admin Activity                    Data Access
        |                                   |
        |                                   |
 Always enabled                  Optional
        |                                   |
        |                                   |
 logging.viewer               logging.privateLogViewer
```

The important difference is:

| Role                           | Admin Activity | Data Access |
| ------------------------------ | -------------- | ----------- |
| roles/logging.viewer           | Yes            | No          |
| roles/logging.privateLogViewer | Yes            | Yes         |

This is why **roles/logging.viewer** is not sufficient for the security team.

---

## Lab Architecture

```
                    Terraform
                        |
                        |
                        v
        +--------------------------------+
        | Create Service Account         |
        +--------------------------------+
                        |
                        |
                        v
        +--------------------------------+
        | Grant logging.viewer role      |
        +--------------------------------+
                        |
                        |
                        v
        +--------------------------------+
        | Authenticate with gcloud       |
        +--------------------------------+
                        |
                        |
                        v
        +--------------------------------+
        | Read Cloud Audit Logs          |
        +--------------------------------+
```

---

## Terraform Resources

Terraform created:

* One Service Account called **security-team**
* One IAM binding
* One Service Account key

The Service Account initially received:

```
roles/logging.viewer
```

This role allows access to standard Cloud Logging data but does not include private audit logs.

---

## Authenticating as the Service Account

The generated key was exported and used to authenticate.

Example:

```bash
gcloud auth activate-service-account \
security-team@PROJECT_ID.iam.gserviceaccount.com \
--key-file=security-team.json
```

After authentication, all logging commands were executed using the permissions of the Service Account instead of the project owner.

---

## Reading Audit Logs

The following command successfully returned Admin Activity audit logs.

```bash
gcloud logging read \
"logName=projects/PROJECT_ID/logs/cloudaudit.googleapis.com%2Factivity" \
--limit=10
```

The output contained entries such as:

* CreateServiceAccount
* SetIamPolicy

These are **Admin Activity audit logs**.

Example:

```
Admin Activity
       |
       +--> CreateServiceAccount
       |
       +--> SetIamPolicy
       |
       +--> IAM Changes
```

This confirms that **roles/logging.viewer** can read Admin Activity logs.

---

## Testing Data Access Logs

The following command was executed.

```bash
gcloud logging read \
"logName=projects/PROJECT_ID/logs/cloudaudit.googleapis.com%2Fdata_access" \
--limit=10
```

No log entries were returned.

This does **not** mean that the permissions were correct.

The project simply did not contain any Data Access audit logs because those logs were not enabled or had not yet been generated.

```
Data Access Logs

+--------------------------+
| No log entries available |
+--------------------------+
```

Therefore, the permission difference could not be observed directly.

---

## Why the Exam Answer is Still D

Google recommends using groups instead of assigning permissions individually.

```
                +------------------+
                | Security Group   |
                +---------+--------+
                          |
          roles/logging.privateLogViewer
                          |
                          |
        +-----------------+----------------+
        |                 |                |
      User A           User B          User C
```

Advantages:

* Easier administration
* Least privilege
* Better scalability
* Recommended by Google IAM best practices

---

## What This Lab Demonstrated

This lab successfully demonstrated:

* Creating a Service Account with Terraform
* Granting IAM roles
* Authenticating using a Service Account key
* Reading Admin Activity audit logs
* Understanding the difference between Admin Activity and Data Access audit logs

Although the project did not contain Data Access logs, the IAM concepts match the certification question.

---

## Exam Summary

```
Need to read:

Admin Activity
        +
Data Access
        |
        v

roles/logging.privateLogViewer
```

```
Question

Security team needs read-only access
to Data Access audit logs.

Best Practice

Create a Google Group
        +
Assign roles/logging.privateLogViewer

Correct Answer

D

