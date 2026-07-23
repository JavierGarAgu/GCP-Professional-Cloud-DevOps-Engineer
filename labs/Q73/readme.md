# SLI vs SLO Lab (Reporting Feature Question)

## 1. The Exam Question

You are responsible for the reliability of a high-volume enterprise application. A large number of users report that an important subset of the application's functionality (a data-intensive reporting feature) is consistently failing with an HTTP 500 error. When you check your dashboards, you notice a strong correlation between the failures and a metric that represents the size of an internal queue used for generating reports. You trace the failures to a reporting backend with high I/O wait times. You fix it by resizing the backend's persistent disk (PD).

Now you need to define an availability Service Level Indicator (SLI) for the report generation feature. How would you define it?

- A. As the I/O wait times aggregated across all report generation backends.
- B. As the proportion of report generation requests that result in a successful response.
- C. As the application's report generation queue size compared to a known-good threshold.
- D. As the reporting backend PD throughput capacity compared to a known-good threshold.

**Correct answer: B.**

This one is pure theory, no infrastructure to build here. It is about knowing the difference between an SLI and an SLO, and knowing what actually counts as "user-facing."

## 2. What an SLI Actually Is

An SLI is a raw, directly measured metric. Nothing fancy. The classic formula from the SRE world is:

```
SLI = good events / valid events
```

For an availability SLI, "good events" means requests that got a successful response. That is it. No threshold, no comparison, just the plain ratio measured from real traffic.

An SLO is a different thing. It is the target you set for that SLI, like "the SLI must stay above 99.9 percent." The SLO adds a threshold on top of an SLI. It does not replace it.

This is the key thing this question is testing: can you tell an SLI apart from an SLO, and can you tell a user-facing metric apart from an internal one.

## 3. Why B Is Correct

Option B says: the proportion of report generation requests that result in a successful response.

- It is measured directly from live traffic. No guessing, no internal state, just counting successes vs total requests.
- It represents what the user actually experiences. The user does not know or care about queue size or disk I/O. They only know if their report came back or not.
- It stands alone as an SLI. You are not comparing it against a threshold in the definition itself; the threshold comes later, as the SLO.

That is exactly the textbook definition of an availability SLI.

## 4. Why the Other Options Are Wrong

**A. I/O wait times aggregated across all backends.**
This is an internal infrastructure metric. It helped you find the root cause during debugging, but the user never sees "I/O wait." It is a diagnostic signal, not a user-facing outcome.

**C. Queue size compared to a known-good threshold.**
Two problems at once here. First, queue size is an internal proxy metric, not something the user experiences directly. Second, "compared to a known-good threshold" is describing an SLO being bolted onto an internal metric, not a clean SLI. You could have a big queue with no failures, or failures with a small queue. It correlates with the problem, but correlation is not the same as being the actual measure of user success.

**D. PD throughput capacity compared to a known-good threshold.**
Same story as C, just one layer deeper into the infrastructure. It is even further from what the user sees. Disk throughput is a resource metric, not an outcome metric, and again it mixes in a threshold comparison that belongs to an SLO, not an SLI.

## 5. The General Rule for This Type of Question

Whenever an exam question gives you an option that:

- measures something internal to the system (queue size, disk throughput, CPU, I/O wait, memory), and/or
- compares that internal thing to a "known-good threshold" inside the definition itself,

that option is describing an SLO applied to an infrastructure metric, not a proper SLI.

The correct SLI option will almost always be phrased as a plain ratio or rate tied to what the user experiences: successful responses, latency under a certain value, correct results, and so on. No threshold baked into the definition, and no internal system metric standing in for the user's experience.

Keep that rule in your back pocket. It solves basically every SLI/SLO question on this kind of exam.