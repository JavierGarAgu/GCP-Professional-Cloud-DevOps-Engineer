COMMANDS

```
$MIG_NAME="production-mig"
$REGION="europe-west1"

gcloud compute instance-groups managed list-instances $MIG_NAME --region=$REGION

$INSTANCE_NAME=$(gcloud compute instances list --format="value(name)" | Select-Object -First 1)

$ZONE=$(gcloud compute instances list --filter="name=$INSTANCE_NAME" --format="value(zone.basename())")

$INSTANCE_EXTERNAL_IP=$(gcloud compute instances describe $INSTANCE_NAME --zone=$ZONE --format="value(networkInterfaces[0].accessConfigs[0].natIP)")

echo $INSTANCE_NAME
echo $ZONE
echo $INSTANCE_EXTERNAL_IP

$MIG_NAME="production-mig"
$REGION="europe-west1"
$ZONE="europe-west1-d"
$INSTANCE_NAME="production-s5z7"
$INSTANCE_EXTERNAL_IP="34.140.82.251"

gcloud compute health-checks list

gcloud compute firewall-rules list

gcloud compute regions describe $REGION

gcloud compute project-info describe

curl http://$INSTANCE_EXTERNAL_IP
```

# Q37 - Capacity Planning for a Multi-Region Managed Instance Group

## Question

You need to deploy a new service to production. The service must automatically scale by using a Managed Instance Group (MIG) and be deployed across multiple regions. Each instance requires a large amount of resources, so capacity planning is important.

**Which option is correct?**

- A. Use the n1-highcpu-96 machine type.
- B. Monitor Stackdriver Trace.
- ✅ C. Validate that the resource requirements are within the available quota limits of each region.
- D. Deploy everything in one region.

---

# Correct Answer

**Answer C**

Before deploying a large service with regional Managed Instance Groups and autoscaling, you must verify that every target region has enough Compute Engine quota.

If the region does not have enough CPUs, memory, instance limits, or IP addresses, the autoscaler will not be able to create new virtual machines when traffic increases.

This is an important part of capacity planning in Google Cloud.

---

# Laboratory Overview

This laboratory simulates a production deployment that uses a Regional Managed Instance Group with autoscaling.

The infrastructure includes:

- Google Compute Engine Instance Template
- Regional Managed Instance Group
- Regional Autoscaler
- HTTP Health Check
- Firewall Rule
- Startup Script
- Large machine type (`n2-standard-16`)

The virtual machine installs Nginx automatically during startup and serves a simple web page.

The Managed Instance Group monitors the health of the instances and can recreate them if necessary. The Autoscaler increases or decreases the number of instances according to CPU utilization.

Finally, regional quotas are checked to verify that enough resources are available before scaling.

---

# main.tf Architecture

The Terraform configuration is divided into several sections.

## Provider

The Google provider connects Terraform to the selected Google Cloud project and region.

---

## Required APIs

The required Google Cloud APIs are enabled automatically.

- Compute Engine API
- Cloud Monitoring API
- Cloud Logging API

---

## Instance Template

The Instance Template defines how every virtual machine will be created.

It includes:

- Debian 12
- Machine type `n2-standard-16`
- Default service account
- External IP
- Startup script

The startup script installs Nginx and creates a simple web page.

---

## Health Check

An HTTP Health Check monitors port 80.

If an instance becomes unhealthy, the Managed Instance Group can replace it automatically.

---

## Regional Managed Instance Group

A Regional Managed Instance Group creates identical virtual machines.

In this laboratory it starts with two instances and uses the Instance Template created previously.

Because it is regional, Google Cloud can distribute the instances across different zones inside the region, increasing availability.

---

## Autoscaler

The Regional Autoscaler monitors CPU utilization.

Configuration:

- Minimum instances: 2
- Maximum instances: 10
- CPU target: 70%

When CPU usage increases, new virtual machines are created automatically.

---

## Firewall

A firewall rule allows incoming HTTP traffic on port 80.

This makes the web application accessible from the Internet.

---

## Outputs

Terraform outputs display useful information such as:

- Managed Instance Group name
- Autoscaler name
- Machine type
- Correct exam answer
- Explanation of capacity planning

---

# Validation Commands

The infrastructure was verified using Google Cloud CLI.

Managed Instance Group:

```powershell
gcloud compute instance-groups managed describe production-mig --region=europe-west1
```

Autoscaler:

```powershell
gcloud compute instance-groups managed list-instances production-mig --region=europe-west1
```

Health Check:

```powershell
gcloud compute health-checks list
```

Firewall:

```powershell
gcloud compute firewall-rules list
```

Regional quotas:

```powershell
gcloud compute regions describe europe-west1
```

Project quotas:

```powershell
gcloud compute project-info describe
```

Application test:

```powershell
curl http://<EXTERNAL_IP>
```

The application returned **HTTP 200 OK**, confirming that the startup script completed successfully and the instance was serving web traffic.

---

# Conclusion

This laboratory demonstrates how to deploy a production service using a Regional Managed Instance Group with autoscaling.

The most important concept is capacity planning. Before deploying large instances across regions, engineers must verify that enough regional quotas are available. Otherwise, the Managed Instance Group will not be able to create additional instances during periods of high demand.

For this reason, the correct answer is **C**.