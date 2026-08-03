# Q127 - Horizontal Pod Autoscaler (HPA)

```
+------------------------------------------------------+
|                 TRAFFIC SCALING FLOW                 |
+------------------------------------------------------+

        Users
          |
          v
    Incoming Traffic
          |
          v
   Kubernetes Service
          |
          v
      Deployment
          |
          v
+----------------------+
| Horizontal Pod       |
| Autoscaler (HPA)     |
+----------------------+
          |
          +------------------------+
          |                        |
          v                        v
     Low CPU Usage           High CPU Usage
          |                        |
          v                        v
      Fewer Pods             More Pods
```

## Question

You deployed a **stateless application** into a large Standard GKE cluster.

The application:

- Runs multiple pods.
- Receives inconsistent traffic.
- Must provide a consistent user experience.
- Must optimize cluster resource usage.

Which solution should you choose?

**Correct Answer: B - Configure a Horizontal Pod Autoscaler (HPA).**

---

# Why B is Correct

The most important keyword in this question is:

**Inconsistent traffic**

Traffic changes during the day.

Example:

```
08:00 ---> Low traffic

12:00 ---> Medium traffic

20:00 ---> High traffic

23:00 ---> Low traffic
```

A fixed number of pods would either:

- Waste resources during low traffic.
- Become overloaded during high traffic.

HPA solves this problem automatically.

It continuously monitors metrics such as CPU utilization and adjusts the number of running pods.

Example:

```
Traffic increases
        |
        v
CPU utilization increases
        |
        v
HPA creates more Pods
        |
        v
Application keeps responding quickly
```

When traffic decreases:

```
Traffic decreases
        |
        v
CPU utilization decreases
        |
        v
HPA removes unnecessary Pods
        |
        v
Lower infrastructure cost
```

This provides:

- Consistent application performance.
- Better resource utilization.
- Automatic scaling without manual intervention.

---

# Why the Other Answers Are Incorrect

## A - Configure a cron job

A cron job scales according to time.

Example:

```
08:00 --> 2 Pods

20:00 --> 8 Pods
```

The problem is that traffic is unpredictable.

If traffic suddenly increases at 15:00, the cron job will not react.

---

## C - Configure a Vertical Pod Autoscaler

Vertical Pod Autoscaler changes the resources of individual pods.

Example:

```
Old Pod

CPU: 500m
Memory: 512Mi

↓

New Pod

CPU: 1 vCPU
Memory: 1Gi
```

It does **not** increase the number of pods.

The application already runs multiple replicas, so horizontal scaling is the recommended solution.

---

## D - Configure Cluster Autoscaling

Cluster Autoscaler manages **nodes**, not pods.

Example:

```
Node 1
  |
  +--> Pod
  +--> Pod

Node 2
  |
  +--> Pod
```

If there is no space for additional pods, Cluster Autoscaler creates more nodes.

However, it does **not** decide how many application pods should exist.

That responsibility belongs to HPA.

---

# HPA vs Cluster Autoscaler

```
Traffic increases
        |
        v
Horizontal Pod Autoscaler
        |
        v
Creates more Pods
        |
        v
Enough space?

      Yes -----------------> Continue

      No
       |
       v
Cluster Autoscaler
       |
       v
Creates more Nodes
```

HPA reacts to application load.

Cluster Autoscaler reacts to infrastructure capacity.

---

# Lab Reference

The practical implementation of this topic was already completed in:

**Q13**

That laboratory demonstrates:

- Creating a Standard GKE cluster.
- Deploying a stateless application.
- Configuring CPU requests and limits.
- Creating a Horizontal Pod Autoscaler.
- Observing automatic pod scaling under load.
- Understanding the relationship between HPA and Cluster Autoscaler.

Q127 focuses on understanding **why** HPA is the correct solution for applications with inconsistent traffic.

---

# Key Exam Concepts

When you read:

- Stateless application
- Multiple pods
- Inconsistent traffic
- Maintain user experience
- Automatic scaling

Think immediately:

```
Stateless Application
          +
Changing Traffic
          +
Multiple Pods

          =

Horizontal Pod Autoscaler
```

The correct answer is:

**B - Configure a Horizontal Pod Autoscaler (HPA).**