#
# Copyright (c) IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# modules/networking/main.tf (Private IP Version)
# Networking module with private IP restrictions

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = var.resource_group_name
  location = var.location
  tags     = var.tags
}

# Virtual Network
resource "azurerm_virtual_network" "vnet" {
  name                = var.vnet_name
  address_space       = var.vnet_address_space
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  tags                = var.tags
}

# Guardium Subnet
resource "azurerm_subnet" "guardium_subnet" {
  name                 = var.subnet_name
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = var.subnet_address_prefixes
}

# Network Security Group for Guardium instances (Private mode)
resource "azurerm_network_security_group" "guardium_nsg" {
  name                = var.nsg_name
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  # SSH access from management subnet only
  security_rule {
    name                       = "allow-ssh-from-management"
    priority                   = 100
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = var.private_mode ? "10.0.1.0/24" : "*"
    destination_address_prefix = "*"
  }

  # Guardium Web UI - accessible from management subnet only
  security_rule {
    name                       = "allow-guardium-web-management"
    priority                   = 110
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8443"
    source_address_prefix      = var.private_mode ? "10.0.1.0/24" : "*"
    destination_address_prefix = "*"
  }

  # HTTPS - accessible from management subnet only
  security_rule {
    name                       = "allow-https-management"
    priority                   = 120
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "443"
    source_address_prefix      = var.private_mode ? "10.0.1.0/24" : "*"
    destination_address_prefix = "*"
  }

  # MySQL - internal communication within VNet
  security_rule {
    name                       = "allow-mysql"
    priority                   = 130
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "3306"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }

  # Guardium Internal communication
  security_rule {
    name                       = "allow-guardium-internal"
    priority                   = 140
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8447"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }

  # Solr communication
  security_rule {
    name                       = "allow-solr"
    priority                   = 150
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["8983", "9983"]
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }

  # S-TAP communication ports (collector/aggregator data transfer)
  security_rule {
    name                       = "allow-stap-communication"
    priority                   = 160
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_ranges    = ["16016", "16017", "16018", "16019", "16020", "16021", "16022", "16023", "16024", "16025"]
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }

  # HTTP internal services
  security_rule {
    name                       = "allow-http-internal"
    priority                   = 170
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8080"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }

  # Sniffer management port
  security_rule {
    name                       = "allow-sniffer-mgmt"
    priority                   = 180
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8444"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }

  # Alternate HTTPS port
  security_rule {
    name                       = "allow-https-alt"
    priority                   = 185
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "9443"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }

  # JMX monitoring
  security_rule {
    name                       = "allow-jmx"
    priority                   = 190
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "7199"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }

  # ICMP for health checks (ping between components)
  security_rule {
    name                       = "allow-icmp-internal"
    priority                   = 195
    direction                  = "Inbound"
    access                     = "Allow"
    protocol                   = "Icmp"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "10.0.0.0/16"
    destination_address_prefix = "*"
  }

  # Allow ALL outbound traffic
  security_rule {
    name                       = "Allow-All-Outbound"
    priority                   = 200
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "*"
    source_port_range          = "*"
    destination_port_range     = "*"
    source_address_prefix      = "*"
    destination_address_prefix = "*"
  }

  tags = var.tags
}

# Associate NSG with Guardium subnet
resource "azurerm_subnet_network_security_group_association" "guardium_nsg_association" {
  subnet_id                 = azurerm_subnet.guardium_subnet.id
  network_security_group_id = azurerm_network_security_group.guardium_nsg.id
} 
