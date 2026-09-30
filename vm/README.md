GCP Compute Engine VM Terraform Module
Reusable Terraform module for creating one or more Google Compute Engine VM instances.

The module provides VM capabilities only. Networking, service accounts, IAM, KMS keys, firewall rules, and secret delivery remain separate concerns and are supplied by callers when required.

Features
Creates one or more Compute Engine VM instances
Integrates with an existing VPC and subnet
Uses private networking by default
Supports optional external IPv4 addresses
Supports configurable machine types and zones
Supports configurable boot images
Supports configurable boot-disk size and type
Supports optional boot-disk CMEK
Supports optional custom service accounts
Supports labels and network tags
Supports instance metadata
Supports optional startup scripts
Supports standard and Spot scheduling
Supports Shielded VM controls
Supports optional Confidential Computing
Enables deletion protection by default
Allows Terraform to stop a VM for updates by default
Exposes VM identity, network, and boot-disk outputs
Module Structure
vm/
├── versions.tf
├── variables.tf
├── main.tf
├── outputs.tf
└── README.md
A locals.tf file is not currently required because the module consumes the instances map directly without additional normalization or transformation.

Architecture
VPC module
    |
    +-- subnet_self_link
                |
                v
Service Account module ---> VM module <--- KMS module
    |                          |              |
    +-- email                  |              +-- crypto_key_id
                               |
                               v
                    Compute Engine VM
The VM module consumes dependencies rather than creating them.

Repository Responsibilities
Reusable VM implementation:

Kedesai/terraform/gcp/vm
Environment-specific caller:

Kedesai/call-gcp-terraform/vm
Provider Configuration
The reusable module declares the Google provider requirement but does not configure the provider.

The caller is responsible for provider configuration:

provider "google" {
  project = var.project_id
  region  = var.region
}
Authentication must be supplied by the execution environment, such as HCP Terraform. Credentials must not be stored in the reusable module.

Basic Private VM
module "vm" {
  source = "git::https://github.com/Kedesai/terraform.git//gcp/vm"

  project_id = var.project_id

  instances = {
    application = {
      name         = "application-vm"
      zone         = "us-central1-a"
      machine_type = "e2-medium"

      boot_disk = {
        image   = "debian-cloud/debian-12"
        size_gb = 20
        type    = "pd-balanced"
      }

      network_interface = {
        subnetwork = var.subnetwork_self_link
      }
    }
  }
}
This deployment creates a VM without an external IPv4 address.

VM Protection and Update Behavior
The module defaults to:

deletion_protection       = true
allow_stopping_for_update = true
can_ip_forward            = false
Deletion protection
Deletion protection reduces the risk of accidental VM deletion.

Before intentionally destroying a protected VM, update the configuration:

deletion_protection = false
Apply that change before running the destroy operation.

Allow stopping for update
Some Compute Engine configuration changes cannot be completed while the VM is running.

The module defaults to:

allow_stopping_for_update = true
This permits Terraform to stop the instance when a requested update requires the VM to be stopped.

Set it to false only when stopping the VM during an update is unacceptable.

VM with Service Account
The service account must be created and authorized outside this module.

instances = {
  application = {
    name         = "application-vm"
    zone         = "us-central1-a"
    machine_type = "e2-medium"

    boot_disk = {
      image = "debian-cloud/debian-12"
    }

    network_interface = {
      subnetwork = var.subnetwork_self_link
    }

    service_account = {
      email = var.service_account_email

      scopes = [
        "cloud-platform"
      ]
    }
  }
}
The module defaults service-account scopes to:

[
  "cloud-platform"
]
The scope does not replace IAM authorization. Required permissions must be assigned independently to the service account using IAM roles.

VM with Boot-Disk CMEK
instances = {
  application = {
    name         = "application-vm"
    zone         = "us-central1-a"
    machine_type = "e2-medium"

    boot_disk = {
      image      = "debian-cloud/debian-12"
      size_gb    = 30
      type       = "pd-balanced"
      kms_key_id = var.kms_key_id
    }

    network_interface = {
      subnetwork = var.subnetwork_self_link
    }
  }
}
The value supplied through kms_key_id must be the fully qualified reference to the Cloud KMS Crypto Key.

Supplying a Crypto Key does not automatically grant the required Google service identity permission to use the key. KMS IAM authorization must be configured separately.

Network Configuration
The reusable module requires a subnetwork reference:

network_interface = {
  subnetwork = var.subnetwork_self_link
}
The value should normally come from the VPC module:

VPC module
    |
    +-- subnet_self_links["application"]
                |
                v
VM module
    |
    +-- network_interface.subnetwork
Static internal address
network_interface = {
  subnetwork = var.subnetwork_self_link
  network_ip = "10.10.0.10"
}
The address must be valid for the selected subnet.

External IP address
External address assignment is disabled by default:

assign_external_ip = false
Enable an ephemeral external IPv4 address explicitly:

network_interface = {
  subnetwork         = var.subnetwork_self_link
  assign_external_ip = true
  network_tier       = "PREMIUM"
}
A reserved external address may be supplied using:

network_interface = {
  subnetwork         = var.subnetwork_self_link
  assign_external_ip = true
  nat_ip             = var.external_ip_address
  network_tier       = "PREMIUM"
}
Supported network tiers exposed by the module are:

PREMIUM
STANDARD
Boot Disk Configuration
Example:

boot_disk = {
  image       = "debian-cloud/debian-12"
  size_gb     = 30
  type        = "pd-balanced"
  auto_delete = true

  labels = {
    managed_by  = "terraform"
    environment = "dev"
  }
}
Defaults:

size_gb     = 20
type        = "pd-balanced"
auto_delete = true
The module validates that size_gb is greater than zero.

Metadata
metadata = {
  enable-oslogin = "TRUE"
}
Instance metadata is available to the guest operating system.

Do not place passwords, private keys, API tokens, certificates, or other sensitive values in VM metadata.

Use Secret Manager or another approved secret-delivery process for sensitive application values.

Startup Script
startup_script = <<-EOT
  #!/usr/bin/env bash

  apt-get update
  apt-get install -y nginx

  systemctl enable nginx
  systemctl start nginx
EOT
Startup scripts should be used for bootstrap actions.

Do not embed passwords, tokens, private keys, certificates, or other sensitive values in startup scripts.

Labels and Network Tags
labels = {
  managed_by  = "terraform"
  environment = "dev"
  application = "example"
}

tags = [
  "application",
  "allow-health-check"
]
Labels provide resource metadata.

Network tags can be referenced by independently managed firewall rules.

This module does not create firewall rules.

Standard VM Scheduling
scheduling = {
  automatic_restart   = true
  on_host_maintenance = "MIGRATE"
  preemptible         = false
  provisioning_model  = "STANDARD"
}
Defaults:

automatic_restart   = true
on_host_maintenance = "MIGRATE"
preemptible         = false
provisioning_model  = "STANDARD"
Spot VM Scheduling
scheduling = {
  automatic_restart   = false
  on_host_maintenance = "TERMINATE"
  preemptible         = false
  provisioning_model  = "SPOT"
}
The module validates that Spot instances use:

automatic_restart   = false
on_host_maintenance = "TERMINATE"
Shielded VM
shielded_instance_config = {
  enable_secure_boot          = true
  enable_vtpm                 = true
  enable_integrity_monitoring = true
}
Defaults:

enable_secure_boot          = false
enable_vtpm                 = true
enable_integrity_monitoring = true
Secure Boot remains disabled by default because compatibility depends on the selected operating-system image, drivers, and guest software.

Confidential Computing
instances = {
  confidential = {
    name         = "confidential-vm"
    zone         = "us-central1-a"
    machine_type = "n2d-standard-2"

    min_cpu_platform = "AMD Milan"

    boot_disk = {
      image = "ubuntu-os-cloud/ubuntu-2204-lts"
    }

    network_interface = {
      subnetwork = var.subnetwork_self_link
    }

    scheduling = {
      automatic_restart   = false
      on_host_maintenance = "TERMINATE"
      provisioning_model  = "STANDARD"
    }

    confidential_compute = {
      enabled = true
      type    = "SEV"
    }
  }
}
The caller is responsible for choosing a compatible machine type, zone, CPU platform, image, and scheduling configuration.

Multiple VMs
The reusable module supports multiple VM definitions:

instances = {
  application_1 = {
    name         = "application-vm-1"
    zone         = "us-central1-a"
    machine_type = "e2-medium"

    boot_disk = {
      image = "debian-cloud/debian-12"
    }

    network_interface = {
      subnetwork = var.application_subnet_self_link
    }
  }

  application_2 = {
    name         = "application-vm-2"
    zone         = "us-central1-b"
    machine_type = "e2-medium"

    boot_disk = {
      image = "debian-cloud/debian-12"
    }

    network_interface = {
      subnetwork = var.application_subnet_self_link
    }
  }
}
The logical keys application_1 and application_2 are used to index module outputs.

Complete Example
module "vm" {
  source = "git::https://github.com/Kedesai/terraform.git//gcp/vm"

  project_id = var.project_id

  instances = {
    application = {
      name         = "application-vm"
      zone         = "us-central1-a"
      machine_type = "e2-medium"

      description = "Application VM managed by Terraform."

      deletion_protection       = true
      allow_stopping_for_update = true
      can_ip_forward            = false

      labels = {
        managed_by  = "terraform"
        environment = "dev"
        application = "example"
      }

      tags = [
        "application"
      ]

      boot_disk = {
        image       = "debian-cloud/debian-12"
        size_gb     = 30
        type        = "pd-balanced"
        auto_delete = true
        kms_key_id  = var.kms_key_id

        labels = {
          managed_by  = "terraform"
          environment = "dev"
        }
      }

      network_interface = {
        subnetwork         = var.subnetwork_self_link
        assign_external_ip = false
      }

      service_account = {
        email = var.service_account_email

        scopes = [
          "cloud-platform"
        ]
      }

      metadata = {
        enable-oslogin = "TRUE"
      }

      startup_script = <<-EOT
        #!/usr/bin/env bash
        apt-get update
      EOT

      scheduling = {
        automatic_restart   = true
        on_host_maintenance = "MIGRATE"
        preemptible         = false
        provisioning_model  = "STANDARD"
      }

      shielded_instance_config = {
        enable_secure_boot          = false
        enable_vtpm                 = true
        enable_integrity_monitoring = true
      }
    }
  }
}
Outputs
Instance IDs
module.vm.instance_ids
Instance names
module.vm.instance_names
Instance self-links
module.vm.instance_self_links
Instance zones
module.vm.instance_zones
Internal IP addresses
module.vm.internal_ip_addresses
External IP addresses
module.vm.external_ip_addresses
VMs without an external address return null for their map entry.

Boot disk sources
module.vm.boot_disk_sources
All outputs are maps keyed by the logical keys used in var.instances.

Safe Defaults
deletion_protection       = true
allow_stopping_for_update = true
can_ip_forward            = false

assign_external_ip = false

boot_disk = {
  size_gb     = 20
  type        = "pd-balanced"
  auto_delete = true
}

scheduling = {
  automatic_restart   = true
  on_host_maintenance = "MIGRATE"
  preemptible         = false
  provisioning_model  = "STANDARD"
}

shielded_instance_config = {
  enable_secure_boot          = false
  enable_vtpm                 = true
  enable_integrity_monitoring = true
}
Composition with Other Modules
VPC module
    |
    +-- subnet_self_links["application"]
                     |
                     v
Service Account ---> VM module <--- KMS module
    |                                  |
    +-- email                          +-- crypto_key_ids["vm"]
                     |
                     v
             Compute Engine VM
                     |
                     +-- private IP
                     +-- optional external IP
                     +-- boot disk
                     +-- optional CMEK
Example composition:

module "vm" {
  source = "git::https://github.com/Kedesai/terraform.git//gcp/vm"

  project_id = var.project_id

  instances = {
    application = {
      name         = "application-vm"
      zone         = var.zone
      machine_type = "e2-medium"

      boot_disk = {
        image      = "debian-cloud/debian-12"
        kms_key_id = module.kms.crypto_key_ids["vm"]
      }

      network_interface = {
        subnetwork = module.vpc.subnet_self_links["application"]
      }

      service_account = {
        email = module.service_account.email
      }
    }
  }
}
Validation
Before committing module changes:

terraform fmt -recursive
terraform init
terraform validate
terraform plan
Design Principles
Provider configuration belongs to the caller
Authentication remains outside the reusable module
VPC and subnet resources are not recreated by this module
Service accounts and IAM roles are not recreated by this module
KMS keys and KMS IAM are not recreated by this module
Firewall rules are not created by this module
Public IP assignment requires explicit caller action
Deletion protection is enabled by default
Terraform can stop the VM for required updates by default
Secret values must not be placed in metadata or startup scripts
Optional features remain caller-controlled
Outputs remain keyed by the logical VM identifiers