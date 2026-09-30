# GCP Secret Manager Terraform Module

Reusable Terraform module for creating Google Secret Manager secrets with
optional CMEK encryption and secret-level IAM access.

## Features

- Creates one or more Secret Manager secret containers
- Supports automatic replication
- Supports user-managed regional replicas
- Supports optional CMEK for automatic replication
- Supports optional CMEK per user-managed replica
- Supports secret-level IAM access
- Exposes secret IDs and fully qualified resource names
- Does not store secret payloads or create secret versions
- Designed for composition with the reusable GCP KMS and service-account modules

## Important Security Boundary

This module manages Secret Manager infrastructure and access configuration.

It intentionally does not accept or create secret payloads through a
`google_secret_manager_secret_version` resource.

Secret payloads supplied to Terraform resources can be recorded in Terraform
state. Secret values should instead be delivered through an approved workflow
that is separate from this reusable infrastructure module.

## Automatic Replication

```hcl
module "secret_manager" {
  source = "git::https://github.com/Kedesai/terraform.git//gcp/secret-manager"

  project_id = var.project_id

  secrets = {
    application = {
      secret_id        = "application-secret"
      replication_type = "AUTOMATIC"

      labels = {
        managed_by  = "terraform"
        environment = "dev"
      }
    }
  }
}
```

## Automatic Replication with CMEK

```hcl
module "secret_manager" {
  source = "git::https://github.com/Kedesai/terraform.git//gcp/secret-manager"

  project_id = var.project_id

  secrets = {
    application = {
      secret_id        = "application-secret"
      replication_type = "AUTOMATIC"

      automatic_kms_key_name = var.kms_key_id

      labels = {
        managed_by  = "terraform"
        environment = "dev"
      }
    }
  }
}
```

## User-Managed Replication

```hcl
module "secret_manager" {
  source = "git::https://github.com/Kedesai/terraform.git//gcp/secret-manager"

  project_id = var.project_id

  secrets = {
    database = {
      secret_id        = "database-secret"
      replication_type = "USER_MANAGED"

      user_managed_replicas = [
        {
          location = "us-central1"
        },
        {
          location = "us-east1"
        }
      ]

      labels = {
        managed_by  = "terraform"
        environment = "prod"
      }
    }
  }
}
```

## User-Managed Replication with CMEK

```hcl
module "secret_manager" {
  source = "git::https://github.com/Kedesai/terraform.git//gcp/secret-manager"

  project_id = var.project_id

  secrets = {
    database = {
      secret_id        = "database-secret"
      replication_type = "USER_MANAGED"

      user_managed_replicas = [
        {
          location     = "us-central1"
          kms_key_name = var.us_central1_kms_key_id
        },
        {
          location     = "us-east1"
          kms_key_name = var.us_east1_kms_key_id
        }
      ]
    }
  }
}
```

## Secret-Level IAM Access

The `secret` property references the logical map key under `secrets`, not the
actual Secret Manager secret ID.

```hcl
module "secret_manager" {
  source = "git::https://github.com/Kedesai/terraform.git//gcp/secret-manager"

  project_id = var.project_id

  secrets = {
    application = {
      secret_id = "application-secret"
    }
  }

  secret_iam_bindings = {
    application_access = {
      secret = "application"
      role   = "roles/secretmanager.secretAccessor"

      members = [
        "serviceAccount:application@my-project.iam.gserviceaccount.com"
      ]
    }
  }
}
```

## Combining Reusable Modules

```hcl
module "kms" {
  source = "git::https://github.com/Kedesai/terraform.git//gcp/kms"

  project_id    = var.project_id
  location      = var.kms_location
  key_ring_name = var.key_ring_name

  keys = {
    secrets = {
      name = "secrets-key"
    }
  }
}

module "service_account" {
  source = "git::https://github.com/Kedesai/terraform.git//gcp/service-account"

  project_id = var.project_id

  account_id   = "application-sa"
  display_name = "Application Service Account"
}

module "secret_manager" {
  source = "git::https://github.com/Kedesai/terraform.git//gcp/secret-manager"

  project_id = var.project_id

  secrets = {
    application = {
      secret_id              = "application-secret"
      automatic_kms_key_name = module.kms.crypto_key_ids["secrets"]
    }
  }

  secret_iam_bindings = {
    application_access = {
      secret = "application"
      role   = "roles/secretmanager.secretAccessor"

      members = [
        module.service_account.member
      ]
    }
  }
}
```

## Outputs

The module exposes:

- `secret_ids`
- `secret_names`
- `secret_replication`
- `secret_iam_members`

No secret-version values or payloads are exposed.

GCP Secret Manager Terraform Module
Reusable Terraform module for creating Google Secret Manager secrets with optional CMEK encryption and secret-level IAM access.

Features
Creates one or more Secret Manager secret containers
Supports automatic replication
Supports user-managed regional replicas
Supports optional CMEK for automatic replication
Supports optional CMEK per user-managed replica
Supports secret-level IAM access
Exposes secret IDs and fully qualified resource names
Does not store secret payloads or create secret versions
Designed for composition with the reusable GCP KMS and service-account modules
Important Security Boundary
This module manages Secret Manager infrastructure and access configuration.

It intentionally does not accept or create secret payloads through a google_secret_manager_secret_version resource.

Secret payloads supplied to Terraform resources can be recorded in Terraform state. Secret values should instead be delivered through an approved workflow that is separate from this reusable infrastructure module.

Automatic Replication
module "secret_manager" {
  source = "git::https://github.com/Kedesai/terraform.git//gcp/secret-manager"

  project_id = var.project_id

  secrets = {
    application = {
      secret_id        = "application-secret"
      replication_type = "AUTOMATIC"

      labels = {
        managed_by  = "terraform"
        environment = "dev"
      }
    }
  }
}
Automatic Replication with CMEK
module "secret_manager" {
  source = "git::https://github.com/Kedesai/terraform.git//gcp/secret-manager"

  project_id = var.project_id

  secrets = {
    application = {
      secret_id        = "application-secret"
      replication_type = "AUTOMATIC"

      automatic_kms_key_name = var.kms_key_id

      labels = {
        managed_by  = "terraform"
        environment = "dev"
      }
    }
  }
}
User-Managed Replication
module "secret_manager" {
  source = "git::https://github.com/Kedesai/terraform.git//gcp/secret-manager"

  project_id = var.project_id

  secrets = {
    database = {
      secret_id        = "database-secret"
      replication_type = "USER_MANAGED"

      user_managed_replicas = [
        {
          location = "us-central1"
        },
        {
          location = "us-east1"
        }
      ]

      labels = {
        managed_by  = "terraform"
        environment = "prod"
      }
    }
  }
}
User-Managed Replication with CMEK
module "secret_manager" {
  source = "git::https://github.com/Kedesai/terraform.git//gcp/secret-manager"

  project_id = var.project_id

  secrets = {
    database = {
      secret_id        = "database-secret"
      replication_type = "USER_MANAGED"

      user_managed_replicas = [
        {
          location     = "us-central1"
          kms_key_name = var.us_central1_kms_key_id
        },
        {
          location     = "us-east1"
          kms_key_name = var.us_east1_kms_key_id
        }
      ]
    }
  }
}
Secret-Level IAM Access
The secret property references the logical map key under secrets, not the actual Secret Manager secret ID.

module "secret_manager" {
  source = "git::https://github.com/Kedesai/terraform.git//gcp/secret-manager"

  project_id = var.project_id

  secrets = {
    application = {
      secret_id = "application-secret"
    }
  }

  secret_iam_bindings = {
    application_access = {
      secret = "application"
      role   = "roles/secretmanager.secretAccessor"

      members = [
        "serviceAccount:application@my-project.iam.gserviceaccount.com"
      ]
    }
  }
}
Combining Reusable Modules
module "kms" {
  source = "git::https://github.com/Kedesai/terraform.git//gcp/kms"

  project_id    = var.project_id
  location      = var.kms_location
  key_ring_name = var.key_ring_name

  keys = {
    secrets = {
      name = "secrets-key"
    }
  }
}

module "service_account" {
  source = "git::https://github.com/Kedesai/terraform.git//gcp/service-account"

  project_id = var.project_id

  account_id   = "application-sa"
  display_name = "Application Service Account"
}

module "secret_manager" {
  source = "git::https://github.com/Kedesai/terraform.git//gcp/secret-manager"

  project_id = var.project_id

  secrets = {
    application = {
      secret_id              = "application-secret"
      automatic_kms_key_name = module.kms.crypto_key_ids["secrets"]
    }
  }

  secret_iam_bindings = {
    application_access = {
      secret = "application"
      role   = "roles/secretmanager.secretAccessor"

      members = [
        module.service_account.member
      ]
    }
  }
}
Outputs
The module exposes:

secret_ids
secret_names
secret_replication
secret_iam_members
No secret-version values or payloads are exposed.