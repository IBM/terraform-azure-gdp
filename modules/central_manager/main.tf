#
# Copyright (c) IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#

# modules/central_manager/main.tf
# Central Manager module - private IP only

locals {
  mask_lookup = {
    "/27" = "255.255.255.224"
    "/25" = "255.255.255.128"
    "/24" = "255.255.255.0"
    "/23" = "255.255.254.0"
    "/20" = "255.255.240.0"
    "/16" = "255.255.0.0"
  }

  dotted_mask = lookup(local.mask_lookup, var.subnet_mask, var.subnet_mask)
}

# ----------------------------
# Network Interface (Private)
# ----------------------------
resource "azurerm_network_interface" "nic" {
  name                = "${var.vm_name}-nic"
  location            = var.location
  resource_group_name = var.resource_group_name

  ip_configuration {
    name                          = "ipcfg1"
    subnet_id                     = var.subnet_id
    private_ip_address_allocation = "Static"
    private_ip_address            = var.private_ip
  }

  tags = var.tags
}

# ----------------------------
# Virtual Machine
# ----------------------------
resource "azurerm_linux_virtual_machine" "vm" {
  name                            = var.vm_name
  location                        = var.location
  resource_group_name             = var.resource_group_name
  size                            = var.instance_type
  admin_username                  = "azureuser"
  disable_password_authentication = false
  admin_password                  = "TempP@ss-Use-CLI"
  network_interface_ids           = [azurerm_network_interface.nic.id]

  plan {
    name      = var.vm_plan.name
    publisher = var.vm_plan.publisher
    product   = var.vm_plan.product
  }

  source_image_reference {
    publisher = var.vm_image.publisher
    offer     = var.vm_image.offer
    sku       = var.vm_image.sku
    version   = var.vm_image.version
  }

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Premium_LRS"
  }

  boot_diagnostics {}
  tags = var.tags
}

# -------------------------------------------------------------------
# Boot wait - Guardium needs ~20 mins to initialize before SSH works
# -------------------------------------------------------------------
resource "time_sleep" "guardium_boot_wait" {
  create_duration = "1200s" # 20 minutes
  depends_on      = [azurerm_linux_virtual_machine.vm]
}

# -------------------------------------------------------------------
# Automated Guardium CLI configuration via Expect
# -------------------------------------------------------------------
resource "null_resource" "wait_for_ssh" {

  provisioner "local-exec" {
    interpreter = ["/usr/bin/env", "bash", "-c"]

    command = <<EOT
set -euo pipefail

PRIVATE_IP='${var.private_ip}'
VM_NAME='${var.vm_name}'
MODULE_PATH='${path.module}'

echo ""
echo "=========================================="
echo "PHASE 1: $VM_NAME DEPLOYMENT (PRIVATE)"
echo "Private IP: $PRIVATE_IP"
echo "=========================================="
echo "[$(date '+%H:%M:%S')] VM deployed successfully"
echo "[$(date '+%H:%M:%S')] Waiting for Guardium to be ready..."

# --- Extra wait after VM create ---
sleep 300

# -------------------------------
# SSH READINESS CHECK
# -------------------------------
echo "[$(date '+%H:%M:%S')] Testing SSH port 22 on $PRIVATE_IP..."
for i in $(seq 1 30); do
  if timeout 5 bash -c "echo > /dev/tcp/$PRIVATE_IP/22" 2>/dev/null; then
    echo "[$(date '+%H:%M:%S')] TCP port 22 is open on $PRIVATE_IP"
    break
  fi
  echo "Attempt $i: SSH port not ready yet, waiting..."
  sleep 30
done

# -------------------------------
# START EXPECT AUTOMATION
# -------------------------------
echo "[$(date '+%H:%M:%S')] Starting Guardium configuration for $PRIVATE_IP..."
cd "$MODULE_PATH"
chmod +x run_wait_for_guardium.sh wait_for_guardium.expect

./run_wait_for_guardium.sh \
  '${var.private_ip}' \
  '${var.guardium_final_pw}' \
  '${var.subnet_mask}' \
  '${var.default_gateway}' \
  '${var.resolver_1}' \
  '${var.resolver_2 != null ? var.resolver_2 : ""}' \
  '${var.host_name}' \
  '${var.domain_name}' \
  '${var.timezone}' \
  '${var.guardium_license_key}' \
  '${var.guardium_shared_secret}' \
  '${var.guardium_central_manager_ip}' \
  || echo "Configuration completed with warnings"

echo "[$(date '+%H:%M:%S')] Guardium configuration completed for $VM_NAME"
echo "=========================================="
EOT
  }

  triggers = {
    private_ip = var.private_ip
    vm_name    = var.vm_name
    phase      = var.phase
    fingerprint = sha256(jsonencode({
      subnet_mask     = var.subnet_mask
      default_gateway = var.default_gateway
      resolver_1      = var.resolver_1
      resolver_2      = var.resolver_2
      host_name       = var.host_name
      domain_name     = var.domain_name
      timezone        = var.timezone
      license_key     = var.guardium_license_key
      shared_secret   = var.guardium_shared_secret
      cm_ip           = var.guardium_central_manager_ip
      final_pw        = var.guardium_final_pw
    }))
  }

  depends_on = [time_sleep.guardium_boot_wait]
}

