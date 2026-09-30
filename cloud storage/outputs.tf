# -----------------------------------------------------------------------------
# Secret Resource Outputs
#
# Outputs are keyed by the caller-defined logical keys from var.secrets.
#
# Downstream modules can consume these values without reconstructing Secret
# Manager resource paths.
# -----------------------------------------------------------------------------

output "secret_ids" {
  description = "Map of Secret Manager secret IDs keyed by logical secret key."

  value = {
    for key, secret in google_secret_manager_secret.this :
    key => secret.secret_id
  }
}

output "secret_names" {
  description = "Map of fully qualified secret resource names."

  value = {
    for key, secret in google_secret_manager_secret.this :
    key => secret.name
  }
}

# -----------------------------------------------------------------------------
# Replication Outputs
#
# Exposes replication metadata returned by the Google provider.
# No secret values or secret-version payloads are exposed.
# -----------------------------------------------------------------------------

output "secret_replication" {
  description = "Replication configuration for each Secret Manager secret."

  value = {
    for key, secret in google_secret_manager_secret.this :
    key => secret.replication
  }
}

# -----------------------------------------------------------------------------
# IAM Assignment Output
#
# Provides a summary of the individual secret-level IAM grants managed by this
# module. The output does not expose secret payloads.
# -----------------------------------------------------------------------------

output "secret_iam_members" {
  description = "Secret-level IAM memberships managed by this module."

  value = {
    for key, assignment in google_secret_manager_secret_iam_member.this :
    key => {
      secret_id = assignment.secret_id
      role      = assignment.role
      member    = assignment.member
    }
  }
}
