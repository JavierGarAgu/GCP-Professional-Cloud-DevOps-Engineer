COMMANDS

```
$LB = terraform output -raw load_balancer_ip

curl http://$LB

1..10 | % { curl http://$LB }

.\hey.exe -n 10000 -c 100 http://$LB/

gcloud compute instances list
```

# Q51 - Improve Service Availability with Multi-Zone Load Balancing

## Exam Question

You support a stateless web-based API that is deployed on a single Compute Engine instance in the `europe-west2-a` zone.

The Service Level Indicator (SLI) for service availability is below the specified Service Level Objective (SLO). A postmortem has revealed that requests to the API regularly time out because the application receives too many requests and eventually runs out of memory.

What should you do to improve service availability?

**A.** Change the specified SLO to match the measured SLI.

**B.** Move the service to higher-specification Compute Engine instances with more memory.

**C.** Set up additional service instances in other zones and load balance the traffic between all instances.

**D.** Set up additional service instances in other zones and use them only as failover if the primary instance becomes unavailable.

**Correct answer: C**

---

# Why is C correct?

The application is **stateless**, which means every request can be processed by any instance.

The problem is not only that a single VM eventually runs out of memory, but also that the entire service depends on one machine.

Simply increasing the size of the VM (option B) only delays the problem. Eventually, a larger VM can also become overloaded.

Using standby instances (option D) improves availability if the VM crashes, but it does not increase the service capacity because only one instance handles traffic during normal operation.

The best solution is to deploy multiple instances in different zones and place them behind a Load Balancer.

This approach provides:

- Horizontal scaling
- Better availability
- Higher capacity
- Zone redundancy

This is exactly what Google recommends for stateless applications running on Compute Engine.

---

# Architecture

Before:

```
                Users
                  |
                  |
            +-----------+
            |   VM API  |
            +-----------+
                  |
          Single Point of Failure
```

After:

```
                    Users
                      |
                      |
             HTTP Load Balancer
                      |
          +-----------+-----------+
          |                       |
          |                       |
   MIG europe-west1-b      MIG europe-west1-c
          |                       |
      +--------+              +--------+
      | API VM |              | API VM |
      +--------+              +--------+
```

Traffic is automatically distributed between both zones.

If one VM becomes unavailable, the Load Balancer continues sending traffic to the healthy instance.

---

# Terraform Resources

This laboratory creates the complete infrastructure needed to demonstrate the recommended solution.

It deploys:

- A Compute Engine Instance Template
- Two Managed Instance Groups
    - europe-west1-b
    - europe-west1-c
- A Health Check
- A Backend Service
- A Global HTTP Load Balancer
- A URL Map
- A Target HTTP Proxy
- A Global Forwarding Rule
- Firewall rules
- A Service Account

---

# Instance Template

The Instance Template defines how every VM is created.

Each VM automatically:

- installs Python
- creates a Python virtual environment
- installs Flask
- deploys a small API
- registers a systemd service
- starts automatically during boot

The application exposes two endpoints:

```
/
```

Returns:

```json
{
    "hostname":"api-b-xxxx",
    "status":"healthy"
}
```

or

```json
{
    "hostname":"api-c-xxxx",
    "status":"healthy"
}
```

and

```
/health
```

used by the Load Balancer Health Check.

The application also allocates a small amount of memory on every request to simulate a service under increasing memory pressure.

---

# Managed Instance Groups

Instead of using standalone virtual machines, this laboratory creates two Managed Instance Groups.

```
api-mig-b
```

Zone:

```
europe-west1-b
```

and

```
api-mig-c
```

Zone:

```
europe-west1-c
```

Managed Instance Groups automatically recreate failed instances if necessary and simplify scaling operations.

---

# Load Balancer

The HTTP Load Balancer sits in front of both Managed Instance Groups.

```
          Client
             |
             |
      HTTP Load Balancer
             |
     +-------+-------+
     |               |
 api-mig-b      api-mig-c
```

Requests are distributed across both zones.

This removes the single point of failure present in the original architecture.

---

# Health Checks

A Compute Engine Health Check periodically calls:

```
/health
```

Only healthy instances receive production traffic.

If one instance stops responding, it is automatically removed from the Backend Service until it becomes healthy again.

---

# Verification

Deploy everything:

```bash
terraform init

terraform apply
```

Get the Load Balancer IP:

```powershell
$LB = terraform output -raw load_balancer_ip
```

Send several requests:

```powershell
1..10 | % { curl http://$LB }
```

The hostname should alternate between both instances.

Example:

```
api-b-xxxx

api-c-xxxx

api-b-xxxx

api-c-xxxx
```

This demonstrates that the Load Balancer is distributing requests across both zones.

Run a simple load test:

```powershell
hey -n 10000 -c 100 http://$LB/
```

A successful execution should return only HTTP 200 responses.

Example:

```
Status code distribution

[200] 10000 responses
```

---

# What this laboratory demonstrates

This laboratory reproduces the architecture described in the correct exam answer.

Instead of relying on a single Compute Engine instance, the service is deployed across multiple availability zones behind a Load Balancer.

This improves availability because the service continues working even if one instance or one zone experiences problems.

It also improves scalability because incoming traffic is shared between multiple servers instead of overloading a single virtual machine.

For stateless applications, horizontal scaling with multiple instances and a Load Balancer is the recommended Google Cloud design pattern and is the reason why option **C** is the correct answer.