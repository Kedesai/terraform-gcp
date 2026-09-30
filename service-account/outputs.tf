output "email" {
  description = "Email address of the service account."
  value       = local.service_account_email
}

output "name" {
  description = "Fully qualified service account resource name."
  value       = local.service_account_name
}

output "member" {
  description = "IAM member representation of the service account."
  value       = local.service_account_member
}

output "account_id" {
  description = "Account ID of the created service account."
  value = var.create_service_account ? (
    google_service_account.this[0].account_id
  ) : null
}

output "unique_id" {
  description = "Unique ID of the created service account."
  value = var.create_service_account ? (
    google_service_account.this[0].unique_id
  ) : null
}
