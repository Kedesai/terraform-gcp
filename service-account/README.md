# GCP Service Account Terraform Module

Reusable Terraform module for creating or consuming a Google Cloud
service account and optionally assigning project-level IAM roles.

## Features

- Create a new service account
- Consume an existing service account
- Optional project-level IAM role assignments
- Multiple project IAM roles
- Clean outputs for downstream Terraform modules
- No hardcoded IAM roles
- Designed for composition with GKE, VM, MIG and other GCP modules

## Create Service Account

```hcl
module "service_account" {
  source = "git::https://github.com/Kedesai/terraform.git//gcp/service-account"

  project_id = var.project_id

  create_service_account = true

  account_id   = "gke-platform"
  display_name = "GKE Platform Service Account"
  description  = "Service account used by the GKE platform."

  project_roles = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter"
  ]
}
```

## Use Existing Service Account

```hcl
module "service_account" {
  source = "git::https://github.com/Kedesai/terraform.git//gcp/service-account"

  project_id = var.project_id

  create_service_account = false

  existing_service_account_email = var.service_account_email

  project_roles = [
    "roles/logging.logWriter"
  ]
}
```

## Create Service Account Without IAM Roles

```hcl
module "service_account" {
  source = "git::https://github.com/Kedesai/terraform.git//gcp/service-account"

  project_id = var.project_id

  create_service_account = true

  account_id   = "application-sa"
  display_name = "Application Service Account"
}
```

## Outputs

The module exposes:

- `email`
- `name`
- `member`
- `account_id`
- `unique_id`

These outputs can be consumed by other reusable modules and callers.

GCP Service Account Terraform Module
Reusable Terraform module for creating or consuming a Google Cloud service account and optionally assigning project-level IAM roles.

Features
Create a new service account
Consume an existing service account
Optional project-level IAM role assignments
Multiple project IAM roles
Clean outputs for downstream Terraform modules
No hardcoded IAM roles
Designed for composition with GKE, VM, MIG and other GCP modules
Create Service Account
module "service_account" {
  source = "git::https://github.com/Kedesai/terraform.git//gcp/service-account"

  project_id = var.project_id

  create_service_account = true

  account_id   = "gke-platform"
  display_name = "GKE Platform Service Account"
  description  = "Service account used by the GKE platform."

  project_roles = [
    "roles/logging.logWriter",
    "roles/monitoring.metricWriter"
  ]
}
Use Existing Service Account
module "service_account" {
  source = "git::https://github.com/Kedesai/terraform.git//gcp/service-account"

  project_id = var.project_id

  create_service_account = false

  existing_service_account_email = var.service_account_email

  project_roles = [
    "roles/logging.logWriter"
  ]
}
Create Service Account Without IAM Roles
module "service_account" {
  source = "git::https://github.com/Kedesai/terraform.git//gcp/service-account"

  project_id = var.project_id

  create_service_account = true

  account_id   = "application-sa"
  display_name = "Application Service Account"
}
Outputs
The module exposes:

email
name
member
account_id
unique_id
These outputs can be consumed by other reusable modules and callers.