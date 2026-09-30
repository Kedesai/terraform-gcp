resource "google_service_account" "this" {
  count = var.create_service_account ? 1 : 0

  project      = var.project_id
  account_id   = var.account_id
  display_name = var.display_name
  description  = var.description
}

resource "google_project_iam_member" "this" {
  for_each = var.project_roles

  project = var.project_id
  role    = each.value
  member  = local.service_account_member
}
