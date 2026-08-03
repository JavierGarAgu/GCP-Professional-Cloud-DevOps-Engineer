# Cloud Run API Key with Secret Manager

## Overview

This project demonstrates the Google-recommended way to store and use a third-party API key in a Cloud Run application.

The API key is stored securely in Secret Manager instead of being hardcoded in the application or stored in the source code. Cloud Run can then access the secret by referencing it as an environment variable.

## Why Option A is Correct

Option A follows Google best practices for secret management.

The API key is stored as a secret in Secret Manager, and Cloud Run injects the secret into the application as an environment variable. This approach keeps sensitive information outside the application code and makes secret rotation easier.

## Why the Other Options Are Incorrect

* **Option B:** Secret Manager does not require manually decrypting secrets. When a secret is mounted as a volume, Cloud Run automatically provides the plaintext value to the application.
* **Option C:** Cloud KMS is designed to manage encryption keys, not to store application secrets such as API keys.
* **Option D:** Encrypting the API key with Cloud KMS and passing it as an environment variable adds unnecessary complexity. Secret Manager already provides secure storage and integrates directly with Cloud Run.

## Conclusion

The recommended solution is to store the API key in Secret Manager and reference it as an environment variable in the Cloud Run service. This is the simplest, most secure, and Google-recommended approach for managing application secrets.
