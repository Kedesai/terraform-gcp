# -----------------------------------------------------------------------------
# Secret Manager Secrets
#
# Creates the secret containers and replication configuration.
#
# This resource does not create secret versions or store secret payloads.
# Secret values should be written through an approved secret-delivery workflow
# rather than supplied as ordinary Terraform variables.
# -----------------------------------------------------------------------------

resource "google_secret_manager_secret" "this" {
  for_each = var.secrets

  project   = var.project_id
  secret_id = each.value.secret_id
  labels    = each.value.labels

  # ---------------------------------------------------------------------------
  # Replication Configuration
  #
  # Exactly one replication strategy is selected for each secret:
  #
  # 1. Automatic replication
  #    Google manages the secret replica placement.
  #
  # 2. User-managed replication
  #    The caller explicitly specifies one or more replica locations.
  # ---------------------------------------------------------------------------

  replication {
    # -------------------------------------------------------------------------
    # Automatic Replication
    #
    # This block is generated only when replication_type is AUTOMATIC.
    # A caller may optionally provide a Cloud KMS Crypto Key for CMEK.
    # -------------------------------------------------------------------------

    dynamic "auto" {
      for_each = upper(each.value.replication_type) == "AUTOMATIC" ? [1] : []

      content {
        dynamic "customer_managed_encryption" {
          for_each = each.value.automatic_kms_key_name == null ? [] : [1]

          content {
            kms_key_name = each.value.automatic_kms_key_name
          }
        }
      }
    }

    # -------------------------------------------------------------------------
    # User-Managed Replication
    #
    # This block is generated only when replication_type is USER_MANAGED.
    # Each replica has an explicit location and can optionally use its own
    # location-compatible Cloud KMS Crypto Key.
    # -------------------------------------------------------------------------

    dynamic "user_managed" {
      for_each = upper(each.value.replication_type) == "USER_MANAGED" ? [1] : []

      content {
        dynamic "replicas" {
          for_each = each.value.user_managed_replicas

          content {
            location = replicas.value.location

            dynamic "customer_managed_encryption" {
              for_each = replicas.value.kms_key_name == null ? [] : [1]

              content {
                kms_key_name = replicas.value.kms_key_name
              }
            }
          }
        }
      }
    }
  }
}

# -----------------------------------------------------------------------------
# Secret-Level IAM Members
#
# Grants individual IAM members access to specific secrets.
#
# google_secret_manager_secret_iam_member is intentionally used instead of an
# authoritative IAM policy resource. This allows the module to add requested
# access without taking ownership of the secret's complete IAM policy.
# -----------------------------------------------------------------------------

resource "google_secret_manager_secret_iam_member" "this" {
  for_each = local.secret_iam_members

  project   = var.project_id
  secret_id = google_secret_manager_secret.this[each.value.secret].secret_id

  role   = each.value.role
  member = each.value.member
}
