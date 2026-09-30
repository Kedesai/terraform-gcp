# -----------------------------------------------------------------------------
# Firestore Database Outputs
# -----------------------------------------------------------------------------

output "database_id" {
  description = "Firestore database resource ID."
  value       = google_firestore_database.this.id
}

output "database_name" {
  description = "Firestore database name."
  value       = google_firestore_database.this.name
}

output "location_id" {
  description = "Firestore database location."
  value       = google_firestore_database.this.location_id
}

output "database_type" {
  description = "Firestore database type."
  value       = google_firestore_database.this.type
}
