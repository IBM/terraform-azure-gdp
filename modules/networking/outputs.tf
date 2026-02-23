#
# Copyright (c) IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# modules/networking/outputs.tf

output "resource_group_name" {
  value       = azurerm_resource_group.rg.name
  description = "Name of the created resource group"
}

output "resource_group_location" {
  value       = azurerm_resource_group.rg.location
  description = "Location of the resource group"
}

output "vnet_id" {
  value       = azurerm_virtual_network.vnet.id
  description = "ID of the Virtual Network"
}

output "vnet_name" {
  value       = azurerm_virtual_network.vnet.name
  description = "Name of the Virtual Network"
}

output "subnet_id" {
  value       = azurerm_subnet.guardium_subnet.id
  description = "ID of the Guardium subnet"
}

output "subnet_name" {
  value       = azurerm_subnet.guardium_subnet.name
  description = "Name of the Guardium subnet"
}

output "nsg_id" {
  value       = azurerm_network_security_group.guardium_nsg.id
  description = "ID of the Network Security Group"
}

output "nsg_name" {
  value       = azurerm_network_security_group.guardium_nsg.name
  description = "Name of the Network Security Group"
}
