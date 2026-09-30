locals {
  service_account_email = var.create_service_account ? (
    google_service_account.this[0].email
  ) : var.existing_service_account_email

  service_account_name = var.create_service_account ? (
    google_service_account.this[0].name
  ) : "projects/${var.project_id}/serviceAccounts/${var.existing_service_account_email}"

  service_account_member = "serviceAccount:${local.service_account_email}"
}
