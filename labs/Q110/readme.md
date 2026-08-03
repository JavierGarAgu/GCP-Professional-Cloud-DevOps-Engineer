# Q110 - Troubleshooting Network Connectivity with Connectivity Tests

## Scenario

Two Google Kubernetes Engine (GKE) clusters are deployed in different Virtual Private Clouds (VPCs).

The nodes in Cluster A cannot communicate with the nodes in Cluster B. You suspect that the problem is caused by the network configuration.

You do not have SSH access to the nodes or permission to execute commands inside the workloads.

The correct solution is to use **Connectivity Tests** from **Network Intelligence Center**.

---

# Why Connectivity Tests?

Connectivity Tests analyze the network path between two Google Cloud resources without requiring access to the virtual machines or Kubernetes nodes.

The service evaluates:

* VPC routes
* Firewall rules
* Network topology
* Peering configuration
* VPN connections
* Load balancers

It identifies where the connection fails and explains the reason.

This makes it the best troubleshooting tool when direct access to the workloads is unavailable.

---

# Why the Other Options Are Incorrect

## A. Install a Toolbox Container

A toolbox container requires access to the Kubernetes nodes.

The scenario clearly states that node access is not available.

---

## C. Run Traceroute

Running `traceroute` requires execution access inside the workloads or nodes.

Again, the scenario explicitly says that this access is not available.

---

## D. Enable VPC Flow Logs

VPC Flow Logs provide information about accepted and rejected network traffic.

Although useful for network analysis, they do not automatically identify the exact layer where connectivity fails.

Connectivity Tests provide a much more direct diagnosis.

---

# Lab Architecture

The original question uses two GKE clusters located in different VPCs.

To simplify the lab and reduce costs, the same networking scenario was recreated using two Compute Engine virtual machines.

```text
               Google Cloud

        +------------------------+
        |        VPC A           |
        |                        |
        |      +-----------+     |
        |      |   VM A    |     |
        |      +-----------+     |
        +------------------------+

                 No Peering
                 No VPN
                 No Routes

        +------------------------+
        |        VPC B           |
        |                        |
        |      +-----------+     |
        |      |   VM B    |     |
        |      +-----------+     |
        +------------------------+
```

Because there is no network connection between the two VPCs, VM A cannot communicate with VM B.

This reproduces the same networking problem described in the exam question.

---

# Lab Procedure

The infrastructure creates:

* VPC A

* Subnet A

* VM A

* VPC B

* Subnet B

* VM B

No VPC Peering, VPN, or Cloud Interconnect is configured.

After deploying the infrastructure, the troubleshooting process is performed from the Google Cloud Console.

Navigate to:

```text
Network Intelligence Center
        │
        ▼
Connectivity Tests
```

Create a new test:

* Source: VM A
* Destination: VM B

Run the analysis.

Connectivity Tests inspect the complete network path and report that communication cannot be established because no network connectivity exists between the two VPCs.

---

# Connectivity Test Workflow

```text
+-----------+
|   VM A    |
+-----------+
      │
      │
      ▼
Connectivity Test
      │
      ▼
Analyze:

- Routes
- Firewall Rules
- Peering
- VPN
- Network Configuration
      │
      ▼
Connection Failed
      │
      ▼
Root Cause Identified
```

---

# Relationship to the Exam Question

The exam describes two GKE clusters, but the real concept being tested is not Kubernetes.

The objective is to identify the correct Google Cloud troubleshooting tool when direct access to workloads and nodes is unavailable.

Replacing the clusters with Compute Engine virtual machines produces the same networking behavior while keeping the lab simple and inexpensive.

The important lesson is that **Connectivity Tests** can identify network failures from the Google Cloud control plane without requiring SSH access or command execution on the affected systems.
