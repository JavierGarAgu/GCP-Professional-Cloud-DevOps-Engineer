COMMANDS
```
gcloud auth configure-docker europe-west1-docker.pkg.dev

gcloud auth configure-docker us-west1-docker.pkg.dev

export PROJECT_ID=devops-cert-labs-v3

export IMAGE_NAME=performance-test

export EU_IMAGE=europe-west1-docker.pkg.dev/$PROJECT_ID/performance-europe/$IMAGE_NAME:latest

export US_IMAGE=us-west1-docker.pkg.dev/$PROJECT_ID/performance-usa/$IMAGE_NAME:latest

cat <<'EOF' > benchmark.sh

#!/bin/bash

EU_IMAGE="europe-west1-docker.pkg.dev/devops-cert-labs-v3/performance-europe/performance-test:latest"

US_IMAGE="us-west1-docker.pkg.dev/devops-cert-labs-v3/performance-usa/performance-test:latest"


echo "====================================="
echo "Artifact Registry Region Benchmark"
echo "Started: $(date)"
echo "====================================="


run_test () {

IMAGE=$1
REGION=$2


echo ""
echo "Testing $REGION"
echo "Image: $IMAGE"


TOTAL=0


for i in {1..5}

do

echo "Iteration $i"


START=$(date +%s%3N)


docker pull $IMAGE > /dev/null


END=$(date +%s%3N)


TIME=$((END-START))


echo "$REGION iteration $i: ${TIME} ms"


TOTAL=$((TOTAL+TIME))


docker image rm $IMAGE > /dev/null


done


AVERAGE=$((TOTAL/5))


echo "$REGION average: ${AVERAGE} ms"


}


run_test $EU_IMAGE "EUROPE"


run_test $US_IMAGE "USA"



echo ""
echo "====================================="
echo "Benchmark finished"
echo "Finished: $(date)"
echo "====================================="


EOF

./benchmark.sh | tee registry-performance-results.txt
chmod +x benchmark.sh

=====================================
Artifact Registry Region Benchmark
Started: Wed Jul 22 19:55:46 UTC 2026
=====================================

Testing EUROPE
Image: europe-west1-docker.pkg.dev/devops-cert-labs-v3/performance-europe/performance-test:latest
Iteration 1

EUROPE iteration 1: 14624 ms
Iteration 2
EUROPE iteration 2: 14626 ms
Iteration 3
EUROPE iteration 3: 14518 ms
Iteration 4
EUROPE iteration 4: 14381 ms
Iteration 5
EUROPE iteration 5: 14474 ms
EUROPE average: 14524 ms

Testing USA
Image: us-west1-docker.pkg.dev/devops-cert-labs-v3/performance-usa/performance-test:latest
Iteration 1
USA iteration 1: 20882 ms
Iteration 2
USA iteration 2: 20453 ms
Iteration 3
USA iteration 3: 20913 ms
Iteration 4
USA iteration 4: 20287 ms
Iteration 5
USA iteration 5: 26020 ms
USA average: 21711 ms

=====================================
Benchmark finished
Finished: Wed Jul 22 19:58:51 UTC 2026
=====================================
```

Tienes razón. El anterior parecía más una explicación de documentación técnica que un README de laboratorio como los que estás haciendo para tu repositorio. Te dejo uno con formato más natural de GitHub README, estilo B2 inglés, explicando laboratorio, Terraform, Cloud Build, prueba, resultado y mentalidad del examen.

```markdown
# Container Registry Regional Performance Test

## Lab Overview

This laboratory demonstrates the importance of choosing the correct location for container image repositories in Google Cloud.

In a real production environment, applications running on Google Kubernetes Engine (GKE) constantly download container images during:

- New deployments.
- Scaling operations.
- Node replacements.
- Rolling updates.
- Disaster recovery scenarios.

Because of this, the location of the container registry can directly affect deployment speed and application availability.

The objective of this lab is to prove that storing container images close to the Kubernetes workloads provides better performance.

---

# Scenario

A company has:

- A build system running in the United States.
- Production workloads running in Europe.

The DevOps team wants to maximize image download performance for the production environment.

The question is:

> Where should the container images be stored?

The correct principle is:

**Store container images close to the systems that consume them, not close to the systems that build them.**

The build system only uploads the image once, but production systems download the image many times.

---

# Lab Architecture

The infrastructure created in this laboratory is:

```

```
                Cloud Build

                     |
                     |
             Build Docker Image

                     |
          +----------+----------+
          |                     |
          |                     |
          v                     v

 Artifact Registry        Artifact Registry

   europe-west1              us-west1


          |                     |
          |                     |
          +----------+----------+

                     |

                     v

          Compute Engine VM

          europe-west1-b


                     |

                     |

          Docker Pull Benchmark

                     |

                     |

          Compare Download Time
```

```

---

# Terraform Infrastructure

Terraform is used to create all required Google Cloud resources.

The main goal is to create a controlled environment where we can compare both registries.

---

# Resources Created

## Artifact Registry - Europe

A Docker repository is created in:

```

europe-west1

```

Repository:

```

performance-europe

```

This repository stores the container image close to the production environment.

Example image:

```

europe-west1-docker.pkg.dev/PROJECT_ID/performance-europe/performance-test:latest

```

---

## Artifact Registry - United States

A second Docker repository is created in:

```

us-west1

```

Repository:

```

performance-usa

```

Example image:

```

us-west1-docker.pkg.dev/PROJECT_ID/performance-usa/performance-test:latest

```

Both repositories contain exactly the same Docker image.

This allows us to compare only the network distance impact.

---

# Cloud Build Pipeline

Cloud Build is used to automate the container image creation process.

The pipeline performs the following actions:

1. Builds the Docker image.

2. Tags the image for the European repository.

3. Tags the image for the US repository.

4. Pushes the image to both Artifact Registry locations.

The final result is:

```

Europe Artifact Registry

*

|
|
performance-test:latest

USA Artifact Registry

*

|
|
performance-test:latest

```

---

# Docker Image

The Docker image contains a simple Python application.

The image size is intentionally increased by creating a large test file during the Docker build process.

The reason is that very small images do not show meaningful differences between regions.

A larger image allows us to measure real download performance.

---

# Compute Engine Benchmark Machine

A Compute Engine virtual machine is created in:

```

europe-west1-b

````

This machine represents a production workload running in Europe.

The VM is responsible for:

- Authenticating with Artifact Registry.
- Downloading both container images.
- Measuring the download time.

---

# Performance Test

Inside the Compute Engine instance, the following test is executed.

First, the European image is downloaded:

```bash
docker pull europe-west1-docker.pkg.dev/...
````

The download time is measured.

Then the image is removed:

```bash
docker image rm IMAGE
```

The same process is repeated with the US image:

```bash
docker pull us-west1-docker.pkg.dev/...
```

The test is executed multiple times to calculate an average value.

---

# Expected Result

The expected result is:

```
Europe Registry = Faster

USA Registry = Slower
```

Example:

```
EUROPE average: 2500 ms

USA average: 6500 ms
```

The European repository provides better performance because the Compute Engine instance is located in Europe.

---

# Why The European Registry Is Faster

Network distance affects latency.

When a GKE node downloads an image:

```
GKE Europe

      |
      |
      v

Artifact Registry Europe
```

The traffic stays close geographically.

However:

```
GKE Europe

      |
      |
      v

Artifact Registry USA
```

The traffic crosses regions, increasing:

* Latency.
* Transfer time.
* Deployment duration.

---

# Professional Cloud DevOps Engineer Exam Explanation

## Question

Some production services are running in GKE in Europe.

The build system runs in the United States.

You want to push container images to a scalable registry and maximize bandwidth when transferring images to the cluster.

What should you do?

Correct answer:

```
Use the European container registry location.
```

---

# Why Option C Is Correct

The build location is not the most important factor.

The important factor is where the images are consumed.

The build system performs:

```
Build system

       |
       |
       v

Registry

(one upload)
```

The production environment performs:

```
GKE Node 1

GKE Node 2

GKE Node 3

       |
       |
       v

Registry

(many downloads)
```

Because production workloads download images many times, the registry should be close to the GKE cluster.

---

# Why The Other Options Are Incorrect

## Option A - gcr.io

The generic hostname does not guarantee the best regional performance.

The objective is to choose the closest registry location.

---

## Option B - us.gcr.io

This places the images in the United States.

The build system is already there, but the production workload is in Europe.

The image downloads would have higher latency.

---

## Option D - Private registry on Compute Engine

A self-managed registry increases operational overhead.

The company would need to manage:

* Availability.
* Security.
* Storage.
* Scaling.
* Maintenance.

Google Artifact Registry is the recommended managed solution.

---

# Key Lessons Learned

This laboratory demonstrates an important DevOps principle:

**Optimize resources for the consumers, not the producers.**

For container images:

* Developers build images.
* CI/CD systems publish images.
* Kubernetes clusters consume images.

Therefore:

The registry should be located close to the Kubernetes clusters.

---

# Final Conclusion

The experiment confirms the exam concept.

A European GKE cluster should use a European Artifact Registry repository to achieve better image download performance.

The correct design decision is:

```
Keep container images close to production workloads.
```

