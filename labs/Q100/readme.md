# Q100 - Firewall Rules Logging with Cloud Logging

## Scenario

You are managing an application running on a Compute Engine virtual machine.

The application exposes an HTTP API, and a firewall rule allows traffic from `0.0.0.0/0`.

The goal is to record the IP address of every client that accesses the application while using the fewest possible configuration steps.

The correct solution is to enable **Firewall Rules Logging**.

---

## Exam Question

**You are managing an application that runs in Compute Engine. The application uses a custom HTTP server to expose an API that is accessed by other applications through an internal TCP/UDP load balancer. A firewall rule allows access to the API port from `0.0.0.0/0`. You need to configure Cloud Logging to log each IP address that accesses the API by using the fewest number of steps. What should you do first?**

**A.** Enable Packet Mirroring on the VPC.

**B.** Install the Ops Agent on the Compute Engine instances.

**C.** Enable logging on the firewall rule.

**D.** Enable VPC Flow Logs on the subnet.

**Correct answer:** **C**

---

## Why Option C?

Firewall Rules Logging automatically writes firewall connection information into Cloud Logging.

Each log entry includes useful information such as:

- Source IP
- Destination IP
- Destination port
- Protocol
- Firewall action (ALLOW or DENY)

Since the firewall rule already allows traffic, enabling logging is enough to start collecting access information.

No application changes are required.

---

## Why Not the Other Options?

### A. Packet Mirroring

Packet Mirroring copies network packets to another instance for deep packet inspection.

It is designed for security analysis and intrusion detection, not for basic access logging.

It is much more complex than required.

---

### B. Ops Agent

The Ops Agent collects operating system metrics and application logs.

However, it does not automatically log incoming client connections.

If the application does not generate logs, the Ops Agent has nothing to send to Cloud Logging.

Additional configuration would also be required.

---

### D. VPC Flow Logs

VPC Flow Logs record network traffic inside a subnet.

Although they contain IP addresses, they are intended for network analysis and troubleshooting.

For this scenario, enabling firewall logging is the simplest and most direct solution.

---

# Architecture

```text
                    Internet
                        |
                        |
                  Client Request
                        |
                        v
             +----------------------+
             | Firewall Rule        |
             | Allow TCP 80         |
             | Logging Enabled      |
             +----------------------+
                   |          |
                   |          |
                   |          +-------> Cloud Logging
                   |                     |
                   |                     |
                   |              Source IP
                   |              Destination IP
                   |              Port
                   |              Protocol
                   |              Action
                   |
                   v
          +-------------------+
          | Compute Engine VM |
          | Debian 12         |
          | Nginx             |
          +-------------------+
```

---

## Terraform Resources

This lab creates:

- Compute Engine virtual machine
- Firewall rule allowing HTTP traffic
- Firewall Rules Logging
- Startup script that installs Nginx
- Public IP output

---

## Deployment

Initialize Terraform:

```bash
terraform init
```

Deploy the infrastructure:

```bash
terraform apply -auto-approve
```

---

## Verify the Application

Get the public IP:

```bash
terraform output
```

Open the application:

```text
http://PUBLIC_IP
```

or

```bash
curl http://PUBLIC_IP
```

The browser should display the Nginx page created by the startup script.

---

## Verify Firewall Logs

Generate some HTTP requests:

```bash
curl http://PUBLIC_IP
curl http://PUBLIC_IP
curl http://PUBLIC_IP
```

Read firewall logs:

```bash
gcloud logging read \
'resource.type="gce_firewall_rule"
AND resource.labels.firewall_rule_name="allow-http"' \
--limit=10
```

The logs contain information similar to:

- Source IP
- Destination IP
- Destination port
- TCP protocol
- ALLOW action

This confirms that every connection matching the firewall rule is automatically recorded in Cloud Logging.

---

## Key Learning Points

- Firewall Rules Logging is the quickest way to record incoming connections.
- No application changes are required.
- No Ops Agent installation is required.
- No Packet Mirroring is required.
- No VPC Flow Logs are required.
- Firewall Rules Logging integrates directly with Cloud Logging.
- It is the recommended solution when the objective is simply to identify which IP addresses accessed a service.

---

## Conclusion

This lab demonstrates the recommended Google Cloud solution for logging client access to a Compute Engine application.

By enabling Firewall Rules Logging, every connection allowed by the firewall rule is automatically sent to Cloud Logging, making it the simplest and fastest solution for this type of requirement.