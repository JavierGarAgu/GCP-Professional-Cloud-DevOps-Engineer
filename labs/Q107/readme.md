# Q107 - Cloud Build Triggers and GitHub Branch Protection

## Scenario

The application source code is stored in GitHub, and the production container image is built using Cloud Build.

The requirements are:

* Production builds must only run after changes reach the **main** branch.
* The Change Control team must approve every change before it is merged into **main**.
* The build process should be as automated as possible.

The correct answers are **C** and **D**.

---

# Pull Request

A **Pull Request (PR)** is a request to merge changes from one branch into another.

For example:

```text
feature/login
      │
      ▼
Create Pull Request
      │
      ▼
main
```

A Pull Request is used to review code before it becomes part of the main branch.

By itself, a Pull Request does **not** force anyone to review or approve the changes.

---

# GitHub Branch Protection

A **Branch Protection Rule** protects a branch, such as **main**, by enforcing rules before changes can be merged.

Common rules include:

* Require a Pull Request before merging.
* Require one or more approvals.
* Require status checks to pass.
* Prevent direct pushes to the branch.

In this scenario, Branch Protection ensures that the Change Control team approves every change before it reaches the main branch.

---

# Cloud Build Trigger for Pull Requests

A Cloud Build trigger can start a build whenever a Pull Request is opened or updated.

```text
Developer
      │
      ▼
Create Pull Request
      │
      ▼
Cloud Build Trigger
      │
      ▼
Run Build
```

This type of trigger is useful for validating code before it is merged.

However, it is **not** the correct choice for this question because the requirement is to build the production image only after the code reaches the **main** branch.

---

# Cloud Build Trigger for Push to Main

A Cloud Build trigger can also start a build after a push to a specific branch.

```text
Push to main
      │
      ▼
Cloud Build Trigger
      │
      ▼
Build Production Image
```

This is the correct trigger for a production pipeline because the image is built only after the approved code has been merged into **main**.

---

# Complete Workflow

The complete workflow is:

```text
Developer
      │
      ▼
Create Pull Request
      │
      ▼
Change Control Review
      │
      ▼
Approval
      │
      ▼
Merge into main
      │
      ▼
Push to main
      │
      ▼
Cloud Build Trigger
      │
      ▼
Build Production Container Image
```

GitHub is responsible for protecting the **main** branch and enforcing approvals.

Cloud Build is responsible for automatically building the production image after a successful push to **main**.

---

# Why C and D are Correct

**C. Create a trigger on the Cloud Build job. Set the repository event setting to "Push to a branch".**

This automatically starts the production build whenever changes are pushed to the **main** branch.

**D. Configure a branch protection rule for the main branch on the repository.**

This ensures that all changes must be reviewed and approved before they can be merged into **main**, satisfying the company's change control policy.
