#
# Copyright (c) IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# phase0bastion/outputs.tf
# Outputs from Phase 0 for use in subsequent phases

# Infrastructure outputs
output "resource_group_name" {
  value       = var.resource_group_name
  description = "Name of the resource group"
}

output "resource_group_location" {
  value       = var.location
  description = "Location of the resource group"
}

output "vnet_id" {
  value       = module.networking.vnet_id
  description = "Virtual Network ID"
}

output "subnet_id" {
  value       = module.networking.subnet_id
  description = "Guardium subnet ID"
}

output "vnet_name" {
  value       = var.vnet_name
  description = "Virtual Network name"
}

# Bastion outputs
output "bastion_public_ip" {
  value       = module.bastion.bastion_public_ip
  description = "Public IP address of the bastion host"
}

output "bastion_private_ip" {
  value       = module.bastion.bastion_private_ip
  description = "Private IP address of the bastion host"
}

output "bastion_ssh_command" {
  value       = module.bastion.bastion_ssh_command
  description = "SSH command to connect to bastion host"
}

output "management_subnet_id" {
  value       = module.bastion.management_subnet_id
  description = "ID of the management subnet"
}

# Phase completion status
output "phase0_status" {
  value = {
    phase               = "0-completed"
    timestamp          = timestamp()
    bastion_ready      = true
    networking_ready   = true
    next_phase         = "phase1cm"
    deployment_mode    = "private"
  }
  description = "Phase 0 completion status"
}

output "next_steps" {
  value = <<-EOT
  ✅ Phase 0 Completed Successfully! (Private IP Mode)
  
  Infrastructure Created:
  - Resource Group: ${var.resource_group_name}
  - Virtual Network: ${var.vnet_name}
  - Bastion Host: ${module.bastion.bastion_public_ip}
  
  🔐 Access Instructions:
  
  1. Connect to bastion host:
     ${module.bastion.bastion_ssh_command}
  
  2. Navigate to Terraform configurations:
     cd /opt/guardium-azure
  
  3. Deploy Phase 1 (Central Managers):
     cd phase1cm
     terraform init
     terraform apply
  
  4. Continue with subsequent phases from bastion
  
  📋 Allowed Source IPs: ${join(", ", var.allowed_source_ips)}
  
  🌐 Port Forwarding for Guardium UI:
     ssh -L 8443:10.0.0.10:8443 ${var.admin_username}@${module.bastion.bastion_public_ip}
     Then browse to: https://localhost:8443
  
  EOT
  description = "Next steps instructions for private deployment"
}

output "connection_instructions" {
  value       = module.bastion.connection_instructions
  description = "Detailed connection instructions"
}
