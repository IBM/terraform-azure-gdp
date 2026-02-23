#
# Copyright (c) IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# phase3col/outputs.tf (Private IP Version)
# Outputs from Phase 3 for private deployment

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

# Collector outputs
output "collector_details" {
  value = {
    for k, col in module.collector : k => {
      vm_name    = col.vm_name
      public_ip  = null  # No public IP in private mode
      private_ip = col.private_ip
      vm_id      = col.vm_id
    }
  }
  description = "Collector instance details (private IP only)"
}

output "collector_public_ips" {
  value       = { for k, col in module.collector : k => null }
  description = "Public IP addresses (not available in private mode)"
}

output "collector_private_ips" {
  value       = { for k, col in module.collector : k => col.private_ip }
  description = "Private IP addresses of Collectors"
}

# Phase completion status
output "phase3_status" {
  value = {
    phase               = "3-completed"
    timestamp          = timestamp()
    collectors         = length(module.collector)
    networking_ready   = true
    deployment_complete = true
    deployment_mode    = "private"
  }
  description = "Phase 3 completion status"
}

output "next_steps" {
  value = <<-EOT
  ✅ Phase 3 Completed Successfully! (Private IP Mode)
  
  Infrastructure Used:
  - Resource Group: ${data.azurerm_resource_group.existing.name}
  - Virtual Network: ${data.azurerm_virtual_network.existing.name}
  - Collectors: ${length(module.collector)} instance(s)
  
  Private IP Addresses:
  ${join("\n  ", [for k, col in module.collector : "- ${k}: ${col.private_ip}"])}
  
  🎉 Full Guardium Private Deployment Complete!
  
  Next Steps:
  1. From bastion host, access collectors:
     ${join("\n     ", [for k, col in module.collector : "ssh cli@${col.private_ip}"])}
  
  2. Accept licenses in Guardium UI via port forwarding:
     ssh -L 8443:[private_ip]:8443 azureuser@[bastion_ip]
     Then browse to: https://localhost:8443
  
  3. Configure Guardium connections:
     - Collectors connect to Central Managers/Aggregators
     - Setup database monitoring policies
     - Configure data flows
  
  4. Access logs and monitor from bastion:
     tail -f /opt/guardium-azure/phase3col/logs/*.log
  
  🔐 All instances accessible only via bastion host
  📍 Bastion host required for all management operations
  
  EOT
  description = "Next steps instructions for private deployment completion"
}

output "access_summary" {
  value = {
    deployment_mode = "private"
    bastion_required = true
    collector_ips = { for k, col in module.collector : k => col.private_ip }
    ssh_commands = { for k, col in module.collector : k => "ssh cli@${col.private_ip}" }
    web_ui_access = "Use SSH port forwarding via bastion host"
  }
  description = "Summary of access methods for private deployment"
}
