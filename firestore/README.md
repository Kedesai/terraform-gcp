GCP Firestore Caller
Terraform caller for deploying a Google Cloud Firestore database using the reusable Firestore module.

Architecture
HCP Terraform Workspace
          |
          v
   Firestore Caller
          |
          v
Reusable Firestore Module
          |
          v
Firestore Database
Repository
Reusable module:

Kedesai/terraform/gcp/firestore
Caller:

Kedesai/call-gcp-terraform/firestore
Directory Structure
firestore/
├── versions.tf
├── variables.tf
├── main.tf
├── outputs.tf
├── terraform.tfvars
└── README.md
No data.tf is currently required because Firestore does not consume an upstream Terraform workspace output.

No locals.tf is currently required because the caller does not need to transform its input variables.

HCP Terraform Workspace
Suggested workspace:

gcp-firestore
Repository:

Kedesai/call-gcp-terraform
Working directory:

firestore
Recommended settings:

Auto apply: Disabled
Speculative plans: Enabled
Required Variables
project_id  = "my-gcp-project"
location_id = "nam5"
Basic Deployment
database_name = "(default)"
database_type = "FIRESTORE_NATIVE"

concurrency_mode = "PESSIMISTIC"

enable_point_in_time_recovery = true
delete_protection             = true
deletion_policy               = "DELETE"
Safe Defaults
database_name = "(default)"
database_type = "FIRESTORE_NATIVE"

concurrency_mode = "PESSIMISTIC"

app_engine_integration_mode = "DISABLED"

enable_point_in_time_recovery = true
delete_protection             = true
deletion_policy               = "DELETE"
Delete Protection
Delete protection is enabled by default.

Before intentionally deleting the database:

delete_protection = false
Apply the change before destroying the database.

Outputs
The caller exposes:

database_id
database_name
location_id
database_type
These become HCP Terraform workspace outputs and can later be consumed by other workspaces if required.

IAM
IAM is intentionally not configured in this caller.

IAM will be addressed separately as part of the consolidated IAM and Landing Zone design.

The caller is responsible only for specifying the desired Firestore deployment configuration.

Validation
terraform fmt -recursive
terraform init
terraform validate
terraform plan
Design Principles
Firestore implementation remains in the reusable module
Environment configuration remains in the caller
Provider configuration belongs to the caller
Authentication is supplied externally
IAM remains separate from the service caller
No unnecessary HCP workspace dependencies are introduced
Delete protection is enabled by default
Point-in-time recovery is enabled by default