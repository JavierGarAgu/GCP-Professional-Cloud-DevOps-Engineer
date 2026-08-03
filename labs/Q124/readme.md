COMMANDS
```
gcloud compute instance-groups managed delete processor-mig --region europe-west1
gcloud eventarc triggers list --location=europe-west1
gcloud compute instance-groups managed describe processor-mig `
--region europe-west1 `
--format="value(targetSize)"
echo test > batch1.txt
gcloud storage cp batch1.txt gs://devops-cert-labs-v4-batch-uploads/
gcloud functions logs read scale-managed-instance-group `
--region europe-west1 `
--gen2
       <!-- scale-managed-instance-group  0dek01esCBAm  2026-08-03 18:00:25.274  Processing file: batch1.txt
       scale-managed-instance-group  0dek01esCBAm  2026-08-03 18:00:25.274  New object uploaded
E      scale-managed-instance-group                2026-08-03 18:00:25.257 -->
```

# Q124 - Scalable Batch Processing with Google Cloud

This project implements a scalable batch processing architecture using Cloud Storage, Eventarc, Cloud Functions Gen2 and Compute Engine Managed Instance Groups.

Third-party systems upload data securely to Cloud Storage, which triggers a Cloud Function when new objects are created.

The Cloud Function starts the processing workflow while Compute Engine MIG provides scalable compute capacity.

The autoscaler automatically adjusts the number of instances depending on workload, reducing costs while maintaining performance.

Terraform is used to deploy and manage the complete infrastructure as code.