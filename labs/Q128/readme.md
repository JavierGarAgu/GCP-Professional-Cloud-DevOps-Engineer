# Q128 - Planning Capacity for Multi-Region Managed Instance Groups

## Objective

Deploy a production service using a Managed Instance Group (MIG) across multiple regions. Each instance requires a large amount of resources, so capacity planning is important before deployment.

```
                    +----------------------+
                    |   Global Load        |
                    |     Balancer         |
                    +----------+-----------+
                               |
               +---------------+---------------+
               |                               |
     +---------v---------+           +---------v---------+
     |   Region A MIG    |           |   Region B MIG    |
     | Large VM Instances|           | Large VM Instances|
     +---------+---------+           +---------+---------+
               |                               |
               +---------------+---------------+
                               |
                 Check Regional Quotas First
```

## Correct Answer

**D. Validate that the resource requirements are within the available project quota limits of each region.**

## Explanation

The service will run in multiple regions and each VM uses many resources. Before the Managed Instance Group scales, Google Cloud must have enough available quota in every region.

If the project does not have enough regional quota (such as vCPUs or other resources), new instances cannot be created, even if autoscaling is enabled.

Capacity planning means verifying that every target region has sufficient quota for the expected workload.

## Why the Other Answers Are Incorrect

**A. Monitor results of Cloud Trace**

Cloud Trace measures application latency and performance. It does not help determine whether enough infrastructure resources are available.

**B. Use the n2-highcpu-96 machine type**

Choosing a larger machine type does not solve the capacity planning problem. In fact, it increases quota consumption.

**C. Use an internal load balancer**

An internal load balancer distributes traffic inside a VPC. It does not help with regional capacity or quota planning.

## Key Exam Tip

When a question includes:

- Managed Instance Groups
- Autoscaling
- Multiple regions
- Large machine types
- Capacity planning

Think about **regional project quotas** first.

Always verify that every deployment region has enough available quota before relying on autoscaling.