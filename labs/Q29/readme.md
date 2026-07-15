COMMANDS

```
tail -f /var/log/startup.log

terraform output

curl.exe $(terraform output -raw application_url)

curl.exe $(terraform output -raw metrics_url)

1..20 | ForEach-Object {

    echo "==============================="
    echo "Request $_"

    curl.exe $(terraform output -raw application_url)

    echo ""
    echo ""

}

echo ""
echo "==============================="
echo "QUALITY SLI"
echo "==============================="

curl.exe $(terraform output -raw metrics_url)

echo ""
echo ""
echo "==============================="
echo "GENERATING 100 REQUESTS..."
echo "==============================="

1..100 | ForEach-Object {

    curl.exe -s $(terraform output -raw application_url) > $null

}

echo ""
echo "==============================="
echo "UPDATED METRICS"
echo "==============================="

curl.exe $(terraform output -raw metrics_url)

echo ""
echo ""
echo "==============================="
echo "RESET COUNTERS"
echo "==============================="

curl.exe $(terraform output -raw reset_url)

echo ""
echo ""
echo "==============================="
echo "METRICS AFTER RESET"
echo "==============================="

curl.exe $(terraform output -raw metrics_url)
```

# Google Cloud Professional Cloud DevOps Engineer Lab

# Question - Choosing the Correct Service Level Indicator (Quality SLI)

---

## Introduction

This repository contains a practical lab created while preparing for the **Google Cloud Professional Cloud DevOps Engineer** certification.

The objective of this lab is to understand how to measure **user experience** using the correct **Service Level Indicator (SLI)**.

The simulated application is built using a small Flask web service running on a Google Compute Engine virtual machine. The application represents a homepage that depends on several independent microservices. Some of those services randomly fail, causing the homepage to be served in **degraded mode** instead of failing completely.

This behavior reproduces the scenario described in the certification question.

---

# Question

> You support a high-traffic web application with a microservice architecture.
>
> The homepage displays several widgets such as weather, stock prices, sports, and news.
>
> Each widget depends on its own microservice.
>
> Sometimes individual microservices fail. Instead of returning an error page, the application still serves the homepage, but some widgets are missing.
>
> Users prefer degraded content instead of receiving no page at all.
>
> Which Service Level Indicator (SLI) should you use?

**Answer:**

> **A — A quality SLI: the ratio of non-degraded responses to total responses.**

---

# Why Answer A is Correct

The objective is **not** to measure whether every microservice is healthy.

The objective is to measure **the experience of the final user.**

If one widget fails but the homepage is still available, users can continue using the application.

Therefore, the most useful metric is measuring how often users receive a **complete homepage** compared to a **degraded homepage**.

This is exactly what a **Quality SLI** measures.

The formula is:

```text
Quality SLI =
Non-Degraded Responses
----------------------
Total Responses
```

If the homepage remains fully functional most of the time, the Quality SLI will stay high.

If degraded responses become frequent, the Quality SLI decreases, showing that the user experience is becoming worse.

---

# Why the Other Answers Are Incorrect

## B — Availability SLI

Availability measures whether services are running.

In this scenario, some microservices may fail while the homepage is still available.

Users care about the homepage, not about the internal state of every microservice.

Therefore, Availability is not the correct indicator.

---

## C — Freshness SLI

Freshness measures how recent the displayed information is.

Examples include:

- weather updates
- financial prices
- news articles

The problem described in the question is not outdated information.

The problem is that widgets disappear because microservices fail.

Freshness does not measure this.

---

## D — Latency SLI

Latency measures response time.

Although latency is important, users are complaining because content is missing.

The problem is not that the page is slow.

The problem is that the homepage is degraded.

Latency alone cannot measure this situation.

---

# Lab Architecture

The Terraform configuration deploys one Compute Engine virtual machine.

Inside the VM, a Flask application simulates a homepage composed of four independent microservices.

```
                Homepage
                    |
    ---------------------------------
    |        |        |            |
 Weather   Stocks    News      Sports
```

Each widget randomly succeeds or fails.

Example:

```
Weather  -> OK
Stocks   -> FAILED
News     -> OK
Sports   -> OK
```

Instead of returning an HTTP error, the homepage is still generated.

The response is marked as:

```
Homepage Status = DEGRADED
```

If every widget succeeds, the homepage becomes:

```
Homepage Status = NON_DEGRADED
```

---

# Quality SLI Calculation

The application stores four counters.

```
Total Requests

Non-Degraded Responses

Degraded Responses

Quality SLI Percentage
```

Every request updates these values.

The Quality SLI is calculated as:

```text
Quality SLI =
Non-Degraded Responses
----------------------
Total Requests
```

For example:

```
Total Requests = 25

Non-Degraded = 21

Degraded = 4
```

The Quality SLI becomes:

```
21 / 25 = 84%
```

This means that 84% of users received a complete homepage, while 16% received a degraded one.

---

# Terraform Resources

The Terraform configuration creates:

- Google Compute Engine VM
- Firewall rule for HTTP access
- Default service account
- Monitoring permissions
- Logging permissions
- Startup script
- Flask application
- Application outputs

The startup script automatically installs Python, creates a virtual environment, installs Flask, and starts the application.

---

# Application Endpoints

The application exposes three endpoints.

## Homepage

```
/
```

Returns the simulated homepage.

Possible responses:

```
NON_DEGRADED
```

or

```
DEGRADED
```

---

## Metrics

```
/metrics
```

Returns the current Quality SLI statistics.

Example:

```json
{
  "total_requests": 25,
  "non_degraded_responses": 21,
  "degraded_responses": 4,
  "quality_sli_percent": 84.0
}
```

---

## Reset

```
/reset
```

Resets every counter back to zero.

Useful for repeating the experiment.

---

# Testing the Lab

The homepage can be requested multiple times using curl.

Example:

```powershell
1..20 | ForEach-Object {
    curl.exe $(terraform output -raw application_url)
}
```

Typical output:

```json
{
  "homepage_status":"DEGRADED",
  "quality_sli_percent":80.0,
  "total_requests":15,
  "non_degraded":12,
  "degraded":3
}
```

As more degraded responses appear, the Quality SLI decreases.

---

# Observations

During testing, several homepage requests were executed.

Some requests returned:

```
NON_DEGRADED
```

while others returned:

```
DEGRADED
```

The Quality SLI percentage changed automatically after every request.

Example progression:

| Requests | Non-Degraded | Degraded | Quality SLI |
|-----------|-------------:|---------:|------------:|
| 10 | 10 | 0 | 100% |
| 15 | 12 | 3 | 80% |
| 20 | 16 | 4 | 80% |
| 25 | 21 | 4 | 84% |

This demonstrates how Quality SLI reflects the actual user experience instead of only measuring infrastructure health.

---

# Key Learning Points

This lab demonstrates several important Site Reliability Engineering concepts:

- A service can continue operating even if some internal components fail.
- Users often prefer degraded functionality over complete downtime.
- Service Level Indicators should measure what users actually experience.
- A Quality SLI directly measures how often users receive a complete service.
- Monitoring user experience is often more valuable than monitoring internal components alone.

---

# Conclusion

This lab demonstrates why **Answer A** is the correct choice.

The homepage remains available even when individual microservices fail.

Instead of measuring infrastructure availability or response latency, the application measures the proportion of complete homepage responses compared to all requests.

This directly reflects the user experience and represents the correct **Quality Service Level Indicator (Quality SLI)**.

For this reason, the correct answer is:

> **A — A Quality SLI: the ratio of non-degraded responses to total responses.**