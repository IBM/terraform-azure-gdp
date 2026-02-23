#
# Copyright (c) IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# modules/networking/variables.tf (Private IP Version)

# Resource configuration
variable "resource_group_name" {
  type        = string
  description = "Name of the Azure Resource Group"
}

variable "location" {
  type        = string
  description = "Azure region"
}

# Network configuration
variable "vnet_name" {
  type        = string
  description = "Name of the Virtual Network"
}

variable "vnet_address_space" {
  type        = list(string)
  description = "Address space for the Virtual Network"
}

variable "subnet_name" {
  type        = string
  description = "Name of the subnet"
}

variable "subnet_address_prefixes" {
  type        = list(string)
  description = "Address prefixes for the subnet"
}

variable "nsg_name" {
  type        = string
  description = "Name of the Network Security Group"
}

# Private mode configuration
variable "private_mode" {
  type        = bool
  default     = true
  description = "Enable private mode (restricts access to management subnet)"
}

variable "allowed_management_ips" {
  type        = list(string)
  default     = []
  description = "List of allowed management IP addresses"
}

# Tagging
variable "tags" {
  type        = map(string)
  default     = {}
  description = "Tags to apply to all resources"
}
