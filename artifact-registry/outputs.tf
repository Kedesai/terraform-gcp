# -----------------------------------------------------------------------------
# Artifact Registry Repository Outputs
#
# Outputs remain keyed by the logical repository key provided in
# var.repositories.
#
# Downstream callers therefore do not need to reconstruct Artifact Registry
# resource identifiers.
# -----------------------------------------------------------------------------

output "repository_ids" {
  description = "Map of Artifact Registry repository IDs."

  value = {
    for key, repository in google_artifact_registry_repository.this :
    key => repository.repository_id
  }
}


output "repository_names" {
  description = "Map of Artifact Registry repository resource names."

  value = {
    for key, repository in google_artifact_registry_repository.this :
    key => repository.name
  }
}


output "repository_locations" {
  description = "Map of Artifact Registry repository locations."

  value = {
    for key, repository in google_artifact_registry_repository.this :
    key => repository.location
  }
}


# -----------------------------------------------------------------------------
# Repository IAM Output
#
# Shows only the IAM memberships managed by this reusable module.
# -----------------------------------------------------------------------------

output "repository_iam_members" {
  description = "Repository-level IAM memberships managed by this module."

  value = {
    for key, assignment in google_artifact_registry_repository_iam_member.this :

    key => {
      repository = assignment.repository
      location   = assignment.location
      role       = assignment.role
      member     = assignment.member
    }
  }
}
