#
# Copyright (c) IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# modules/central_manager/variables.tf

# Resource configuration
variable "resource_group_name" {
  type        = string
  description = "Name of the Azure Resource Group"
}

variable "location" {
  type        = string
  description = "Azure region"
}

variable "subnet_id" {
  type        = string
  description = "ID of the subnet for the VM"
}

# VM configuration
variable "vm_name" {
  type        = string
  description = "Name of the virtual machine"
}

variable "instance_type" {
  type        = string
  description = "Azure VM size"
  default     = "Standard_D8s_v3"
}

# Network configuration
variable "private_ip" {
  type        = string
  description = "Static private IP address"
}

variable "host_name" {
  type        = string
  description = "System hostname"
}

variable "domain_name" {
  type        = string
  description = "System domain name"
}

variable "subnet_mask" {
  type        = string
  description = "Subnet mask (CIDR or dotted decimal)"
}

variable "default_gateway" {
  type        = string
  description = "Default gateway IP address"
}

variable "resolver_1" {
  type        = string
  description = "Primary DNS resolver"
}

variable "resolver_2" {
  type        = string
  default     = null
  description = "Secondary DNS resolver (optional)"
}

variable "timezone" {
  type        = string
  default     = "America/New_York"
  description = "System timezone"
}

# Authentication
variable "guardium_default_pw" {
  type        = string
#  sensitive   = true
  description = "Initial Guardium CLI password"
}

variable "guardium_final_pw" {
  type        = string
#  sensitive   = true
  description = "Final password after configuration"
}


variable "guardium_shared_secret" {
  type        = string
#  sensitive   = true
  description = "Guardium Shared Secret Password"
}

variable "guardium_license_key" {
  type        = string
#  sensitive   = true
  description = "Guardium License Key"
}

variable "guardium_central_manager_ip" {
  type        = string
#  sensitive   = true
  description = "Guardium Central Manager IP"
}


# Phase control
variable "phase" {
  type        = string
  default     = "1"
  description = "Deployment phase: '1' = VM only, '1-with-basic-config' = VM + basic config"
  
  validation {
    condition     = contains(["1", "1-with-basic-config"], var.phase)
    error_message = "Phase must be '1' or '1-with-basic-config'."
  }
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
  default     = {}
  description = "Tags to apply to all resources"
}
