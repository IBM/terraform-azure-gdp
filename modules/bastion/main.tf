#
# Copyright (c) IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# modules/bastion/main.tf
# Bastion Host module for secure access to private Guardium instances

# Management subnet for bastion host
resource "azurerm_subnet" "management_subnet" {
  name                 = var.management_subnet_name
  resource_group_name  = var.resource_group_name
  virtual_network_name = var.vnet_name
  address_prefixes     = var.management_subnet_prefixes
}

# Network Security Group for bastion host
resource "azurerm_network_security_group" "bastion_nsg" {
  name                = "${var.bastion_name}-nsg"
  location            = var.location
  resource_group_name = var.resource_group_name

  # SSH access from specific IPs
  dynamic "security_rule" {
    for_each = var.allowed_source_ips
    content {
      name                       = "SSH-${security_rule.key}"
      priority                   = 100 + security_rule.key
      direction                  = "Inbound"
      access                     = "Allow"
      protocol                   = "Tcp"
      source_port_range          = "*"
      destination_port_range     = "22"
      source_address_prefix      = security_rule.value
      destination_address_prefix = "*"
    }
  }

  # Outbound rule for bastion to access Guardium instances
  security_rule {
    name                       = "SSH-to-guardium"
    priority                   = 200
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "22"
    source_address_prefix      = "*"
    destination_address_prefix = var.guardium_subnet_prefix
  }

  # HTTPS access to Guardium web interfaces
  security_rule {
    name                       = "HTTPS-to-guardium"
    priority                   = 210
    direction                  = "Outbound"
    access                     = "Allow"
    protocol                   = "Tcp"
    source_port_range          = "*"
    destination_port_range     = "8443"
    source_address_prefix      = "*"
    destination_address_prefix = var.guardium_subnet_prefix
  }

  tags = var.tags
}

# Associate NSG to management subnet
resource "azurerm_subnet_network_security_group_association" "bastion_nsg_association" {
  subnet_id                 = azurerm_subnet.management_subnet.id
  network_security_group_id = azurerm_network_security_group.bastion_nsg.id
}

# Public IP for bastion host
resource "azurerm_public_ip" "bastion_pip" {
  name                = "${var.bastion_name}-pip"
  location            = var.location
  resource_group_name = var.resource_group_name
  allocation_method   = "Static"
  sku                 = "Standard"
  tags                = var.tags
}

# Network interface for bastion host
resource "azurerm_network_interface" "bastion_nic" {
  name                = "${var.bastion_name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "internal"
    subnet_id                     = azurerm_subnet.management_subnet.id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.bastion_private_ip
    public_ip_address_id          = azurerm_public_ip.bastion_pip.id
  }

  tags = var.tags
}

# Bastion host virtual machine
resource "azurerm_linux_virtual_machine" "bastion" {
  name                = var.bastion_name
  location            = var.location
  resource_group_name = var.resource_group_name
  size                = var.bastion_vm_size
  admin_username      = var.admin_username
  
  disable_password_authentication = true

  network_interface_ids = [azurerm_network_interface.bastion_nic.id]

  admin_ssh_key {
    username   = var.admin_username
    public_key = var.ssh_public_key
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  source_image_reference {
  publisher = "Canonical"
  offer     = "0001-com-ubuntu-server-jammy"
  sku       = "22_04-lts-gen2"
  version   = "latest"
}

  tags = var.tags
}

# Install required tools on bastion host
resource "null_resource" "bastion_setup" {
provisioner "remote-exec" {
  inline = [
    # Update base packages
    "sudo apt-get update",
    "sudo apt-get install -y curl wget unzip jq expect",

    # Install HashiCorp repo (official method)
    "wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg",
    "echo \"deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(grep -oP '(?<=UBUNTU_CODENAME=).*' /etc/os-release || lsb_release -cs) main\" | sudo tee /etc/apt/sources.list.d/hashicorp.list",

    # Install Terraform
    "sudo apt-get update && sudo apt-get install -y terraform",

    # Install Azure CLI
    "curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash",

    # Prepare SSH directory
    "mkdir -p ~/.ssh",
    "chmod 700 ~/.ssh"
  ]

  connection {
    type        = "ssh"
    host        = azurerm_public_ip.bastion_pip.ip_address
    user        = var.admin_username
    private_key = var.ssh_private_key
  }
}

  depends_on = [azurerm_linux_virtual_machine.bastion]
}
