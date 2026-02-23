#
# Copyright (c) IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# phase1cm/variables.tf
# Variables for Phase 1: Central Manager Deployment

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
  description = "Name of the subnet"
}

variable "subnet_address_prefixes" {
  type        = list(string)
  default     = ["10.0.0.0/24"]
  description = "Address prefixes for the subnet"
}

variable "nsg_name" {
  type        = string
  default     = "guardium-nsg"
  description = "Name of the Network Security Group"
}

# Central Manager Configuration
variable "cm_config_json_path" {
  type        = string
  default     = "central_manager_config.json"
  description = "Path to Central Manager configuration JSON file"
}

# Legacy variable name support (from your original setup)
variable "cm_instances_json_path" {
  type        = string
  default     = "central_manager_config.json"
  description = "Path to Central Manager configuration JSON file (legacy name)"
}

variable "vm_plan" {
  type = object({
    name      = string
    publisher = string
    product   = string
  })
}

variable "vm_image" {
  type = object({
    publisher = string
    offer     = string
    sku       = string
    version   = string
  })
}


# Tagging
variable "tags" {
  type        = map(string)
  default     = {
    project     = "guardium"
    environment = "production"
    managed_by  = "terraform"
  }
  description = "Tags to apply to all resources"
}
