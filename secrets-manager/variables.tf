# -----------------------------------------------------------------------------
# GCP Project Configuration
# -----------------------------------------------------------------------------

variable "project_id" {
  description = "GCP project ID where Secret Manager resources will be created."
  type        = string
}

# -----------------------------------------------------------------------------
# Secret Definitions
#
# The map key is the caller-defined logical identifier used by Terraform.
# The secret_id property is the actual Secret Manager secret name in GCP.
#
# replication_type supports:
# - AUTOMATIC
# - USER_MANAGED
#
# automatic_kms_key_name is optional and applies only to automatic replication.
#
# user_managed_replicas is used only when replication_type is USER_MANAGED.
# Each replica requires a location and can optionally use a location-compatible
# Cloud KMS Crypto Key.
# -----------------------------------------------------------------------------

variable "secrets" {
  description = "Map of Secret Manager secrets to create."

  type = map(object({
    secret_id        = string
    replication_type = optional(string, "AUTOMATIC")

    automatic_kms_key_name = optional(string)

    user_managed_replicas = optional(list(object({
      location     = string
      kms_key_name = optional(string)
    })), [])

    labels = optional(map(string), {})
  }))

  default = {}

  validation {
    condition = alltrue([
      for secret in values(var.secrets) :
      contains(
        ["AUTOMATIC", "USER_MANAGED"],
        upper(secret.replication_type)
      )
    ])

    error_message = "Each replication_type must be AUTOMATIC or USER_MANAGED."
  }

  validation {
    condition = alltrue([
      for secret in values(var.secrets) :
      upper(secret.replication_type) != "USER_MANAGED" ||
      length(secret.user_managed_replicas) > 0
    ])

    error_message = "A USER_MANAGED secret must define at least one user_managed_replicas entry."
  }

  validation {
    condition = alltrue([
      for secret in values(var.secrets) :
      upper(secret.replication_type) != "AUTOMATIC" ||
      length(secret.user_managed_replicas) == 0
    ])

    error_message = "An AUTOMATIC secret must not define user_managed_replicas."
  }
}

# -----------------------------------------------------------------------------
# Secret-Level IAM Assignments
#
# This input grants IAM roles on individual secrets rather than at the entire
# project level.
#
# The secret property must reference a logical key from var.secrets, not the
# actual GCP secret_id.
#
# Example:
#
# secret_iam_bindings = {
#   application_access = {
#     secret = "application"
#     role   = "roles/secretmanager.secretAccessor"
#
#     members = [
#       "serviceAccount:application@project.iam.gserviceaccount.com"
#     ]
#   }
# }
# -----------------------------------------------------------------------------

variable "secret_iam_bindings" {
  description = "Secret-level IAM roles and members to assign."

  type = map(object({
    secret  = string
    role    = string
    members = set(string)
  }))

  default = {}

  validation {
    condition = alltrue([
      for binding in values(var.secret_iam_bindings) :
      contains(keys(var.secrets), binding.secret)
    ])

    error_message = "Every secret IAM binding must reference a logical key defined in var.secrets."
  }
}
