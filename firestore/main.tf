# -----------------------------------------------------------------------------
# Google Cloud Firestore Database
#
# This reusable module creates and manages a Firestore database.
#
# It intentionally does not create:
#
# - GCP projects
# - Service accounts
# - Project IAM
# - Application IAM
# - Firestore documents
# - Firestore indexes
#
# Those capabilities remain separate concerns.
# -----------------------------------------------------------------------------

resource "google_firestore_database" "this" {
  project = var.project_id

  # ---------------------------------------------------------------------------
  # Database Identity
  # ---------------------------------------------------------------------------

  name        = var.database_name
  location_id = var.location_id

  type = upper(var.database_type)


  # ---------------------------------------------------------------------------
  # Database Behavior
  # ---------------------------------------------------------------------------

  concurrency_mode = upper(
    var.concurrency_mode
  )

  app_engine_integration_mode = upper(
    var.app_engine_integration_mode
  )


  # ---------------------------------------------------------------------------
  # Point-in-Time Recovery
  # ---------------------------------------------------------------------------

  point_in_time_recovery_enablement = (
    var.enable_point_in_time_recovery
    ? "POINT_IN_TIME_RECOVERY_ENABLED"
    : "POINT_IN_TIME_RECOVERY_DISABLED"
  )


  # ---------------------------------------------------------------------------
  # Delete Protection
  # ---------------------------------------------------------------------------

  delete_protection_state = (
    var.delete_protection
    ? "DELETE_PROTECTION_ENABLED"
    : "DELETE_PROTECTION_DISABLED"
  )


  # ---------------------------------------------------------------------------
  # Terraform Deletion Behavior
  # ---------------------------------------------------------------------------

  deletion_policy = upper(
    var.deletion_policy
  )


  # ---------------------------------------------------------------------------
  # Resource Manager Tags
  # ---------------------------------------------------------------------------

  tags = var.tags
}
