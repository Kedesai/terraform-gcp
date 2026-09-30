# -----------------------------------------------------------------------------
# Local Values
#
# IAM binding inputs can contain multiple members, but the individual IAM
# member resources manage one identity per Terraform resource instance.
#
# These locals flatten the caller-friendly IAM structures into individual
# topic/role/member and subscription/role/member records.
# -----------------------------------------------------------------------------

locals {
  # ---------------------------------------------------------------------------
  # Topic IAM Members
  # ---------------------------------------------------------------------------

  topic_iam_members = merge(
    {},
    [
      for binding_key, binding in var.topic_iam_bindings : {
        for member in binding.members :
        "${binding_key}:${member}" => {
          topic  = binding.topic
          role   = binding.role
          member = member
        }
      }
    ]...
  )


  # ---------------------------------------------------------------------------
  # Subscription IAM Members
  # ---------------------------------------------------------------------------

  subscription_iam_members = merge(
    {},
    [
      for binding_key, binding in var.subscription_iam_bindings : {
        for member in binding.members :
        "${binding_key}:${member}" => {
          subscription = binding.subscription
          role         = binding.role
          member       = member
        }
      }
    ]...
  )
}
