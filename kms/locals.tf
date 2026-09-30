locals {
  key_ring_id = var.create_key_ring ? (
    google_kms_key_ring.this[0].id
  ) : data.google_kms_key_ring.existing[0].id

  key_ring_name = var.create_key_ring ? (
    google_kms_key_ring.this[0].name
  ) : data.google_kms_key_ring.existing[0].name

  key_iam_members = merge([
    for binding_key, binding in var.key_iam_members : {
      for member in binding.members :
      "${binding_key}:${member}" => {
        key    = binding.key
        role   = binding.role
        member = member
      }
    }
  ]...)
}
