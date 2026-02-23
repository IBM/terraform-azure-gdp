#
# Copyright (c) IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# modules/bastion/variables.tf

# Resource configuration
variable "resource_group_name" {
  type        = string
  description = "Name of the Azure Resource Group"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "vnet_name" {
  type        = string
  description = "Name of the Virtual Network"
}

# Bastion configuration
variable "bastion_name" {
  type        = string
  default     = "guardium-bastion"
  description = "Name of the bastion host"
}

variable "bastion_vm_size" {
  type        = string
  default     = "Standard_B2s"
  description = "Azure VM size for bastion host"
}

variable "bastion_private_ip" {
  type        = string
  default     = "10.0.1.10"
  description = "Static private IP for bastion host"
}

# Network configuration
variable "management_subnet_name" {
  type        = string
  default     = "management-subnet"
  description = "Name of the management subnet"
}

variable "management_subnet_prefixes" {
  type        = list(string)
  default     = ["10.0.1.0/24"]
  description = "Address prefixes for the management subnet"
}

variable "guardium_subnet_prefix" {
  type        = string
  default     = "10.0.0.0/24"
  description = "Guardium subnet prefix for outbound rules"
}

# Security configuration
variable "allowed_source_ips" {
  type        = list(string)
  default     = [
    "129.41.47.3/32",
    "129.41.47.4/32",
    "170.225.223.17/32"
  ]
  description = "List of allowed source IPs for SSH access"
}

# SSH configuration
variable "admin_username" {
  type        = string
  default     = "azureuser"
  description = "Admin username for the bastion host"
}

variable "ssh_public_key" {
  type        = string
  description = "SSH public key for bastion host access"
}

variable "ssh_private_key" {
  type        = string
  sensitive   = true
  description = "SSH private key for bastion host setup"
}

# Tagging
variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to all resources"
}
