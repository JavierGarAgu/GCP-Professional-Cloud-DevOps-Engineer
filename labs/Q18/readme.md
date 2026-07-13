COMMANDS

```
terraform init

terraform plan

terraform apply -auto-approve

gcloud compute instances list
NAME                                                 ZONE            MACHINE_TYPE  PREEMPTIBLE  INTERNAL_IP    EXTERNAL_IP    STATUS
development-environment                              europe-west1-b  e2-medium                  10.132.0.10    34.38.139.225  RUNNING
testing-environment                                  europe-west1-b  e2-medium                  10.132.0.14    34.62.0.171    RUNNING
```

Your company experiences bugs, outages, and slowness in its production systems. Developers use the production environment for new feature development and bug fixes. Configuration and experiments are done in the production environment, causing outages for users. Testers use the production environment for load testing, which often slows the production systems. You need to redesign the environment to reduce the number of bugs and outages in production and to enable testers to toad test new features. What should you do?

D
Create a development environment for writing code and a test environment for configurations, experiments, and load testing.
