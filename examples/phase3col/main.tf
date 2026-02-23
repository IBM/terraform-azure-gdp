#
# Copyright (c) IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# phase3col/main.tf (Private IP Version)
# Phase 3: Deploy Collector + Private Infrastructure

terraform {
  required_version = ">= 1.6.0"
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.110"
    }
  }
}

provider "azurerm" {
  features {}
  subscription_id = var.subscription_id
  tenant_id       = var.tenant_id
  client_id       = var.client_id
  client_secret   = var.client_secret
}

# Load Collector configuration from JSON
locals {
  json_file_path = var.col_instances_json_path != "collector_config.json" ? var.col_instances_json_path : var.col_config_json_path
  col_raw_data = jsondecode(file(local.json_file_path))
  col_config = local.col_raw_data.collectors
}

# Data sources to reference existing infrastructure
data "azurerm_resource_group" "existing" {
  name = var.resource_group_name
}

data "azurerm_virtual_network" "existing" {
  name                = var.vnet_name
  resource_group_name = data.azurerm_resource_group.existing.name
}

data "azurerm_subnet" "existing" {
  name                 = var.subnet_name
  virtual_network_name = data.azurerm_virtual_network.existing.name
  resource_group_name  = data.azurerm_resource_group.existing.name
}

# Phase 3: Deploy Collector instances using existing infrastructure (Private IP only)
module "collector" {
  source = "../../modules/collector"

  for_each = { for col in local.col_config : col.vm_name => col }

  # Use existing resource group and networking
  resource_group_name = data.azurerm_resource_group.existing.name
  location           = data.azurerm_resource_group.existing.location
  subnet_id          = data.azurerm_subnet.existing.id

  # VM configuration
  vm_name       = each.value.vm_name
  instance_type = each.value.instance_type
  
  # Network configuration
  private_ip      = each.value.network_interface_ip
  host_name       = each.value.system_hostname
  domain_name     = each.value.system_domain
  subnet_mask     = each.value.network_interface_mask
  default_gateway = each.value.network_routes_defaultroute
  resolver_1      = each.value.network_resolvers1
  resolver_2      = lookup(each.value, "network_resolvers2", null)
  
  # System configuration
  timezone = lookup(each.value, "system_clock_timezone", "America/New_York")
  
  # Authentication
  guardium_default_pw = each.value.guardium_cli_default_password
  guardium_final_pw   = each.value.guardium_final_pw

  # License Keys
  guardium_license_key = each.value.guardium_license_key
  guardium_shared_secret = each.value.guardium_shared_secret
  guardium_central_manager_ip = each.value.guardium_central_manager_ip

  # VM Image
  vm_plan  = var.vm_plan
  vm_image = var.vm_image

  # Phase 3: Private IP deployment
  phase = "3"
  
  tags = merge(var.tags, {
    phase = "3-deployment"
    component = "collector"
    instance = each.value.vm_name
    mode = "private"
  })
}
