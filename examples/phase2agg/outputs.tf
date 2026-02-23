#
# Copyright (c) IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# phase2agg/outputs.tf (Private IP Version)
# Outputs from Phase 2 for private deployment

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

# Aggregator outputs
output "aggregator_details" {
  value = {
    for k, agg in module.aggregator : k => {
      vm_name    = agg.vm_name
      public_ip  = null  # No public IP in private mode
      private_ip = agg.private_ip
      vm_id      = agg.vm_id
    }
  }
  description = "Aggregator instance details (private IP only)"
}

output "aggregator_public_ips" {
  value       = { for k, agg in module.aggregator : k => null }
  description = "Public IP addresses (not available in private mode)"
}

output "aggregator_private_ips" {
  value       = { for k, agg in module.aggregator : k => agg.private_ip }
  description = "Private IP addresses of Aggregators"
}

# Phase completion status
output "phase2_status" {
  value = {
    phase               = "2-completed"
    timestamp          = timestamp()
    aggregators        = length(module.aggregator)
    networking_ready   = true
    next_phase         = "phase3col"
    deployment_mode    = "private"
  }
  description = "Phase 2 completion status"
}

output "next_steps" {
  value = <<-EOT
  ✅ Phase 2 Completed Successfully! (Private IP Mode)
  
  Infrastructure Used:
  - Resource Group: ${data.azurerm_resource_group.existing.name}
  - Virtual Network: ${data.azurerm_virtual_network.existing.name}
  - Aggregators: ${length(module.aggregator)} instance(s)
  
  Private IP Addresses:
  ${join("\n  ", [for k, agg in module.aggregator : "- ${k}: ${agg.private_ip}"])}
  
  Next Steps:
  1. From bastion host, access aggregators:
     ${join("\n     ", [for k, agg in module.aggregator : "ssh cli@${agg.private_ip}"])}
  
  2. Accept licenses in Guardium UI via port forwarding:
     ssh -L 8443:[private_ip]:8443 azureuser@[bastion_ip]
     Then browse to: https://localhost:8443
  
  3. Run Phase 3 (Collectors):
     cd ../phase3col
     terraform init && terraform apply
  
  4. Configure Guardium connections:
     - Aggregators connect to Central Managers
     - Setup data aggregation policies
  
  5. Monitor logs in: phase2agg/logs/
  
  🔐 All instances accessible only via bastion host
  EOT
  description = "Next steps instructions for private deployment"
}
