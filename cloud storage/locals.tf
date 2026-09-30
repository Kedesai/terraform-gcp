# -----------------------------------------------------------------------------
# Local Values
#
# This file contains data transformation logic used by the Cloud Storage
# reusable module.
#
# Keeping this logic separate from main.tf makes the resource definitions
# easier to read and keeps the module responsibilities clear.
# -----------------------------------------------------------------------------


# -----------------------------------------------------------------------------
# Bucket IAM Member Transformation
#
# The public module interface allows callers to define IAM access like this:
#
# bucket_iam_bindings = {
#   application_access = {
#     bucket = "application"
#     role   = "roles/storage.objectViewer"
#
#     members = [
#       "serviceAccount:app1@project.iam.gserviceaccount.com",
#       "serviceAccount:app2@project.iam.gserviceaccount.com"
#     ]
#   }
# }
#
# The google_storage_bucket_iam_member resource manages one IAM member per
# Terraform resource instance.
#
# Therefore, the caller-friendly structure above must be flattened into
# individual bucket / role / member combinations.
#
# Result conceptually becomes:
#
# {
#   "application_access:app1..." = {
#     bucket = "application"
#     role   = "roles/storage.objectViewer"
#     member = "serviceAccount:app1@..."
#   }
#
#   "application_access:app2..." = {
#     bucket = "application"
#     role   = "roles/storage.objectViewer"
#     member = "serviceAccount:app2@..."
#   }
# }
#
# main.tf then uses this map with for_each.
# -----------------------------------------------------------------------------

locals {

  bucket_iam_members = merge(
    {},
    [
      for binding_key, binding in var.bucket_iam_bindings : {

        for member in binding.members :

        "${binding_key}:${member}" => {
          bucket = binding.bucket
          role   = binding.role
          member = member
        }
      }
    ]...
  )
}
