# -----------------------------------------------------------------------------
# Frontend
# -----------------------------------------------------------------------------

output "ip_address" {
  description = "Global external IPv4 address of the load balancer."
  value       = google_compute_global_address.this.address
}

output "ip_address_id" {
  description = "Global address resource ID."
  value       = google_compute_global_address.this.id
}

output "forwarding_rule_id" {
  description = "Global HTTP forwarding-rule ID."
  value       = google_compute_global_forwarding_rule.http.id
}


# -----------------------------------------------------------------------------
# Proxy and URL Map
# -----------------------------------------------------------------------------

output "target_http_proxy_id" {
  description = "Target HTTP proxy resource ID."
  value       = google_compute_target_http_proxy.this.id
}

output "url_map_id" {
  description = "URL map resource ID."
  value       = google_compute_url_map.this.id
}


# -----------------------------------------------------------------------------
# Backend
# -----------------------------------------------------------------------------

output "backend_service_id" {
  description = "Backend service resource ID."
  value       = google_compute_backend_service.this.id
}

output "backend_service_self_link" {
  description = "Backend service self-link."
  value       = google_compute_backend_service.this.self_link
}

output "health_check_id" {
  description = "Load-balancer health-check resource ID."
  value       = google_compute_health_check.this.id
}
