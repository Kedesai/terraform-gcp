# -----------------------------------------------------------------------------
# GCP Project Configuration
# -----------------------------------------------------------------------------

variable "project_id" {
  description = "GCP project ID where Cloud Storage buckets will be created."
  type        = string
}


# -----------------------------------------------------------------------------
# Cloud Storage Bucket Configuration
#
# The reusable module accepts a map so callers can create one or more buckets.
#
# The Terraform map key is a logical identifier. The actual GCP bucket name is
# supplied using the name property.
# -----------------------------------------------------------------------------

variable "buckets" {
  description = "Map of Cloud Storage buckets to create."

  type = map(object({
    name          = string
    location      = string
    storage_class = optional(string, "STANDARD")

    # Protect the bucket from accidental Terraform deletion.
    force_destroy = optional(bool, false)

    # Recommended access-control model for modern GCS buckets.
    uniform_bucket_level_access = optional(bool, true)

    # Prevent public IAM grants from being introduced on the bucket.
    public_access_prevention = optional(string, "enforced")

    # Optional object versioning.
    versioning_enabled = optional(bool, false)

    # Optional customer-managed encryption key.
    kms_key_name = optional(string)

    # Optional resource labels.
    labels = optional(map(string), {})

    # Optional lifecycle rules used to transition or delete objects.
    lifecycle_rules = optional(list(object({
      action = object({
        type          = string
        storage_class = optional(string)
      })

      condition = object({
        age                   = optional(number)
        created_before        = optional(string)
        with_state            = optional(string)
        matches_storage_class = optional(list(string))
        num_newer_versions    = optional(number)
      })
    })), [])
  }))

  default = {}
}


# -----------------------------------------------------------------------------
# Bucket-Level IAM Configuration
#
# IAM grants are optional and scoped to individual buckets.
#
# The bucket property references the logical key in var.buckets rather than
# requiring callers to duplicate the actual GCS bucket name.
# -----------------------------------------------------------------------------

variable "bucket_iam_bindings" {
  description = "Bucket-level IAM role assignments."

  type = map(object({
    bucket  = string
    role    = string
    members = set(string)
  }))

  default = {}

  validation {
    condition = alltrue([
      for binding in values(var.bucket_iam_bindings) :
      contains(keys(var.buckets), binding.bucket)
    ])

    error_message = "Each bucket IAM binding must reference a logical key defined in var.buckets."
  }
}
