#
# Copyright (c) IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# phase0bastion/variables.tf
# Variables for Phase 0: Bastion Host and Base Infrastructure

# Azure Authentication
variable "client_id" {
  type        = string
  sensitive   = true
  description = "Azure Service Principal Client ID"
}

variable "client_secret" {
  type        = string
  sensitive   = true
  description = "Azure Service Principal Client Secret"
}

variable "tenant_id" {
  type        = string
  description = "Azure Tenant ID"
}

variable "subscription_id" {
  type        = string
  description = "Azure Subscription ID"
}

# Infrastructure Configuration
variable "location" {
  type        = string
  default     = "East US"
  description = "Azure region for deployment"
}

variable "resource_group_name" {
  type        = string
  default     = "IBMGuardium"
  description = "Name of the Azure Resource Group"
}

# Networking Configuration
variable "vnet_name" {
  type        = string
  default     = "guardium-vnet"
  description = "Name of the Virtual Network"
}

variable "vnet_address_space" {
  type        = list(string)
  default     = ["10.0.0.0/16"]
  description = "Address space for the Virtual Network"
}

variable "subnet_name" {
  type        = string
  default     = "guardium-subnet"
  description = "Name of the Guardium subnet"
}

variable "subnet_address_prefixes" {
  type        = list(string)
  default     = ["10.0.0.0/24"]
  description = "Address prefixes for the Guardium subnet"
}

variable "nsg_name" {
  type        = string
  default     = "guardium-nsg"
  description = "Name of the Network Security Group"
}

# Bastion Configuration
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

# Security Configuration
variable "allowed_source_ips" {
  type        = list(string)
  default     = [
    "129.41.47.3/32",
    "129.41.47.4/32"
  ]
  description = "List of allowed source IPs for SSH access to bastion"
}

# SSH Configuration
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
  default     = {
    project     = "guardium"
    environment = "production"
    managed_by  = "terraform"
    mode        = "private"
  }
  description = "Tags to apply to all resources"
}
