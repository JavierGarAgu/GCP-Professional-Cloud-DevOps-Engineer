COMMANDS

```
gcloud config set project devops-cert-labs-v2

gcloud container clusters get-credentials logging-sidecar-lab --zone europe-west1-b

kubectl get nodes

kubectl get pods -n production

kubectl describe deployment third-party-app -n production

kubectl get pod -n production -o jsonpath="{.items[0].spec.containers[*].name}"

kubectl exec -n production deployment/third-party-app -- ls -l /var/log

kubectl exec -n production deployment/third-party-app -- cat /var/log/app_messages.log

kubectl exec -n production deployment/third-party-app -- tail -n 10 /var/log/app_messages.log
```

The command kubectl get pod -n production -o jsonpath="{.items[0].spec.containers[*].name}" only shows third-party-app. If the logging agent were installed, it would also appear in the output.

# Q54 - Troubleshooting Missing Stackdriver Logs

## Overview

This lab simulates a troubleshooting scenario where an application is running correctly and generating log files, but no logs appear in the Stackdriver (Cloud Logging) dashboard.

The objective is to reproduce the situation described in the exam question and understand why the correct answer is:

**A. Confirm that the Stackdriver agent has been installed in the hosting virtual machine.**

---

## Exam Question

You are using Stackdriver to monitor applications hosted on Google Cloud Platform (GCP). You recently deployed a new application, but its logs are not appearing on the Stackdriver dashboard.

You need to troubleshoot the issue. What should you do?

**A.** Confirm that the Stackdriver agent has been installed in the hosting virtual machine.

**B.** Confirm that your account has the proper permissions to use the Stackdriver dashboard.

**C.** Confirm that port 25 has been opened in the firewall to allow messages through to Stackdriver.

**D.** Confirm that the application is using the required client library and the service account key has proper permissions.

**Correct answer:** **A**

---

# Lab Architecture

The infrastructure is deployed with Terraform and contains:

* A GKE cluster.
* One node pool.
* A Kubernetes namespace called **production**.
* A BusyBox application that continuously writes log messages into a file.
* A shared volume mounted at **/var/log**.

Unlike a normal logging deployment, **no logging sidecar or Stackdriver logging agent is deployed**.

As a result, the application creates log files successfully, but no component collects or forwards those logs to Cloud Logging.

---

# Terraform Resources

The **main.tf** creates the following resources:

* Google Kubernetes Engine cluster.
* Kubernetes node pool.
* Kubernetes provider configuration.
* Production namespace.
* BusyBox deployment.
* Shared EmptyDir volume for log storage.

The application executes the following loop:

```sh
touch /var/log/app_messages.log

while true; do
  echo "Application log $(date)" >> /var/log/app_messages.log
  sleep 5
done
```

A new log entry is written every five seconds.

The deployment intentionally does **not** include any logging agent.

---

# Why the Logs Do Not Appear

The application works correctly.

The log file exists.

The log file is continuously updated.

However, nothing reads that file and sends its contents to Stackdriver.

Because the logging agent is missing, Cloud Logging never receives the application logs.

This reproduces the exact troubleshooting scenario described in the certification exam.

---

# Deploy the Lab

Initialize Terraform.

```powershell
terraform init
```

Deploy the infrastructure.

```powershell
terraform apply -auto-approve
```

---

# Configure kubectl

Set the active project.

```powershell
gcloud config set project devops-cert-labs-v2
```

Download the Kubernetes credentials.

```powershell
gcloud container clusters get-credentials logging-sidecar-lab --zone europe-west1-b
```

---

# Verify the Deployment

Check that the cluster is running.

```powershell
kubectl get nodes
```

List the pods.

```powershell
kubectl get pods -n production
```

Expected output:

```text
NAME                               READY   STATUS
third-party-app-xxxxxxxxxx-xxxxx   1/1     Running
```

---

# Verify That No Logging Agent Exists

Display the containers running inside the pod.

```powershell
kubectl get pod -n production -o jsonpath="{.items[0].spec.containers[*].name}"
```

Expected output:

```text
third-party-app
```

Only one container exists.

If the logging agent were installed, it would also appear in the output.

---

# Verify the Log File

List the files inside the log directory.

```powershell
kubectl exec -n production deployment/third-party-app -- ls -l /var/log
```

Expected output:

```text
app_messages.log
```

Read the log file.

```powershell
kubectl exec -n production deployment/third-party-app -- cat /var/log/app_messages.log
```

Example:

```text
Application log Sun Jul 19 18:00:01 UTC 2026
Application log Sun Jul 19 18:00:06 UTC 2026
Application log Sun Jul 19 18:00:11 UTC 2026
```

Display the latest log entries.

```powershell
kubectl exec -n production deployment/third-party-app -- tail -n 10 /var/log/app_messages.log
```

---

# Explanation

The application is functioning correctly.

The log file is created successfully.

New log entries are continuously generated.

However, there is no Stackdriver logging agent installed to collect those logs and send them to Cloud Logging.

Because of this, no application logs appear in the Stackdriver dashboard.

---

# Why Option A Is Correct

The first step when application logs are missing is to verify that the logging agent responsible for collecting and forwarding the logs is installed and running.

Without the agent, the application may generate logs correctly, but Cloud Logging will never receive them.

---

# Why the Other Answers Are Incorrect

**B**

Dashboard permissions only control whether a user can view logs. They do not prevent logs from being collected.

**C**

Stackdriver does not use SMTP or port 25 to receive log data.

**D**

The application is already generating logs locally. The problem is that nothing is collecting and forwarding those logs to Stackdriver.

---

# Conclusion

This lab demonstrates a common troubleshooting scenario where an application produces logs successfully, but Cloud Logging remains empty because the logging agent is missing.

The correct solution is to verify that the Stackdriver logging agent has been installed and is running.

**Correct Answer: A**
