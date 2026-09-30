# -----------------------------------------------------------------------------
# Local Values
#
# This file contains transformation logic required by the reusable Artifact
# Registry module.
#
# Resource definitions remain in main.tf.
# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------
# Repository IAM Member Transformation
#
# The module interface allows a caller to define one IAM binding containing
# multiple members:
#
# repository_iam_bindings = {
#   docker_readers = {
#     repository = "docker"
#     role       = "roles/artifactregistry.reader"
#
#     members = [
#       "serviceAccount:application1@project.iam.gserviceaccount.com",
#       "serviceAccount:application2@project.iam.gserviceaccount.com"
#     ]
#   }
# }
#
# google_artifact_registry_repository_iam_member manages one identity per
# Terraform resource instance.
#
# This local therefore converts each caller-friendly binding into individual
# repository / role / member assignments.
# -----------------------------------------------------------------------------

locals {
  repository_iam_members = merge(
    {},
    [
      for binding_key, binding in var.repository_iam_bindings : {

        for member in binding.members :

        "${binding_key}:${member}" => {
          repository = binding.repository
          role       = binding.role
          member     = member
        }
      }
    ]...
  )
}
