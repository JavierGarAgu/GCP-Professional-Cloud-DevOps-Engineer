# Network Tier and Load Balancer Selection

## Scenario

The application is deployed in **one region (europe-west2)** and only serves users in the **United Kingdom**.

The question asks for the **most cost-effective** solution.

The correct answer is:

**D. Standard Tier with a regional load balancer**

---

# Why?

The application does not need Google's global private network because:

* It runs in a single region.
* Users are located in one country.
* The goal is to reduce costs.

A **Regional External Application Load Balancer** with **Standard Tier** provides the required functionality at a lower cost than Premium Tier.

---

# Network Tier Comparison

| Feature                    | Standard Tier | Premium Tier |
| -------------------------- | ------------- | ------------ |
| Google global network      | No            | Yes          |
| Regional load balancer     | Yes           | Yes          |
| Global load balancer       | No            | Yes          |
| Multi-region applications  | No            | Yes          |
| Global users               | No            | Yes          |
| Lower network cost         | Yes           | No           |
| Best performance worldwide | No            | Yes          |

---

# Quick Decision Table

| Scenario            | Network Tier | Load Balancer |
| ------------------- | ------------ | ------------- |
| Single region       | Standard     | Regional      |
| Local users         | Standard     | Regional      |
| Lowest cost         | Standard     | Regional      |
| Multiple regions    | Premium      | Global        |
| Global users        | Premium      | Global        |
| Highest performance | Premium      | Global        |

---

# Exam Tip

Look for these keywords:

* **Single region**
* **Local users**
* **Cost-effective**

These usually indicate:

```text
Standard Tier
+
Regional Load Balancer
```

If the question mentions:

* Global users
* Multiple regions
* Best performance
* Lowest latency worldwide

The correct choice is usually:

```text
Premium Tier
+
Global Load Balancer
```
