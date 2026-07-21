LOGS
```
null_resource.load_test (local-exec): Summary:
null_resource.load_test (local-exec):   Total:  -1644.6673 secs
null_resource.load_test (local-exec):   Slowest:        19.2300 secs
null_resource.load_test (local-exec):   Fastest:        0.8232 secs
null_resource.load_test (local-exec):   Average:        9.9450 secs
null_resource.load_test (local-exec):   Requests/sec:   -0.0608

null_resource.load_test (local-exec):   Total data:     992 bytes
null_resource.load_test (local-exec):   Size/request:   124 bytes

null_resource.load_test (local-exec): Response time histogram:
null_resource.load_test (local-exec):   0.823 [1]       |■■■■■■■■■■■■■■■■■■■■
null_resource.load_test (local-exec):   2.664 [1]       |■■■■■■■■■■■■■■■■■■■■
null_resource.load_test (local-exec):   4.505 [0]       |
null_resource.load_test (local-exec):   6.345 [0]       |
null_resource.load_test (local-exec):   8.186 [2]       |■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
null_resource.load_test (local-exec):   10.027 [0]      |
null_resource.load_test (local-exec):   11.867 [0]      |
null_resource.load_test (local-exec):   13.708 [2]      |■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■
null_resource.load_test (local-exec):   15.549 [0]      |
null_resource.load_test (local-exec):   17.389 [0]      |
null_resource.load_test (local-exec):   19.230 [2]      |■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■■


null_resource.load_test (local-exec): Latency distribution:
null_resource.load_test (local-exec):   10%% in 0.9512 secs
null_resource.load_test (local-exec):   25%% in 6.7080 secs
null_resource.load_test (local-exec):   50%% in 12.7169 secs
null_resource.load_test (local-exec):   75%% in 18.9560 secs
null_resource.load_test (local-exec):   0%% in 0.0000 secs
null_resource.load_test (local-exec):   0%% in 0.0000 secs
null_resource.load_test (local-exec):   0%% in 0.0000 secs

null_resource.load_test (local-exec): Details (average, fastest, slowest):
null_resource.load_test (local-exec):   DNS+dialup:     0.0465 secs, 0.0444 secs, 0.0497 secs
null_resource.load_test (local-exec):   DNS-lookup:     0.0000 secs, 0.0000 secs, 0.0000 secs
null_resource.load_test (local-exec):   req write:      0.0001 secs, 0.0000 secs, 0.0002 secs
null_resource.load_test (local-exec):   resp wait:      9.8975 secs, 0.7747 secs, 19.1800 secs
null_resource.load_test (local-exec):   resp read:      0.0001 secs, 0.0001 secs, 0.0003 secs

null_resource.load_test (local-exec): Status code distribution:
null_resource.load_test (local-exec):   [200]   8 responses
```

# Google Cloud Professional Cloud DevOps Engineer

# Question

You have migrated an e-commerce application to Google Cloud Platform (GCP). You want to prepare the application for the upcoming busy season. What should you do first to prepare for the busy season?

**A.** Load test the application to profile its performance for scaling.

**B.** Enable Auto Scaling on the production clusters, in case there is growth.

**C.** Pre-provision double the compute power used last season, expecting growth.

**D.** Create a runbook on inflating the disaster recovery (DR) environment if there is growth.

**Correct Answer:** **A**

---

# Explanation

The first step before increasing infrastructure capacity is to understand how the application behaves under heavy traffic.

A load test simulates many users accessing the application at the same time. During the test, engineers collect important performance metrics such as:

* Response time
* Requests per second
* CPU utilization
* Memory consumption
* Error rate
* Throughput

These measurements help determine how much capacity the application really needs.

Without performance data, enabling Auto Scaling or adding more virtual machines is only a guess and may lead to unnecessary costs or poor performance.

For this reason, Google recommends performing load testing before making scaling decisions.

The other answers are not the best choice.

Option B enables Auto Scaling immediately without understanding the application's limits.

Option C allocates additional resources based only on assumptions instead of real measurements.

Option D prepares disaster recovery documentation, but disaster recovery is unrelated to measuring application performance before a traffic increase.

---

# Laboratory Overview

This laboratory recreates the scenario described in the exam question.

Terraform deploys a simple web application on a Compute Engine virtual machine.

After the application becomes available, a load test is executed using **hey**, a popular HTTP load testing tool.

The generated statistics help analyze the application's behavior before deciding how to scale the infrastructure.

---

# main.tf Explanation

## Terraform Configuration

The Terraform block specifies the minimum Terraform version and installs the required providers.

Two providers are used:

* Google Provider
* Null Provider

The Google provider creates the infrastructure, while the Null provider executes the local load test after deployment.

---

## Google Provider

The provider connects Terraform to the Google Cloud project and defines the default region and zone where resources will be created.

---

## Enable Required APIs

Terraform enables the Compute Engine API before creating any virtual machine resources.

This guarantees that Compute Engine services are available during deployment.

---

## Firewall Rule

A firewall rule allows inbound HTTP traffic on port **8080**.

This allows external users and the load testing tool to access the Flask application running inside the virtual machine.

---

## Compute Engine Instance

Terraform creates a Debian virtual machine.

The instance receives:

* Public IP address
* Default VPC network
* Default service account
* Cloud Platform access scope

A startup script automatically installs and configures the application.

---

## Startup Script

The startup script performs all application installation tasks automatically.

It executes the following actions:

* Updates the operating system.
* Installs Python.
* Installs pip and Python virtual environments.
* Creates the application directory.
* Generates a Flask application.
* Creates the Python dependency file.
* Installs Flask and Gunicorn.
* Starts the Gunicorn web server.
* Waits until the application responds successfully.

All installation logs are stored in:

```text
/var/log/startup.log
```

Gunicorn logs are stored in:

```text
/var/log/gunicorn.log
```

---

## Flask Application

The Flask application exposes a single endpoint.

Each request performs a CPU-intensive calculation before returning an HTML page.

This artificial workload makes the application suitable for load testing because CPU utilization increases as the number of concurrent requests grows.

---

## Load Testing

After the virtual machine becomes available, Terraform waits until the application responds successfully.

The local **hey** executable is then executed automatically.

Example command:

```powershell
.\hey.exe -n 10000 -c 100 http://VM_PUBLIC_IP:8080/
```

The test sends:

* 10,000 HTTP requests
* 100 concurrent users

The results are saved into:

```text
load-test.txt
```

The report includes important performance metrics such as:

* Total requests
* Average latency
* Fastest request
* Slowest request
* Requests per second
* Status code distribution

These values allow engineers to understand how the application behaves before enabling Auto Scaling.

---

# Verification

After the deployment finishes successfully, open the application using:

```text
http://VM_PUBLIC_IP:8080
```

The browser should display the Load Testing Lab page.

Terraform automatically performs the load test and creates the following report:

```text
load-test.txt
```

The report confirms that the application has been tested under load and provides performance statistics.

---

# Conclusion

This laboratory demonstrates Google's recommended approach for capacity planning.

Instead of immediately increasing infrastructure size or enabling Auto Scaling, engineers first execute a load test to understand the application's real performance characteristics.

The collected metrics provide objective data that can be used to make informed scaling decisions.

This workflow directly represents the correct answer to the Professional Cloud DevOps Engineer certification exam.
