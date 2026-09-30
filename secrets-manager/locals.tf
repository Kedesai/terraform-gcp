# -----------------------------------------------------------------------------
# Local Values
#
# Secret IAM assignments are supplied as bindings containing one or more
# members. The google_secret_manager_secret_iam_member resource manages one
# member per resource instance.
#
# This local flattens each binding into an individual role/member assignment.
# -----------------------------------------------------------------------------

locals {
  secret_iam_members = merge(
    {},
    [
      for binding_key, binding in var.secret_iam_bindings : {
        for member in binding.members :
        "${binding_key}:${member}" => {
          secret = binding.secret
          role   = binding.role
          member = member
        }
      }
    ]...
  )
}
