#
# Copyright (c) IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# modules/central_manager/outputs.tf (Private IP Version)

output "vm_id" {
  value       = azurerm_linux_virtual_machine.vm.id
  description = "ID of the virtual machine"
}

output "vm_name" {
  value       = azurerm_linux_virtual_machine.vm.name
  description = "Name of the virtual machine"
}

output "public_ip" {
  value       = null
  description = "Public IP address (not available in private mode)"
}

output "private_ip" {
  value       = var.private_ip
  description = "Private IP address"
}

output "network_interface_id" {
  value       = azurerm_network_interface.nic.id
  description = "ID of the network interface"
}

output "ssh_command" {
  value       = "ssh cli@${var.private_ip} # Access via bastion host"
  description = "SSH command to connect to the VM via private IP"
}

output "web_url" {
  value       = "https://${var.private_ip}:8443 # Access via bastion host or port forwarding"
  description = "Guardium web interface URL via private IP"
}
