#
# Copyright (c) IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# phase1cm/outputs.tf (Private IP Version)
# Outputs from Phase 1 for private deployment

# Infrastructure outputs
output "resource_group_name" {
  value       = data.azurerm_resource_group.existing.name
  description = "Name of the resource group"
}

output "resource_group_location" {
  value       = data.azurerm_resource_group.existing.location
  description = "Location of the resource group"
}

output "vnet_id" {
  value       = data.azurerm_virtual_network.existing.id
  description = "Virtual Network ID"
}

output "subnet_id" {
  value       = data.azurerm_subnet.existing.id
  description = "Subnet ID"
}

# Central Manager outputs
output "central_manager_details" {
  value = {
    for k, cm in module.central_manager : k => {
      vm_name    = cm.vm_name
      public_ip  = null  # No public IP in private mode
      private_ip = cm.private_ip
      vm_id      = cm.vm_id
    }
  }
  description = "Central Manager instance details (private IP only)"
}

output "central_manager_public_ips" {
  value       = { for k, cm in module.central_manager : k => null }
  description = "Public IP addresses (not available in private mode)"
}

output "central_manager_private_ips" {
  value       = { for k, cm in module.central_manager : k => cm.private_ip }
  description = "Private IP addresses of Central Managers"
}

# Phase completion status
output "phase1_status" {
  value = {
    phase               = "1-completed"
    timestamp          = timestamp()
    central_managers   = length(module.central_manager)
    networking_ready   = true
    next_phase         = "phase2agg"
    deployment_mode    = "private"
  }
  description = "Phase 1 completion status"
}

output "next_steps" {
  value = <<-EOT
  ✅ Phase 1 Completed Successfully! (Private IP Mode)
  
  Infrastructure Used:
  - Resource Group: ${data.azurerm_resource_group.existing.name}
  - Virtual Network: ${data.azurerm_virtual_network.existing.name}
  - Central Managers: ${length(module.central_manager)} instance(s)
  
  Private IP Addresses:
  ${join("\n  ", [for k, cm in module.central_manager : "- ${k}: ${cm.private_ip}"])}
  
  Next Steps:
  1. From bastion host, access central managers:
     ${join("\n     ", [for k, cm in module.central_manager : "ssh cli@${cm.private_ip}"])}
  
  2. Accept licenses in Guardium UI via port forwarding:
     ssh -L 8443:[private_ip]:8443 azureuser@[bastion_ip]
     Then browse to: https://localhost:8443
  
  3. Run Phase 2 (Aggregators):
     cd ../phase2agg
     terraform init && terraform apply
  
  4. Monitor logs in: phase1cm/logs/
  
  🔐 All instances accessible only via bastion host
  EOT
  description = "Next steps instructions for private deployment"
}
