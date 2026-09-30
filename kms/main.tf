resource "google_kms_key_ring" "this" {
  count = var.create_key_ring ? 1 : 0

  project  = var.project_id
  name     = var.key_ring_name
  location = var.location
}

data "google_kms_key_ring" "existing" {
  count = var.create_key_ring ? 0 : 1

  project  = var.project_id
  name     = var.existing_key_ring_name
  location = var.location
}

resource "google_kms_crypto_key" "this" {
  for_each = var.keys

  name     = each.value.name
  key_ring = local.key_ring_id

  purpose = each.value.purpose

  rotation_period = each.value.rotation_period

  destroy_scheduled_duration = each.value.destroy_scheduled_duration

  labels = each.value.labels

  lifecycle {
    prevent_destroy = true
  }
}

resource "google_kms_crypto_key_iam_member" "this" {
  for_each = local.key_iam_members

  crypto_key_id = google_kms_crypto_key.this[each.value.key].id

  role   = each.value.role
  member = each.value.member
}
