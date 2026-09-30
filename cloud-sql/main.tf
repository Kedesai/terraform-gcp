# -----------------------------------------------------------------------------
# Google Cloud SQL
#
# This reusable module manages:
#
# - One Cloud SQL instance
# - Private or public connectivity
# - Storage and automatic storage growth
# - Automated backups
# - MySQL binary logging
# - PostgreSQL and SQL Server point-in-time recovery
# - Backup retention
# - Maintenance configuration
# - Database flags
# - Optional CMEK
# - Instance deletion protection
# - One or more databases
#
# The module intentionally does not create networking, Private Service Access,
# KMS keys, IAM, database users, passwords, or Secret Manager secrets.
# -----------------------------------------------------------------------------

resource "google_sql_database_instance" "this" {
  project = var.project_id

  name             = var.instance_name
  region           = var.region
  database_version = upper(var.database_version)

  # ---------------------------------------------------------------------------
  # Protection and Encryption
  # ---------------------------------------------------------------------------

  deletion_protection = var.deletion_protection
  encryption_key_name = var.encryption_key_name

  # ---------------------------------------------------------------------------
  # Cloud SQL Settings
  # ---------------------------------------------------------------------------

  settings {
    tier = var.tier

    availability_type = upper(
      var.availability_type
    )

    edition = (
      var.edition == null
      ? null
      : upper(var.edition)
    )

    user_labels = var.user_labels

    # -------------------------------------------------------------------------
    # Storage
    # -------------------------------------------------------------------------

    disk_type = upper(
      var.disk_type
    )

    disk_size = var.disk_size_gb

    disk_autoresize = (
      var.disk_autoresize
    )

    disk_autoresize_limit = (
      var.disk_autoresize_limit
    )

    # -------------------------------------------------------------------------
    # Network Configuration
    #
    # Private Service Access and Service Networking must already exist before
    # creating a private-IP instance.
    # -------------------------------------------------------------------------

    ip_configuration {
      ipv4_enabled = var.ipv4_enabled

      private_network = (
        var.private_network
      )

      allocated_ip_range = (
        var.allocated_ip_range
      )

      enable_private_path_for_google_cloud_services = (
        var.enable_private_path_for_google_cloud_services
      )

      ssl_mode = (
        var.ssl_mode == null
        ? null
        : upper(var.ssl_mode)
      )

      # -----------------------------------------------------------------------
      # Optional Public Authorized Networks
      # -----------------------------------------------------------------------

      dynamic "authorized_networks" {
        for_each = var.authorized_networks

        content {
          name            = authorized_networks.value.name
          value           = authorized_networks.value.value
          expiration_time = authorized_networks.value.expiration_time
        }
      }
    }

    # -------------------------------------------------------------------------
    # Automated Backup Configuration
    #
    # This block is generated only when automated backups are enabled.
    # -------------------------------------------------------------------------

    dynamic "backup_configuration" {
      for_each = var.backup_enabled ? [1] : []

      content {
        enabled    = true
        start_time = var.backup_start_time
        location   = var.backup_location

        # ---------------------------------------------------------------------
        # MySQL Binary Logging
        # ---------------------------------------------------------------------

        binary_log_enabled = (
          local.is_mysql
          ? var.binary_log_enabled
          : null
        )

        # ---------------------------------------------------------------------
        # PostgreSQL and SQL Server Point-in-Time Recovery
        # ---------------------------------------------------------------------

        point_in_time_recovery_enabled = (
          local.is_postgres || local.is_sqlserver
          ? var.point_in_time_recovery_enabled
          : null
        )

        # ---------------------------------------------------------------------
        # PostgreSQL and SQL Server Transaction-Log Retention
        # ---------------------------------------------------------------------

        transaction_log_retention_days = (
          local.is_postgres || local.is_sqlserver
          ? var.transaction_log_retention_days
          : null
        )

        # ---------------------------------------------------------------------
        # Automated Backup Retention
        # ---------------------------------------------------------------------

        backup_retention_settings {
          retained_backups = var.retained_backups
          retention_unit   = "COUNT"
        }
      }
    }

    # -------------------------------------------------------------------------
    # Maintenance Window
    #
    # The block is generated only when both day and hour are supplied.
    # -------------------------------------------------------------------------

    dynamic "maintenance_window" {
      for_each = (
        var.maintenance_window_day != null &&
        var.maintenance_window_hour != null
      ) ? [1] : []

      content {
        day  = var.maintenance_window_day
        hour = var.maintenance_window_hour

        update_track = lower(
          var.maintenance_update_track
        )
      }
    }

    # -------------------------------------------------------------------------
    # Database Flags
    # -------------------------------------------------------------------------

    dynamic "database_flags" {
      for_each = var.database_flags

      content {
        name  = database_flags.key
        value = database_flags.value
      }
    }
  }

  # ---------------------------------------------------------------------------
  # Disk Autoresize Lifecycle
  #
  # Cloud SQL can increase disk size outside the configured initial value.
  #
  # Ignoring the observed disk-size change prevents Terraform from repeatedly
  # planning against the original initial disk size.
  # ---------------------------------------------------------------------------

  lifecycle {
    ignore_changes = [
      settings[0].disk_size
    ]
  }
}


# -----------------------------------------------------------------------------
# Cloud SQL Databases
#
# Databases are managed separately from the instance lifecycle.
# -----------------------------------------------------------------------------

resource "google_sql_database" "this" {
  for_each = var.databases

  project = var.project_id

  name = each.value.name

  instance = (
    google_sql_database_instance.this.name
  )

  charset = (
    each.value.charset
  )

  collation = (
    each.value.collation
  )

  deletion_policy = upper(
    each.value.deletion_policy
  )
}
