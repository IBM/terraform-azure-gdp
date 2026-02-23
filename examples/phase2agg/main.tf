#
# Copyright (c) IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# phase2agg/main.tf (Private IP Version)
# Phase 2: Deploy Aggregator + Private Infrastructure

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

# Load Aggregator configuration from JSON
locals {
  json_file_path = var.agg_instances_json_path != "aggregator_config.json" ? var.agg_instances_json_path : var.agg_config_json_path
  agg_raw_data = jsondecode(file(local.json_file_path))
  agg_config = local.agg_raw_data.aggregators
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

# Phase 2: Deploy Aggregator instances using existing infrastructure (Private IP only)
module "aggregator" {
  source = "../../modules/aggregator"

  for_each = { for agg in local.agg_config : agg.vm_name => agg }

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

  # Phase 2: Private IP deployment
  phase = "2"
  
  tags = merge(var.tags, {
    phase = "2-deployment"
    component = "aggregator"
    instance = each.value.vm_name
    mode = "private"
  })
}
