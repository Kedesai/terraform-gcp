resource "google_storage_bucket_iam_member" "this" {
  for_each = local.bucket_iam_members

  bucket = google_storage_bucket.this[each.value.bucket].name

  role   = each.value.role
  member = each.value.member
}
