# Cost-Benefit Analysis for Availability Improvements

This exercise evaluates whether increasing an application's availability is financially worthwhile.

---

## Scenario

```text
+-------------------------------+
| Current Availability : 99.9%  |
| Target Availability  : 99.99% |
| Annual Revenue       : $1,000,000 |
| Upgrade Cost         : $2,000 |
+-------------------------------+
```

---

## Step 1: Calculate the Downtime Reduction

The key value is **downtime**, not availability.

```text
Current State

Availability : 99.90%
Downtime     :  0.10%

█████████████████████████████████████████████████░
                                                 ^
                                             Downtime
```

```text
Target State

Availability : 99.99%
Downtime     :  0.01%

██████████████████████████████████████████████████
                                                  ^
                                           Smaller downtime
```

Downtime improvement:

```text
0.10% - 0.01% = 0.09%
```

Convert it to decimal:

```text
0.09% = 0.0009
```

---

## Step 2: Calculate the Financial Benefit

The application generates:

```text
$1,000,000 per year
```

Multiply the annual revenue by the downtime improvement.

```text
$1,000,000 × 0.0009 = $900
```

Result:

```text
+-----------------------------+
| Annual Revenue : $1,000,000 |
| Downtime Saved : 0.09%      |
| Money Saved    : $900       |
+-----------------------------+
```

---

## Step 3: Compare Benefit vs Cost

```text
             +-------------+
             | Comparison  |
             +-------------+

Benefit : $900
Cost    : $2,000
```

```text
        $900
         |
         |############
         |
         |
         |####################################
                     $2,000
```

Since:

```text
$900 < $2,000
```

the investment is **not financially justified**.

---

## Formula for the Exam

```text
Money Saved =
Annual Revenue ×
(Old Downtime − New Downtime)
```

Example:

```text
$1,000,000 × (0.001 − 0.0001)

= $1,000,000 × 0.0009

= $900
```

---

## Correct Answer

```text
+-----------+
| Answer: A |
+-----------+
```

Reason:

- Downtime is reduced by **0.09%**.
- The company saves **$900** per year.
- The upgrade costs **$2,000**.
- The benefit is lower than the cost.

Therefore, the investment is **not worth it**.

---

## Exam Tip

Always follow these steps:

```text
+------------------------------+
| 1. Find old downtime          |
| 2. Find new downtime          |
| 3. Calculate the difference   |
| 4. Multiply by revenue        |
| 5. Compare with the cost      |
+------------------------------+
```

Remember:

```text
Availability ↑
      does NOT mean
Revenue ↑

Only the recovered downtime
creates additional value.
```