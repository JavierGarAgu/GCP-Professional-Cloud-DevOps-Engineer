COMMANDS
```
Get-Content secret.enc 

#$ø¾Tl™ôŽz+=ÎÏ’ž—xˆ§ëÈì<n+äc•.W#ÎÏDÓÉE5ß¾(V¼ÑÎDªŽ¿ÚYî¨Gi¤åƒ83–/ƒ+Ð@õ‡²ß¥ùAåPS 

Get-Content secret.dec 

#MySuperSecretPassword123!
```

# Google Cloud Professional Cloud DevOps Engineer

## Question

You are deploying an application that needs to access sensitive information. You need to ensure that this information is encrypted and the risk of exposure is minimal if a breach occurs. What should you do?

**A.** Store the encryption keys in Cloud Key Management Service (KMS) and rotate the keys frequently.

**B.** Inject the secret at the time of instance creation via an encrypted configuration management system.

**C.** Integrate the application with a Single Sign-On (SSO) system and do not expose secrets to the application.

**D.** Leverage a continuous build pipeline that produces multiple versions of the secret for each instance of the application.

**Correct answer:** **A**

---

# Explanation

The application needs to work with sensitive information such as passwords, API keys, certificates, or encryption keys. The best practice in Google Cloud is to store cryptographic keys in **Cloud Key Management Service (Cloud KMS)** instead of storing them inside the application or virtual machines.

Cloud KMS provides a secure and managed environment for encryption keys. Access to the keys is controlled through IAM, every operation is audited, and keys can be rotated automatically to reduce the impact of a compromised key.

Automatic key rotation is an important security feature because old key versions can eventually be replaced by new versions without requiring manual key creation.

The other options are not the best solution.

Option B injects secrets into the instance, but the secrets still exist inside the virtual machine after deployment.

Option C focuses on user authentication with SSO. It does not solve the problem of protecting encryption keys.

Option D creates multiple secret versions during the build process, but this does not improve key management or encryption security.

---

# Solution Overview

This laboratory demonstrates the recommended Google Cloud approach for managing encryption keys.

Terraform performs the following tasks:

* Enables the Cloud KMS API.
* Creates a dedicated Service Account for the application.
* Creates a Cloud KMS Key Ring.
* Creates an encryption key with automatic rotation.
* Grants the application permission to encrypt and decrypt data using IAM.
* Executes a PowerShell demonstration using Terraform `local-exec`.

During the demonstration, Terraform automatically:

1. Creates a plaintext file containing a secret.
2. Encrypts the file using Cloud KMS.
3. Deletes the plaintext file.
4. Decrypts the encrypted file.
5. Displays the recovered secret.
6. Shows the Cloud KMS key configuration.
7. Lists the available key versions.

This demonstrates that the application never stores the encryption key locally. Instead, Cloud KMS performs the cryptographic operations while securely managing the key.

---

# main.tf Explanation

## Terraform Configuration

The Terraform block defines the required Terraform version and installs the Google Cloud and Null providers.

The Google provider creates the cloud infrastructure, while the Null provider is used to execute the PowerShell demonstration after all resources have been deployed.

---

## Provider

The provider connects Terraform to the target Google Cloud project and selects the default deployment region.

---

## Enable Required APIs

Before Cloud KMS resources can be created, Terraform enables the required Google Cloud services.

This ensures that Cloud KMS and IAM are available before the remaining resources are deployed.

---

## Service Account

A dedicated Service Account represents the application.

Instead of allowing every user or resource to access the encryption key, only this Service Account receives permission to perform encryption and decryption operations.

This follows the principle of least privilege.

---

## Cloud KMS Key Ring

The Key Ring acts as a logical container for cryptographic keys.

It organizes encryption keys inside Cloud KMS but does not perform encryption itself.

---

## Cloud KMS Crypto Key

Terraform creates an encryption key with the purpose:

* **ENCRYPT_DECRYPT**

The key also includes an automatic rotation period of 30 days.

Regular key rotation reduces the impact of a compromised encryption key and follows Google Cloud security best practices.

---

## IAM Permissions

Terraform grants the Service Account the following role:

`roles/cloudkms.cryptoKeyEncrypterDecrypter`

This permission allows the application to encrypt and decrypt data without exposing the encryption key itself.

---

## PowerShell Demonstration

After the infrastructure has been created, Terraform executes a PowerShell script using the `local-exec` provisioner.

The script performs the following actions automatically:

* Creates a plaintext secret.
* Encrypts the secret using Cloud KMS.
* Removes the plaintext file.
* Decrypts the encrypted file.
* Displays the recovered secret.
* Shows the key configuration.
* Lists the available key versions.

This practical demonstration confirms that Cloud KMS is correctly protecting the secret.

---

# Verification

After running `terraform apply`, the following files should exist:

* `secret.enc`
* `secret.dec`

The plaintext file is automatically deleted after encryption.

The content of `secret.dec` should match the original secret, proving that Cloud KMS successfully encrypted and decrypted the data.

Terraform also displays the created Key Ring, Crypto Key, and Service Account as outputs.

---

# Conclusion

This laboratory demonstrates the recommended Google Cloud approach for protecting sensitive information.

Instead of storing encryption keys inside applications or virtual machines, Cloud KMS securely manages the keys while IAM controls access permissions. Automatic key rotation further improves security by reducing the lifetime of each encryption key version.

This implementation directly represents the correct answer for the Professional Cloud DevOps Engineer certification exam.
