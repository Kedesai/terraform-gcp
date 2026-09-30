# -----------------------------------------------------------------------------
# Google Artifact Registry
#
# Creates one or more Artifact Registry repositories from the configuration
# supplied through var.repositories.
#
# This reusable module is responsible only for Artifact Registry resources
# and repository-level IAM.
#
# Service accounts and KMS keys remain independent reusable modules and are
# passed into this module when required.
# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------
# Artifact Registry Repository
#
# Each entry in var.repositories creates one Artifact Registry repository.
#
# Example logical keys:
#
# repositories = {
#   docker = {...}
#   maven  = {...}
# }
#
# These logical map keys are Terraform identifiers. The actual repository name
# is determined by repository_id.
# -----------------------------------------------------------------------------

resource "google_artifact_registry_repository" "this" {
  for_each = var.repositories

  project = var.project_id

  # ---------------------------------------------------------------------------
  # Basic Repository Configuration
  # ---------------------------------------------------------------------------

  location      = each.value.location
  repository_id = each.value.repository_id
  format        = upper(each.value.format)

  description = each.value.description

  labels = each.value.labels


  # ---------------------------------------------------------------------------
  # Customer-Managed Encryption Key
  #
  # When kms_key_name is supplied, Artifact Registry uses the specified
  # Cloud KMS Crypto Key.
  #
  # When null, no customer-managed key is configured by this module.
  #
  # IMPORTANT:
  # Supplying the Crypto Key alone does not automatically grant the Artifact
  # Registry service identity permission to use that key. KMS IAM must be
  # configured separately.
  # ---------------------------------------------------------------------------

  kms_key_name = each.value.kms_key_name


  # ---------------------------------------------------------------------------
  # Docker Repository Configuration
  #
  # docker_config is created only when the repository format is DOCKER.
  #
  # immutable_tags prevents existing Docker tags from being moved to another
  # image digest when enabled.
  # ---------------------------------------------------------------------------

  dynamic "docker_config" {
    for_each = upper(each.value.format) == "DOCKER" ? [1] : []

    content {
      immutable_tags = each.value.immutable_tags
    }
  }
}


# -----------------------------------------------------------------------------
# Artifact Registry Repository IAM Members
#
# IAM assignments are optional.
#
# locals.tf converts caller-friendly IAM bindings containing multiple members
# into individual repository/role/member records.
#
# google_artifact_registry_repository_iam_member is intentionally used so this
# module manages only the IAM memberships requested by the caller instead of
# taking ownership of the repository's complete IAM policy.
# -----------------------------------------------------------------------------

resource "google_artifact_registry_repository_iam_member" "this" {
  for_each = local.repository_iam_members

  project = var.project_id

  # ---------------------------------------------------------------------------
  # Repository Reference
  #
  # each.value.repository contains the logical repository key from
  # var.repositories.
  #
  # We use that key to obtain the actual repository ID and location.
  # ---------------------------------------------------------------------------

  location = google_artifact_registry_repository.this[
    each.value.repository
  ].location

  repository = google_artifact_registry_repository.this[
    each.value.repository
  ].repository_id

  role   = each.value.role
  member = each.value.member
}
