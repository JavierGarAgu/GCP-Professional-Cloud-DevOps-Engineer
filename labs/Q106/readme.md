# Q106 - Investigating Application Latency with Cloud Trace

## Scenario

After the latest application release, the application's performance has degraded. The engineering team suspects that one of the downstream dependencies is making some requests slower.

The correct answer is **Cloud Trace**.

## Why Cloud Trace?

Cloud Trace records the complete path of a request as it travels through the application and its dependencies. It divides the request into multiple **spans**, allowing engineers to see how much time is spent in each service or operation.

This makes it possible to identify which dependency is responsible for the increased latency.

For example, Cloud Trace can reveal:

* Time spent processing the request in the application.
* Time spent communicating with Redis or a database.
* Time spent waiting for an external API.
* The total latency of the request.

Instead of only knowing that a request took 800 ms, Cloud Trace shows exactly where those 800 ms were spent.

This is the best tool for investigating slow downstream dependencies after a new application release.

## Why the other options are incorrect

### Error Reporting

Error Reporting is used to collect exceptions and stack traces. It helps diagnose application failures, but it does not explain why requests are slower.

### Managed Service for Prometheus

Managed Service for Prometheus collects infrastructure and application metrics such as CPU usage, memory consumption, request rate, and latency. However, it does not follow the complete execution path of an individual request.

### Cloud Profiler

Cloud Profiler identifies CPU and memory bottlenecks inside the application's code. It is useful for optimizing resource usage, but it does not trace requests across different services or dependencies.

## Reference to Q1

This question is based on the same concept covered in **Q1**.

In Q1, a Node.js application was instrumented with **OpenTelemetry**, traces were sent to an **OpenTelemetry Collector**, and then exported to **Google Cloud Trace**. That lab demonstrated how distributed tracing can identify which component or downstream dependency is responsible for increased request latency.

Q106 tests the same knowledge in a theoretical scenario instead of asking you to deploy the tracing infrastructure.
