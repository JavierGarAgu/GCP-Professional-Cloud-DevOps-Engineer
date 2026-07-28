SIMULATION

steps:

# 1. Run unit tests
- name: bash
  id: "Unit Tests"
  entrypoint: bash
  args:
    - -c
    - |
      echo "================================="
      echo "Running unit tests"
      echo "================================="

      sleep 3

      echo "Test 1: Application startup ........ PASSED"
      echo "Test 2: API response ............... PASSED"
      echo "Test 3: Database connection ......... PASSED"

      echo "Unit tests completed successfully"


# 2. Build container image
- name: bash
  id: "Build Container"
  entrypoint: bash
  args:
    - -c
    - |
      echo "================================="
      echo "Building Docker container image"
      echo "================================="

      sleep 3

      echo "docker build -t app:v1 ."

      echo "Container image created:"
      echo "app:v1"


# 3. Push image to registry
- name: bash
  id: "Push Artifact"
  entrypoint: bash
  args:
    - -c
    - |
      echo "================================="
      echo "Pushing container image"
      echo "================================="

      sleep 3

      echo "docker push registry/app:v1"

      echo "Image stored in Artifact Registry"


# 4. Deploy to testing environment
- name: bash
  id: "Deploy Testing"
  entrypoint: bash
  args:
    - -c
    - |
      echo "================================="
      echo "Deploying application to TEST environment"
      echo "================================="

      sleep 3

      echo "Deployment successful"
      echo "Environment: testing"


# 5. Integration tests
- name: bash
  id: "Integration Tests"
  entrypoint: bash
  args:
    - -c
    - |
      echo "================================="
      echo "Running integration tests"
      echo "================================="

      sleep 3

      echo "Test API endpoints ........ PASSED"
      echo "Test service communication  PASSED"

      echo "Integration tests completed"


# 6. Acceptance tests
- name: bash
  id: "Acceptance Tests"
  entrypoint: bash
  args:
    - -c
    - |
      echo "================================="
      echo "Running acceptance tests"
      echo "================================="

      sleep 3

      echo "User workflow test ........ PASSED"
      echo "Business requirements ..... PASSED"

      echo "Acceptance tests completed"


# 7. Production deployment
- name: bash
  id: "Deploy Production"
  entrypoint: bash
  args:
    - -c
    - |
      echo "================================="
      echo "Deploying to PRODUCTION"
      echo "================================="

      sleep 3

      echo "kubectl apply -f deployment.yaml"

      echo "Production deployment successful"


# 8. Smoke tests
- name: bash
  id: "Smoke Tests"
  entrypoint: bash
  args:
    - -c
    - |
      echo "================================="
      echo "Running smoke tests"
      echo "================================="

      sleep 3

      echo "Application health check .... PASSED"
      echo "HTTP response ............... 200 OK"

      echo "Pipeline finished successfully"


timeout: "1200s"

# Simulated CI/CD Pipeline with Cloud Build

## Overview

This project simulates a CI/CD pipeline using Google Cloud Build.

The goal is to understand the complete DevOps workflow without deploying real infrastructure.

## Pipeline Flow

The pipeline performs the following steps:

1. Run unit tests.
2. Build a container image.
3. Push the image to a container registry.
4. Deploy the application to a testing environment.
5. Run integration tests.
6. Run acceptance tests.
7. Deploy the application to production.
8. Run smoke tests.

## Architecture

```
Developer
    |
    v
Cloud Build Trigger
    |
    v
Unit Tests
    |
    v
Build Container
    |
    v
Container Registry
    |
    v
Testing Environment
    |
    v
Integration Tests
    |
    v
Acceptance Tests
    |
    v
Production Deployment
    |
    v
Smoke Tests
```

## Notes

This laboratory only simulates the CI/CD process.

No real containers, Kubernetes clusters, or cloud resources are deployed.

The objective is to understand the typical CI/CD workflow used in production environments.

This pipeline follows DevOps best practices:
- Automate testing.
- Build artifacts after successful tests.
- Validate changes before production.
- Verify the application after deployment.