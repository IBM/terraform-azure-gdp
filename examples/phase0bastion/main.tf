#
# Copyright (c) IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# phase0bastion/main.tf
# Phase 0: Deploy Bastion Host and Base Infrastructure

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

# Phase 0: Create base networking infrastructure
module "networking" {
  source = "../../modules/networking"

  resource_group_name      = var.resource_group_name
  location                = var.location
  vnet_name               = var.vnet_name
  vnet_address_space      = var.vnet_address_space
  subnet_name             = var.subnet_name
  subnet_address_prefixes = var.subnet_address_prefixes
  nsg_name                = var.nsg_name
  
  # Private mode - restrict access
  private_mode = true
  allowed_management_ips = var.allowed_source_ips
  
  tags = merge(var.tags, {
    phase = "0-infrastructure"
    component = "networking"
  })
}

# Phase 0: Deploy bastion host
module "bastion" {
  source = "../../modules/bastion"

  # Resource configuration using direct data references
  resource_group_name = var.resource_group_name
  location           = var.location
  vnet_name          = var.vnet_name
  
  # Bastion configuration
  bastion_name                 = var.bastion_name
  bastion_vm_size             = var.bastion_vm_size
  bastion_private_ip          = var.bastion_private_ip
  
  # Network configuration
  management_subnet_name       = var.management_subnet_name
  management_subnet_prefixes   = var.management_subnet_prefixes
  guardium_subnet_prefix       = var.subnet_address_prefixes[0]
  
  # Security configuration
  allowed_source_ips          = var.allowed_source_ips
  
  # SSH configuration
  admin_username              = var.admin_username
  ssh_public_key              = var.ssh_public_key
  ssh_private_key             = var.ssh_private_key
  
  tags = merge(var.tags, {
    phase = "0-bastion"
    component = "bastion"
  })

  depends_on = [module.networking]
}

resource "null_resource" "upload_terraform_configs" {

  provisioner "remote-exec" {
    inline = [
      # Prepare clean temp directory owned by Azure user
      "sudo rm -rf /tmp/guardium-azure",
      "sudo mkdir -p /tmp/guardium-azure",
      "sudo chown ${var.admin_username}:${var.admin_username} /tmp/guardium-azure",
      "chmod 755 /tmp/guardium-azure",
    ]

    connection {
      type        = "ssh"
      host        = module.bastion.bastion_public_ip
      user        = var.admin_username
      private_key = var.ssh_private_key
    }
  }

  # Upload modules
  provisioner "file" {
    source      = "../../modules"
    destination = "/tmp/guardium-azure/modules"

    connection {
      type        = "ssh"
      host        = module.bastion.bastion_public_ip
      user        = var.admin_username
      private_key = var.ssh_private_key
    }
  }

  # Upload all example phases (safe, but optional)
  provisioner "file" {
    source      = "../../examples"
    destination = "/tmp/guardium-azure/examples"

    connection {
      type        = "ssh"
      host        = module.bastion.bastion_public_ip
      user        = var.admin_username
      private_key = var.ssh_private_key
    }
  }

  provisioner "remote-exec" {
    inline = [
      "sudo rm -rf /opt/guardium-azure",
      "sudo mkdir -p /opt/guardium-azure",
      "sudo cp -r /tmp/guardium-azure/* /opt/guardium-azure/",
      "sudo chown -R ${var.admin_username}:${var.admin_username} /opt/guardium-azure",

      # Make scripts executable
      "find /opt/guardium-azure -type f -name 'run_*.sh' -exec chmod +x {} \\;",
      "find /opt/guardium-azure -type f -name '*.expect' -exec chmod +x {} \\;",

      # --- NEW: Install expect ---
      "echo 'Installing expect...'",
      "sudo apt-get update -y || sudo dnf check-update || true",
      "if command -v apt-get >/dev/null 2>&1; then sudo apt-get install -y expect; fi",
      "if command -v dnf >/dev/null 2>&1; then sudo dnf install -y expect; fi",
      "if command -v yum >/dev/null 2>&1; then sudo yum install -y expect; fi",

      "echo 'Expect version:'",
      "expect -v || echo 'Expect installation failed!'",

      "echo 'Guardium Terraform modules successfully uploaded'",
      "ls -la /opt/guardium-azure/"
    ]

    connection {
      type        = "ssh"
      host        = module.bastion.bastion_public_ip
      user        = var.admin_username
      private_key = var.ssh_private_key
    }
  }

  depends_on = [module.bastion]
}

