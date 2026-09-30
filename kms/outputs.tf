output "key_ring_id" {
  description = "ID of the KMS Key Ring."
  value       = local.key_ring_id
}

output "key_ring_name" {
  description = "Name of the KMS Key Ring."
  value       = local.key_ring_name
}

output "crypto_key_ids" {
  description = "Map of Crypto Key IDs keyed by caller-defined key."

  value = {
    for key, crypto_key in google_kms_crypto_key.this :
    key => crypto_key.id
  }
}

output "crypto_key_names" {
  description = "Map of Crypto Key names keyed by caller-defined key."

  value = {
    for key, crypto_key in google_kms_crypto_key.this :
    key => crypto_key.name
  }
}
