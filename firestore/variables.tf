# -----------------------------------------------------------------------------
# GCP Project
# -----------------------------------------------------------------------------

variable "project_id" {
  description = "GCP project ID where the Firestore database is created."
  type        = string
}


# -----------------------------------------------------------------------------
# Firestore Database
# -----------------------------------------------------------------------------

variable "database_name" {
  description = "Firestore database name."
  type        = string
  default     = "(default)"

  validation {
    condition     = trimspace(var.database_name) != ""
    error_message = "database_name must not be empty."
  }
}

variable "location_id" {
  description = "Location of the Firestore database."
  type        = string
}

variable "database_type" {
  description = "Firestore database type."
  type        = string
  default     = "FIRESTORE_NATIVE"

  validation {
    condition = contains(
      [
        "FIRESTORE_NATIVE",
        "DATASTORE_MODE"
      ],
      upper(var.database_type)
    )

    error_message = "database_type must be FIRESTORE_NATIVE or DATASTORE_MODE."
  }
}


# -----------------------------------------------------------------------------
# Concurrency
# -----------------------------------------------------------------------------

variable "concurrency_mode" {
  description = "Concurrency mode for the Firestore database."
  type        = string
  default     = "PESSIMISTIC"

  validation {
    condition = contains(
      [
        "OPTIMISTIC",
        "PESSIMISTIC",
        "OPTIMISTIC_WITH_ENTITY_GROUPS"
      ],
      upper(var.concurrency_mode)
    )

    error_message = "Unsupported Firestore concurrency_mode."
  }
}


# -----------------------------------------------------------------------------
# App Engine Integration
# -----------------------------------------------------------------------------

variable "app_engine_integration_mode" {
  description = "App Engine integration mode."
  type        = string
  default     = "DISABLED"

  validation {
    condition = contains(
      [
        "DISABLED",
        "ENABLED"
      ],
      upper(var.app_engine_integration_mode)
    )

    error_message = "app_engine_integration_mode must be DISABLED or ENABLED."
  }
}


# -----------------------------------------------------------------------------
# Point-in-Time Recovery
# -----------------------------------------------------------------------------

variable "enable_point_in_time_recovery" {
  description = "Enable Firestore point-in-time recovery."
  type        = bool
  default     = true
}


# -----------------------------------------------------------------------------
# Protection and Deletion Behavior
#
# Delete protection protects the database against accidental deletion.
#
# deletion_policy controls Terraform behavior when the resource is removed.
# -----------------------------------------------------------------------------

variable "delete_protection" {
  description = "Enable Firestore delete protection."
  type        = bool
  default     = true
}

variable "deletion_policy" {
  description = "Firestore deletion policy."
  type        = string
  default     = "DELETE"

  validation {
    condition = contains(
      [
        "DELETE",
        "ABANDON"
      ],
      upper(var.deletion_policy)
    )

    error_message = "deletion_policy must be DELETE or ABANDON."
  }
}


# -----------------------------------------------------------------------------
# Resource Tags
#
# Firestore database tags are optional.
# -----------------------------------------------------------------------------

variable "tags" {
  description = "Resource Manager tags applied to the Firestore database."
  type        = map(string)
  default     = {}
}
