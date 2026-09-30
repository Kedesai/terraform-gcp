# -----------------------------------------------------------------------------
# GCP Project Configuration
# -----------------------------------------------------------------------------

variable "project_id" {
  description = "GCP project containing the Cloud SQL resources."
  type        = string

  validation {
    condition     = trimspace(var.project_id) != ""
    error_message = "project_id must not be empty."
  }
}


# -----------------------------------------------------------------------------
# Cloud SQL Instance Configuration
# -----------------------------------------------------------------------------

variable "instance_name" {
  description = "Cloud SQL instance name."
  type        = string

  validation {
    condition     = trimspace(var.instance_name) != ""
    error_message = "instance_name must not be empty."
  }
}

variable "region" {
  description = "GCP region containing the Cloud SQL instance."
  type        = string

  validation {
    condition     = trimspace(var.region) != ""
    error_message = "region must not be empty."
  }
}

variable "database_version" {
  description = "Cloud SQL database engine/version, such as POSTGRES_15, MYSQL_8_0, or SQLSERVER_2022_STANDARD."
  type        = string

  validation {
    condition = (
      startswith(upper(var.database_version), "POSTGRES_") ||
      startswith(upper(var.database_version), "MYSQL_") ||
      startswith(upper(var.database_version), "SQLSERVER_")
    )

    error_message = "database_version must identify a PostgreSQL, MySQL, or SQL Server Cloud SQL engine."
  }
}

variable "tier" {
  description = "Cloud SQL machine tier."
  type        = string

  validation {
    condition     = trimspace(var.tier) != ""
    error_message = "tier must not be empty."
  }
}

variable "availability_type" {
  description = "Cloud SQL availability type."
  type        = string
  default     = "ZONAL"

  validation {
    condition = contains(
      ["ZONAL", "REGIONAL"],
      upper(var.availability_type)
    )

    error_message = "availability_type must be ZONAL or REGIONAL."
  }
}

variable "edition" {
  description = "Optional Cloud SQL edition, such as ENTERPRISE or ENTERPRISE_PLUS."
  type        = string
  default     = null

  validation {
    condition = (
      var.edition == null ||
      contains(
        ["ENTERPRISE", "ENTERPRISE_PLUS"],
        upper(var.edition)
      )
    )

    error_message = "edition must be ENTERPRISE, ENTERPRISE_PLUS, or null."
  }
}


# -----------------------------------------------------------------------------
# Networking
#
# This module does not create:
#
# - A VPC network
# - A Private Service Access range
# - A Service Networking connection
#
# At least one connectivity mechanism must be configured:
#
# - private_network
# - ipv4_enabled = true
# -----------------------------------------------------------------------------

variable "ipv4_enabled" {
  description = "Enable a public IPv4 address for the Cloud SQL instance."
  type        = bool
  default     = false
}

variable "private_network" {
  description = "Existing VPC network ID or self-link used for Cloud SQL private IP."
  type        = string
  default     = null

  validation {
    condition = (
      var.private_network != null ||
      var.ipv4_enabled
    )

    error_message = "Either private_network must be provided or ipv4_enabled must be true."
  }
}

variable "allocated_ip_range" {
  description = "Optional allocated Private Service Access range name."
  type        = string
  default     = null

  validation {
    condition = (
      var.allocated_ip_range == null ||
      var.private_network != null
    )

    error_message = "allocated_ip_range can only be specified when private_network is configured."
  }
}

variable "enable_private_path_for_google_cloud_services" {
  description = "Allow supported Google Cloud services to access the instance through private IP."
  type        = bool
  default     = false

  validation {
    condition = (
      !var.enable_private_path_for_google_cloud_services ||
      var.private_network != null
    )

    error_message = "enable_private_path_for_google_cloud_services requires private_network."
  }
}


# -----------------------------------------------------------------------------
# SSL Configuration
# -----------------------------------------------------------------------------

variable "ssl_mode" {
  description = "Optional SSL mode used for Cloud SQL client connections."
  type        = string
  default     = null

  validation {
    condition = (
      var.ssl_mode == null ||
      contains(
        [
          "ALLOW_UNENCRYPTED_AND_ENCRYPTED",
          "ENCRYPTED_ONLY",
          "TRUSTED_CLIENT_CERTIFICATE_REQUIRED"
        ],
        upper(var.ssl_mode)
      )
    )

    error_message = "ssl_mode must be ALLOW_UNENCRYPTED_AND_ENCRYPTED, ENCRYPTED_ONLY, TRUSTED_CLIENT_CERTIFICATE_REQUIRED, or null."
  }

  validation {
    condition = !(
      try(
        upper(var.ssl_mode) == "TRUSTED_CLIENT_CERTIFICATE_REQUIRED",
        false
      ) &&
      startswith(
        upper(var.database_version),
        "SQLSERVER_"
      )
    )

    error_message = "TRUSTED_CLIENT_CERTIFICATE_REQUIRED is not supported for SQL Server."
  }
}


# -----------------------------------------------------------------------------
# Public IP Authorized Networks
#
# These entries are relevant only when public IPv4 access is enabled.
# -----------------------------------------------------------------------------

variable "authorized_networks" {
  description = "Networks authorized to reach the Cloud SQL public IP."

  type = list(object({
    name            = string
    value           = string
    expiration_time = optional(string)
  }))

  default = []

  validation {
    condition = (
      length(var.authorized_networks) == 0 ||
      var.ipv4_enabled
    )

    error_message = "authorized_networks can only be configured when ipv4_enabled is true."
  }
}


# -----------------------------------------------------------------------------
# Storage Configuration
# -----------------------------------------------------------------------------

variable "disk_type" {
  description = "Cloud SQL persistent disk type."
  type        = string
  default     = "PD_SSD"

  validation {
    condition = contains(
      ["PD_SSD", "PD_HDD"],
      upper(var.disk_type)
    )

    error_message = "disk_type must be PD_SSD or PD_HDD."
  }
}

variable "disk_size_gb" {
  description = "Initial Cloud SQL storage size in GB."
  type        = number
  default     = 20

  validation {
    condition     = var.disk_size_gb > 0
    error_message = "disk_size_gb must be greater than zero."
  }
}

variable "disk_autoresize" {
  description = "Allow Cloud SQL to automatically increase storage."
  type        = bool
  default     = true
}

variable "disk_autoresize_limit" {
  description = "Maximum automatic disk size in GB. Zero leaves the service default behavior."
  type        = number
  default     = 0

  validation {
    condition     = var.disk_autoresize_limit >= 0
    error_message = "disk_autoresize_limit cannot be negative."
  }

  validation {
    condition = (
      var.disk_autoresize_limit == 0 ||
      var.disk_autoresize_limit >= var.disk_size_gb
    )

    error_message = "disk_autoresize_limit must be zero or greater than or equal to disk_size_gb."
  }
}


# -----------------------------------------------------------------------------
# Automated Backup Configuration
# -----------------------------------------------------------------------------

variable "backup_enabled" {
  description = "Enable automated Cloud SQL backups."
  type        = bool
  default     = true
}

variable "backup_start_time" {
  description = "Start time for automated backups in HH:MM format."
  type        = string
  default     = "03:00"

  validation {
    condition = can(
      regex(
        "^([01][0-9]|2[0-3]):[0-5][0-9]$",
        var.backup_start_time
      )
    )

    error_message = "backup_start_time must use HH:MM format, for example 03:00."
  }
}

variable "backup_location" {
  description = "Optional location where automated backups are stored."
  type        = string
  default     = null
}

variable "retained_backups" {
  description = "Number of automated backups retained."
  type        = number
  default     = 7

  validation {
    condition     = var.retained_backups > 0
    error_message = "retained_backups must be greater than zero."
  }
}


# -----------------------------------------------------------------------------
# MySQL Binary Logging
#
# The module passes this setting only for MySQL instances.
# -----------------------------------------------------------------------------

variable "binary_log_enabled" {
  description = "Enable binary logging for MySQL Cloud SQL instances."
  type        = bool
  default     = true
}


# -----------------------------------------------------------------------------
# Point-in-Time Recovery
#
# The module passes point_in_time_recovery_enabled only for PostgreSQL and
# SQL Server instances.
# -----------------------------------------------------------------------------

variable "point_in_time_recovery_enabled" {
  description = "Enable point-in-time recovery for supported database engines."
  type        = bool
  default     = true
}

variable "transaction_log_retention_days" {
  description = "Transaction-log retention period for PITR-capable instances."
  type        = number
  default     = null

  validation {
    condition = (
      var.transaction_log_retention_days == null ||
      (
        var.transaction_log_retention_days >= 1 &&
        var.transaction_log_retention_days <= 7
      )
    )

    error_message = "transaction_log_retention_days must be between 1 and 7."
  }
}


# -----------------------------------------------------------------------------
# Maintenance Window
#
# A maintenance window is generated only when both day and hour are supplied.
# -----------------------------------------------------------------------------

variable "maintenance_window_day" {
  description = "Optional maintenance-window day from 1 through 7."
  type        = number
  default     = null

  validation {
    condition = (
      var.maintenance_window_day == null ||
      (
        var.maintenance_window_day >= 1 &&
        var.maintenance_window_day <= 7
      )
    )

    error_message = "maintenance_window_day must be between 1 and 7."
  }
}

variable "maintenance_window_hour" {
  description = "Optional maintenance-window hour from 0 through 23."
  type        = number
  default     = null

  validation {
    condition = (
      var.maintenance_window_hour == null ||
      (
        var.maintenance_window_hour >= 0 &&
        var.maintenance_window_hour <= 23
      )
    )

    error_message = "maintenance_window_hour must be between 0 and 23."
  }
}

variable "maintenance_update_track" {
  description = "Cloud SQL maintenance update track."
  type        = string
  default     = "stable"

  validation {
    condition = contains(
      ["stable", "canary"],
      lower(var.maintenance_update_track)
    )

    error_message = "maintenance_update_track must be stable or canary."
  }
}


# -----------------------------------------------------------------------------
# Database Flags
#
# Valid flags depend on the selected database engine and version.
# -----------------------------------------------------------------------------

variable "database_flags" {
  description = "Database engine flags applied to the Cloud SQL instance."
  type        = map(string)
  default     = {}
}


# -----------------------------------------------------------------------------
# Customer-Managed Encryption Key
#
# The module consumes an existing Cloud KMS CryptoKey.
# -----------------------------------------------------------------------------

variable "encryption_key_name" {
  description = "Optional Cloud KMS CryptoKey resource ID used for Cloud SQL CMEK."
  type        = string
  default     = null
}


# -----------------------------------------------------------------------------
# Instance Protection
# -----------------------------------------------------------------------------

variable "deletion_protection" {
  description = "Protect the Cloud SQL instance against Terraform deletion."
  type        = bool
  default     = true
}


# -----------------------------------------------------------------------------
# Labels
# -----------------------------------------------------------------------------

variable "user_labels" {
  description = "Labels applied to the Cloud SQL instance."
  type        = map(string)

  default = {
    managed_by = "terraform"
  }
}


# -----------------------------------------------------------------------------
# Databases
#
# Creates databases inside the Cloud SQL instance.
#
# Database users and credentials remain outside this module.
# -----------------------------------------------------------------------------

variable "databases" {
  description = "Databases created inside the Cloud SQL instance."

  type = map(object({
    name            = string
    charset         = optional(string)
    collation       = optional(string)
    deletion_policy = optional(string, "DELETE")
  }))

  default = {}

  validation {
    condition = alltrue([
      for database in values(var.databases) :
      trimspace(database.name) != ""
    ])

    error_message = "Each Cloud SQL database must have a non-empty name."
  }

  validation {
    condition = alltrue([
      for database in values(var.databases) :
      contains(
        ["DELETE", "ABANDON"],
        upper(database.deletion_policy)
      )
    ])

    error_message = "Each database deletion_policy must be DELETE or ABANDON."
  }
}
