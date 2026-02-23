#
# Copyright (c) IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# modules/bastion/outputs.tf

output "bastion_public_ip" {
  value       = azurerm_public_ip.bastion_pip.ip_address
  description = "Public IP address of the bastion host"
}

output "bastion_private_ip" {
  value       = azurerm_linux_virtual_machine.bastion.private_ip_address
  description = "Private IP address of the bastion host"
}

output "bastion_ssh_command" {
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.bastion_pip.ip_address}"
  description = "SSH command to connect to bastion host"
}

output "management_subnet_id" {
  value       = azurerm_subnet.management_subnet.id
  description = "ID of the management subnet"
}

output "bastion_vm_id" {
  value       = azurerm_linux_virtual_machine.bastion.id
  description = "ID of the bastion virtual machine"
}

output "connection_instructions" {
  value = <<-EOT
  Bastion Host Access Instructions:
  
  1. Connect to bastion host:
     ssh ${var.admin_username}@${azurerm_public_ip.bastion_pip.ip_address}
  
  2. From bastion, access Guardium instances:
     ssh cli@10.0.0.10   # Central Manager 1
     ssh cli@10.0.0.11   # Central Manager 2
     ssh cli@10.0.0.15   # Aggregator 1
     ssh cli@10.0.0.16   # Aggregator 2
     ssh cli@10.0.0.20   # Collector 1
     ssh cli@10.0.0.21   # Collector 2
  
  3. Access Guardium Web UI via port forwarding:
     ssh -L 8443:10.0.0.10:8443 ${var.admin_username}@${azurerm_public_ip.bastion_pip.ip_address}
     Then browse to: https://localhost:8443
  
  4. Deploy remaining phases from bastion:
     cd /opt/guardium-azure
     # Run terraform commands from here
  EOT
  description = "Instructions for accessing Guardium via bastion host"
}
