COMMANDS

```
gcloud compute instances list

gcloud monitoring uptime list-configs

gcloud alpha monitoring policies list

gcloud logging read "resource.type=gce_instance" --limit=3

curl http://34.78.111.222

gcloud projects get-iam-policy devops-cert-labs
```

# Q45 - SRE Incident Management Roles

## Scenario

Your company follows Site Reliability Engineering (SRE) practices. You are the Incident Commander for a new customer-impacting incident. You need to immediately assign two incident management roles to support the incident response.

**Question**

> Your company follows Site Reliability Engineering practices. You are the Incident Commander for a new, customer-impacting incident. You need to immediately assign two incident management roles to assist you in an effective incident response. What roles should you assign? (Choose two.)

## Correct Answer

**C. Communications Lead**

**D. Customer Impact Assessor**

## Explanation

According to Google Site Reliability Engineering practices, the Incident Commander is responsible for coordinating the technical response but should delegate other responsibilities.

The **Communications Lead** keeps internal teams and stakeholders informed during the incident. This allows engineers to focus on resolving the problem instead of answering questions or providing updates.

The **Customer Impact Assessor** continuously evaluates how many customers are affected, which services are impacted, and how severe the business impact is. This information helps the Incident Commander prioritize recovery actions.

The other options are not the best immediate assignments for this situation.

- **Operations Lead** is not one of the standard SRE incident management roles.
- **Engineering Lead** usually focuses on technical work but is not one of the two roles that should immediately support the Incident Commander.
- **External Customer Communications Lead** may be required during major incidents, but the standard recommendation is to assign a Communications Lead responsible for all communications.

---

# Laboratory Objective

This Terraform project creates a small production-like environment that can be used to simulate an incident.

The infrastructure includes:

- A Compute Engine virtual machine
- An Nginx web server
- Cloud Logging
- Cloud Monitoring
- An Uptime Check
- A CPU Alert Policy
- Firewall rules for HTTP access

Although Google Cloud does not provide resources called *Communications Lead* or *Customer Impact Assessor*, the infrastructure allows you to simulate the monitoring and response phase of an SRE incident.

---

# Architecture

```
                    Internet
                        |
                        |
                  HTTP Port 80
                        |
                Firewall Rule
                        |
                        |
          Compute Engine VM (Debian)
                  Nginx Web Server
                        |
        -------------------------------
        |                             |
 Cloud Logging                 Cloud Monitoring
                                      |
                              Uptime Check
                                      |
                               CPU Alert Policy
```

---

# Terraform Resources

## Provider

The Google provider is configured to deploy every resource into the **europe-west1** region using the **devops-cert-labs** project.

---

## API Enablement

Terraform enables the required Google Cloud APIs:

- Compute Engine API
- Cloud Logging API
- Cloud Monitoring API

These services are required before creating infrastructure.

---

## Default Service Account

The virtual machine uses the default Compute Engine service account with Cloud Platform access.

This allows the instance to automatically write logs and metrics to Google Cloud.

---

## Compute Engine Instance

Terraform creates a Debian virtual machine.

During startup it automatically:

- Updates the operating system
- Installs Nginx
- Installs the stress utility
- Creates a simple web page
- Starts the Nginx service

The VM represents a production service that customers can access.

---

## Firewall Rule

A firewall rule allows inbound HTTP traffic on port 80.

This makes the web application accessible from the Internet.

---

## Uptime Check

Cloud Monitoring continuously checks whether the web server is available.

If the service becomes unavailable, the uptime check detects the failure.

---

## Alert Policy

A monitoring alert is created for high CPU utilization.

If CPU usage remains above 80% for one minute, Cloud Monitoring generates an alert.

This simulates the beginning of an incident.

---

## Outputs

Terraform prints useful information after deployment, including:

- VM name
- External IP address
- Application URL
- Correct exam answer
- Explanation of each SRE role

---

# Deployment

Initialize Terraform.

```bash
terraform init
```

Create the infrastructure.

```bash
terraform apply
```

Destroy the laboratory.

```bash
terraform destroy
```

---

# Verification

List the Compute Engine instances.

```bash
gcloud compute instances list
```

Verify the uptime check.

```bash
gcloud monitoring uptime list-configs
```

Verify the alert policy.

```bash
gcloud alpha monitoring policies list
```

Check recent VM logs.

```bash
gcloud logging read "resource.type=gce_instance" --limit=3
```

Test the web server.

```bash
curl http://EXTERNAL_IP
```

Display the IAM policy.

```bash
gcloud projects get-iam-policy devops-cert-labs
```

---

# Simulating an Incident

You can simulate an incident in several ways.

For example:

- Stop the Nginx service.
- Generate high CPU usage with the **stress** utility.
- Block HTTP traffic.
- Shut down the virtual machine.

Cloud Monitoring detects these failures and can generate alerts.

---

# Important Note

This laboratory simulates the technical environment of an SRE incident.

The roles **Incident Commander**, **Communications Lead**, and **Customer Impact Assessor** are organizational responsibilities defined by Google's Site Reliability Engineering practices.

They are **not Google Cloud resources**, IAM roles, or Terraform objects.

The purpose of this lab is to demonstrate how monitoring, logging, and alerting support the Incident Commander during an incident while the Communications Lead and Customer Impact Assessor perform their organizational responsibilities.