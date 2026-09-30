GCP External HTTP Load Balancer Terraform Module
Reusable Terraform module for creating a global external HTTP Application Load Balancer with an existing Managed Instance Group backend.

Architecture
Internet
   |
   v
Global Static IP
   |
   v
Forwarding Rule :80
   |
   v
Target HTTP Proxy
   |
   v
URL Map
   |
   v
Backend Service
   |
   +-- HTTP Health Check
   |
   v
Managed Instance Group
Module Boundary
The module creates:

Global static IP
HTTP health check
Backend service
URL map
Target HTTP proxy
Global HTTP forwarding rule
The module does not create:

VPC networks
Subnets
Instance templates
Managed Instance Groups
VM firewall rules
DNS records
TLS certificates
Basic Usage
module "load_balancer" {
  source = "git::https://github.com/Kedesai/terraform.git//gcp/load-balancer"

  project_id = var.project_id
  name       = "application"

  backend_instance_group = var.instance_group

  port_name         = "http"
  health_check_port = 8080

  health_check_request_path = "/"
}
MIG Requirement
The backend Managed Instance Group should expose a named port matching:

port_name = "http"
For example:

named_ports = {
  http = 8080
}
Autoscaling
Autoscaling remains the responsibility of the MIG module.

HTTPS
The initial module provides HTTP only.

TLS certificates and HTTPS frontend support can be added as a future extension.

Outputs
ip_address
ip_address_id
forwarding_rule_id
target_http_proxy_id
url_map_id
backend_service_id
backend_service_self_link
health_check_id
Validation
terraform fmt -recursive
terraform init
terraform validate
terraform plan