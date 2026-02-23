#
# Copyright (c) IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# modules/collector/outputs.tf
output "vm_id" {
  value       = azurerm_linux_virtual_machine.vm.id
  description = "ID of the virtual machine"
}

output "vm_name" {
  value       = azurerm_linux_virtual_machine.vm.name
  description = "Name of the virtual machine"
}

output "private_ip" {
  value       = azurerm_network_interface.nic.ip_configuration[0].private_ip_address
  description = "Private IP address"
}

output "network_interface_id" {
  value       = azurerm_network_interface.nic.id
  description = "ID of the network interface"
}

output "ssh_command" {
  value       = "ssh cli@${azurerm_network_interface.nic.ip_configuration[0].private_ip_address}"
  description = "SSH command to connect to the VM (from bastion host)"
}

output "web_url" {
  value       = "https://${azurerm_network_interface.nic.ip_configuration[0].private_ip_address}:8443"
  description = "Guardium web interface URL (accessible from private network)"
}
