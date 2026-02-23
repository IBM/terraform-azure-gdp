<p align="center">
  <img src="https://img.shields.io/badge/Terraform-%3E%3D1.6.0-623CE4?style=for-the-badge&logo=terraform" alt="Terraform">
  <img src="https://img.shields.io/badge/Azure-Cloud-0078D4?style=for-the-badge&logo=microsoft-azure" alt="Azure">
  <img src="https://img.shields.io/badge/IBM-Guardium%20V12.1.0-054ADA?style=for-the-badge&logo=ibm" alt="IBM Guardium">
  <img src="https://img.shields.io/badge/License-Apache%202.0-green?style=for-the-badge" alt="License">
</p>

# 🛡️ IBM Guardium Data Protection V12.1.0 - Azure Private Cloud Deployment

A production-ready Terraform solution for deploying **IBM Guardium Data Protection V12.1.0** on Microsoft Azure with enterprise-grade security using private networking and bastion host access.

## 📋 Table of Contents

- [Overview](#overview)
- [Architecture](#architecture)
- [Features](#features)
- [Prerequisites](#prerequisites)
- [Quick Start](#quick-start)
- [Deployment Guide](#deployment-guide)
  - [Phase 0: Infrastructure & Bastion](#phase-0-infrastructure--bastion)
  - [Phase 1: Central Manager](#phase-1-central-manager)
  - [Phase 2: Aggregators](#phase-2-aggregators)
  - [Phase 3: Collectors](#phase-3-collectors)
- [Configuration Reference](#configuration-reference)
- [Network Architecture](#network-architecture)
- [Security](#security)
- [Accessing Guardium](#accessing-guardium)
- [Troubleshooting](#troubleshooting)
- [Cleanup](#cleanup)
- [Contributing](#contributing)
- [License](#license)

---

## Overview

This project provides a comprehensive Infrastructure-as-Code (IaC) solution for deploying IBM Guardium Data Protection V12.1.0 on Azure. The deployment follows a **phased approach** with all Guardium components deployed in a private network with no public IP addresses, accessible only through a secure bastion host.

### What is IBM Guardium?

IBM Guardium Data Protection is an enterprise database activity monitoring (DAM) solution that provides:
- Real-time database activity monitoring
- Data security and compliance
- Automated audit reporting
- Vulnerability assessment
- Data discovery and classification

---

## Architecture

```
┌────────────────────────────────────────────────────────────────────────────────┐
│                              Azure Virtual Network (10.0.0.0/16)               │
│                                                                                │
│  ┌─────────────────────────────┐   ┌──────────────────────────────────────────-│
│  │   Management Subnet         │   │         Guardium Subnet                   │
│  │   10.0.1.0/24               │   │         10.0.0.0/24                       │
│  │                             │   │                                           │
│  │  ┌────────────────────┐     │   │  ┌─────────────┐  ┌─────────────┐        ││
│  │  │   Bastion Host     │     │   │  │Central Mgr 1│  │Central Mgr 2│        ││
│  │  │   10.0.1.10        │◄────┼───┼─►│  10.0.0.10  │  │  10.0.0.11  │        ││
│  │  │   (Public IP)      │     │   │  └─────────────┘  └─────────────┘        ││
│  │  └────────────────────┘     │   │                                          ││
│  │          ▲                  │   │  ┌─────────────┐  ┌─────────────┐        ││
│  │          │                  │   │  │ Aggregator 1│  │ Aggregator 2│        ││
│  └──────────┼──────────────────┘   │  │  10.0.0.15  │  │  10.0.0.16  │        ││
│             │                      │  └─────────────┘  └─────────────┘        ││
│             │                      │                                          ││
│             │                      │  ┌─────────────┐  ┌─────────────┐        ││
│             │                      │  │ Collector 1 │  │ Collector 2 │        ││
│             │                      │  │  10.0.0.20  │  │  10.0.0.21  │        ││
│             │                      │  └─────────────┘  └─────────────┘        ││
│             │                      │                                          ││
│             │                      └──────────────────────────────────────────┘│
└─────────────┼──────────────────────────────────────────────────────────────────┘
              │
              │ SSH (Port 22)
              │ Restricted IPs
              ▼
        ┌───────────┐
        │ Admin     │
        │Workstation│
        └───────────┘
```

### Deployment Phases

| Phase | Component | Description |
|-------|-----------|-------------|
| **Phase 0** | Infrastructure & Bastion | Creates VNet, subnets, NSGs, and secure bastion host |
| **Phase 1** | Central Manager(s) | Deploys Guardium Central Manager instances |
| **Phase 1.5** | CM Post-Config ⭐ | Accept GUI license + run Phase 2 script |
| **Phase 2** | Aggregator(s) | Deploys Guardium Aggregator instances |
| **Phase 3** | Collector(s) | Deploys Guardium Collector instances |

> ⭐ **Note:** Phase 1.5 is a manual step required after Central Manager deployment - you must accept the license in the GUI and run the `run_guardium_phase2.sh` script before proceeding to deploy Aggregators.

---

## Features

- ✅ **Private Networking** - All Guardium components use private IPs only
- ✅ **Secure Access** - Single bastion host with restricted IP access
- ✅ **Automated Configuration** - Expect scripts automate Guardium CLI setup
- ✅ **Phased Deployment** - Modular approach for controlled rollouts
- ✅ **JSON Configuration** - Easy multi-instance deployments via JSON files
- ✅ **High Availability** - Support for multiple CM, Aggregator, and Collector instances
- ✅ **Azure Best Practices** - NSGs, Premium storage, boot diagnostics
- ✅ **Infrastructure as Code** - Fully reproducible deployments

---

## Prerequisites

### Azure Requirements

| Requirement | Description |
|-------------|-------------|
| **Azure Subscription** | Active subscription with appropriate quotas |
| **Service Principal** | With Contributor role on the subscription |
| **Azure CLI** | Version 2.0+ installed and configured |
| **Marketplace Access** | Accept IBM Guardium marketplace terms |

### Software Requirements

| Software | Version | Purpose |
|----------|---------|---------|
| **Terraform** | ≥ 1.6.0 | Infrastructure provisioning |
| **SSH Client** | Any | Bastion access |
| **jq** | Any | JSON processing |
| **expect** | Any | Automated CLI interactions |

### IBM Guardium Requirements

- Valid IBM Guardium V12.1.0 license keys
- Guardium shared secret for component registration
- Access to IBM Guardium Azure marketplace image

### Accept Azure Marketplace Terms

Before deploying, accept the IBM Guardium marketplace terms:

```bash
az vm image terms accept \
  --publisher ibm-usa-ny-armonk-hq-6275750-ibmcloud-asperia \
  --offer ibm-guardium-data-protection \
  --plan ibm-guardium-data-protection
```

---

## Quick Start

### 1️⃣ Clone the Repository

```bash
git clone https://github.com/ibm/terraform-azure-guardium.git
cd terraform-azure-guardium
```

### 2️⃣ Configure Azure Credentials

Create `examples/phase0bastion/terraform.tfvars`:

```hcl
subscription_id = "your-subscription-id"
tenant_id       = "your-tenant-id"
client_id       = "your-client-id"
client_secret   = "your-client-secret"

# SSH Configuration
admin_username = "azureuser"
# SSH Public Key - REPLACE with your actual public key
#ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC... your-public-key-here"
# SSH Private Key - REPLACE with your actual private key
# NOTE: For production, use Azure Key Vault or other secure storage
#ssh_private_key = <<-EOT
-----BEGIN OPENSSH PRIVATE KEY-----
#your-private-key-content-here
-----END OPENSSH PRIVATE KEY-----
EOT


# SSH Public Key - REPLACE with your actual public key
###ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQC... your-public-key-here"

# SSH Private Key - REPLACE with your actual private key
# NOTE: For production, use Azure Key Vault or other secure storage
###ssh_private_key = <<-EOT
-----BEGIN OPENSSH PRIVATE KEY-----
#your-private-key-content-here
###-----END OPENSSH PRIVATE KEY-----
EOT
```

### 3️⃣ Deploy Phase 0 (Bastion)

```bash
cd examples/phase0bastion
terraform init
terraform plan
terraform apply
```

### 4️⃣ Continue from Bastion Host

```bash
# SSH to bastion
ssh azureuser@<bastion-public-ip>

# Navigate to deployment directory
cd /opt/guardium-azure/examples

# Deploy Central Manager
cd phase1cm && terraform init && terraform apply

# ⚠️ IMPORTANT: After Phase 1 completes:
# 1. Accept license in GUI (https://<Central_Manager>:8443 via SSH tunnel /or VPN)
# 2. Run Phase 2 configuration script:
cd /opt/guardium-azure/modules/central_manager
chmod +x run_guardium_phase2.sh
./run_guardium_phase2.sh 10.0.0.10 'YOUR_PASSWORD' YOUR_SHARED_SECRET

# Continue with Aggregators and Collectors
cd /opt/guardium-azure/examples/phase2agg && terraform init && terraform apply
cd ../phase3col && terraform init && terraform apply
```

---

## Deployment Guide

### Phase 0: Infrastructure & Bastion

**Purpose:** Create base networking infrastructure and secure bastion host.

**Components Created:**
- Resource Group
- Virtual Network (10.0.0.0/16)
- Guardium Subnet (10.0.0.0/24)
- Management Subnet (10.0.1.0/24)
- Network Security Groups
- Bastion Host (Ubuntu 22.04 LTS)

**Configuration Files:**
- `examples/phase0bastion/terraform.tfvars`

```bash
cd examples/phase0bastion

# Initialize Terraform
terraform init

# Preview changes
terraform plan

# Apply infrastructure
terraform apply

# Note the bastion public IP from outputs
```

**Expected Duration:** ~10 minutes

---

### Phase 1: Central Manager

**Purpose:** Deploy IBM Guardium Central Manager instance(s).

**Prerequisites:** Phase 0 completed successfully

**Configuration:** Edit `examples/phase1cm/central_manager_config.json`:

```json
{
  "central_managers": [
    {
      "vm_name": "cm01",
      "system_hostname": "cm01",
      "instance_type": "Standard_D8s_v3",
      "network_interface_ip": "10.0.0.10",
      "system_domain": "guardium.local",
      "network_interface_mask": "/24",
      "network_routes_defaultroute": "10.0.0.1",
      "network_resolvers1": "168.63.129.16",
      "network_resolvers2": "8.8.8.8",
      "system_clock_timezone": "America/New_York",
      "guardium_cli_default_password": "guardium",
      "guardium_final_pw": "YOUR_SECURE_PASSWORD",
      "guardium_shared_secret": "YOUR_SHARED_SECRET",
      "guardium_central_manager_ip": "10.0.0.10",
      "guardium_license_key": "YOUR_LICENSE_KEY"
    }
  ]
}
```

**Deployment (from bastion host):**

```bash
cd /opt/guardium-azure/examples/phase1cm
terraform init
terraform apply
```

**Expected Duration:** ~25-30 minutes (includes 20-minute Guardium boot time)

#### ⚠️ Post-Deployment: Central Manager Configuration (Required)

After the Terraform deployment completes, you **must** perform these additional steps to fully configure the Central Manager:

##### Step 1: Accept License Agreement in GUI

1. **Set up SSH port forwarding** to access the Guardium web interface:

```bash
# From your local machine, create SSH tunnel through bastion
ssh -L 8443:10.0.0.10:8443 -i ~/.ssh/your-key azureuser@<bastion-public-ip>
```

2. **Open browser** and navigate to:
```
https://localhost:8443
```

3. **Login** with the credentials:
   - Username: `admin`
   - Guardium Default Password: Your `guardium` 

4. **Accept the EULA/License Agreement** when prompted in the GUI

> ⚡ **Important:** The license must be accepted via the GUI before running the Phase 2 configuration script.

##### Step 2: Run Phase 2 Configuration Script

After accepting the license in the GUI, run the Phase 2 script to complete the Central Manager setup:

```bash
# SSH to bastion host
ssh azureuser@<bastion-public-ip>

# Navigate to central_manager module
cd /opt/guardium-azure/modules/central_manager

# Make the script executable (if not already)
chmod +x run_guardium_phase2.sh

# Run the Phase 2 configuration script
./run_guardium_phase2.sh <CM_IP> '<FINAL_PASSWORD>' <SHARED_SECRET>
```

**Example:**
```bash
./run_guardium_phase2.sh 10.0.0.10 'MySecurePassword123!' MySharedSecret123
```

**Parameters:**
| Parameter | Description | Example |
|-----------|-------------|---------|
| `<CM_IP>` | Central Manager private IP address | `10.0.0.10` |
| `<FINAL_PASSWORD>` | The `guardium_final_pw` you configured | `'MySecurePassword123!'` |
| `<SHARED_SECRET>` | The `guardium_shared_secret` from config | `MySharedSecret123` |

> 💡 **Tip:** Wrap the password in single quotes if it contains special characters.

**What Phase 2 Does:**
- Verifies license installation
- Sets the shared secret for unit registration
- Configures the unit type as "manager"
- Restarts services to apply changes

**Expected Duration:** ~5 minutes

**Verify Configuration:**
```bash
# SSH to Central Manager CLI
ssh cli@10.0.0.10

# Check unit type
show unit type

# Expected output: manager
```

##### For Multiple Central Managers

If deploying multiple Central Managers (e.g., cm01, cm02), repeat the post-deployment steps for each:

```bash
# For cm01 (Primary)
./run_guardium_phase2.sh 10.0.0.10 'YourPassword!' YourSharedSecret

# For cm02 (Secondary) - after cm01 is fully configured
./run_guardium_phase2.sh 10.0.0.11 'YourPassword!' YourSharedSecret
```

---

### Phase 2: Aggregators

**Purpose:** Deploy IBM Guardium Aggregator instance(s).

**Prerequisites:** Phase 1 completed successfully

**Configuration:** Edit `examples/phase2agg/aggregator_config.json`:

```json
{
  "aggregators": [
    {
      "vm_name": "agg01",
      "system_hostname": "agg01",
      "instance_type": "Standard_D8s_v3",
      "network_interface_ip": "10.0.0.15",
      "system_domain": "guardium.local",
      "network_interface_mask": "/24",
      "network_routes_defaultroute": "10.0.0.1",
      "network_resolvers1": "168.63.129.16",
      "network_resolvers2": "8.8.8.8",
      "system_clock_timezone": "America/New_York",
      "guardium_cli_default_password": "guardium",
      "guardium_final_pw": "YOUR_SECURE_PASSWORD",
      "guardium_shared_secret": "YOUR_SHARED_SECRET",
      "guardium_central_manager_ip": "10.0.0.10",
      "guardium_license_key": "YOUR_LICENSE_KEY"
    }
  ]
}
```

**Deployment (from bastion host):**

```bash
cd /opt/guardium-azure/examples/phase2agg
terraform init
terraform apply
```

**Expected Duration:** ~25-30 minutes per aggregator

---

### Phase 3: Collectors

**Purpose:** Deploy IBM Guardium Collector instance(s).

**Prerequisites:** Phase 2 completed successfully

**Configuration:** Edit `examples/phase3col/collector_config.json`:

```json
{
  "collectors": [
    {
      "vm_name": "col01",
      "system_hostname": "col01",
      "instance_type": "Standard_D8s_v3",
      "network_interface_ip": "10.0.0.20",
      "system_domain": "guardium.local",
      "network_interface_mask": "/24",
      "network_routes_defaultroute": "10.0.0.1",
      "network_resolvers1": "168.63.129.16",
      "network_resolvers2": "8.8.8.8",
      "system_clock_timezone": "America/New_York",
      "guardium_cli_default_password": "guardium",
      "guardium_final_pw": "YOUR_SECURE_PASSWORD",
      "guardium_shared_secret": "YOUR_SHARED_SECRET",
      "guardium_central_manager_ip": "10.0.0.10",
      "guardium_license_key": "YOUR_LICENSE_KEY"
    }
  ]
}
```

**Deployment (from bastion host):**

```bash
cd /opt/guardium-azure/examples/phase3col
terraform init
terraform apply
```

**Expected Duration:** ~25-30 minutes per collector

---

## Configuration Reference

### Project Structure

```
terraform-azure-guardium/
├── modules/
│   ├── bastion/              # Bastion host module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   └── outputs.tf
│   ├── central_manager/      # Central Manager module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── run_wait_for_guardium.sh      # Phase 1: Initial setup
│   │   ├── wait_for_guardium.expect      # Phase 1: Expect automation
│   │   ├── run_guardium_phase2.sh        # Phase 2: Post-GUI configuration ⭐
│   │   └── wait_for_guardium_phase2.expect # Phase 2: Expect automation
|   |   |---Logs 
│   ├── aggregator/           # Aggregator module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── run_wait_for_guardium.sh
│   │   └── wait_for_guardium.expect
|   |   |---Logs 
│   ├── collector/            # Collector module
│   │   ├── main.tf
│   │   ├── variables.tf
│   │   ├── outputs.tf
│   │   ├── run_wait_for_guardium.sh
│   │   └── wait_for_guardium.expect
|   |   |---Logs 
│   └── networking/           # Network infrastructure module
│       ├── main.tf
│       ├── variables.tf
│       └── outputs.tf
├── examples/
│   ├── phase0bastion/        # Phase 0: Bastion deployment
│   ├── phase1cm/             # Phase 1: Central Manager deployment
│   ├── phase2agg/            # Phase 2: Aggregator deployment
│   └── phase3col/            # Phase 3: Collector deployment
├── versions.tf
└── README.md
```

### Azure VM Configuration

| Component | Recommended Size | vCPUs | Memory |
|-----------|-----------------|-------|--------|
| Bastion Host | Standard_B2s | 2 | 4 GB |
| Central Manager | Standard_D8s_v3 | 8 | 32 GB |
| Aggregator | Standard_D8s_v3 | 8 | 32 GB |
| Collector | Standard_D8s_v3 | 8 | 32 GB |

### Configuration Parameters

| Parameter | Description | Example |
|-----------|-------------|---------|
| `vm_name` | VM instance name | `cm01` |
| `system_hostname` | Guardium system hostname | `cm01` |
| `instance_type` | Azure VM size | `Standard_D8s_v3` |
| `network_interface_ip` | Static private IP | `10.0.0.10` |
| `system_domain` | Domain name | `guardium.local` |
| `network_interface_mask` | Subnet mask (CIDR) | `/24` |
| `network_routes_defaultroute` | Default gateway | `10.0.0.1` |
| `network_resolvers1` | Primary DNS | `168.63.129.16` |
| `network_resolvers2` | Secondary DNS | `8.8.8.8` |
| `system_clock_timezone` | Timezone | `America/New_York` |
| `guardium_cli_default_password` | Initial password | `guardium` |
| `guardium_final_pw` | New secure password | `YourSecurePass123!` |
| `guardium_shared_secret` | Registration secret | `your-shared-secret` |
| `guardium_central_manager_ip` | CM IP for registration | `10.0.0.10` |
| `guardium_license_key` | Guardium license | `LICENSE-KEY-HERE` |

---

## Network Architecture

### IP Addressing Scheme

| Component | IP Range | Example IPs |
|-----------|----------|-------------|
| **Management Subnet** | 10.0.1.0/24 | |
| - Bastion Host | 10.0.1.10 | 10.0.1.10 |
| **Guardium Subnet** | 10.0.0.0/24 | |
| - Central Managers | 10.0.0.10-14 | 10.0.0.10, 10.0.0.11 |
| - Aggregators | 10.0.0.15-19 | 10.0.0.15, 10.0.0.16 |
| - Collectors | 10.0.0.20-29 | 10.0.0.20, 10.0.0.21 |

### Network Security Group Rules

#### Bastion NSG (Inbound)

| Rule | Port | Source | Description |
|------|------|--------|-------------|
| SSH | 22 | Allowed IPs | Admin SSH access |

#### Bastion NSG (Outbound)

security policy can be update from /modules/networking/main.tf

| Rule | Port | Destination | Description |
|------|------|-------------|-------------|
| SSH | 22 | 10.0.0.0/24 | Access to Guardium |
| HTTPS | 8443 | 10.0.0.0/24 | Guardium Web UI |

#### Guardium NSG (Inbound)
security policy can be update from /modules/networking/main.tf

| Rule | Port | Source | Description |
|------|------|--------|-------------|
| SSH | 22 | 10.0.1.0/24 | Management access |
| Guardium UI | 8443 | 10.0.1.0/24 | Web interface |
| HTTPS | 443 | 10.0.1.0/24 | Secure web access |
| MySQL | 3306 | 10.0.0.0/16 | Internal DB communication |
| Guardium Internal | 8447 | 10.0.0.0/16 | Component communication |
| Solr | 8983, 9983 | 10.0.0.0/16 | Search indexing |

---

## Security

### Security Best Practices

1. **Restricted Bastion Access**
   - Only specified IP addresses can SSH to bastion
   - Configure `allowed_source_ips` in terraform.tfvars

2. **No Public IPs on Guardium**
   - All Guardium components use private IPs only
   - Access only through bastion host

3. **SSH Key Authentication**
   - Password authentication disabled on bastion
   - Use SSH key pairs for access

4. **Network Segmentation**
   - Separate management and Guardium subnets
   - NSG rules restrict traffic flow

5. **Credential Management**
```bash
   # Store sensitive values in environment variables
   export TF_VAR_client_secret="your-secret"
   export TF_VAR_guardium_final_pw="your-password"
   ```

6. **Azure Key Vault (Recommended)**
   - Store SSH keys in Azure Key Vault
   - Store Guardium credentials securely
   - Reference secrets via data sources

### Allowed Source IPs

Configure trusted IP addresses in `terraform.tfvars`:

```hcl
allowed_source_ips = [
  "YOUR.PUBLIC.IP.1/32",
  "YOUR.PUBLIC.IP.2/32",
  "YOUR.CORP.RANGE/24"
]
```

---

## Accessing Guardium

### SSH Access

```bash
# Connect to bastion host
ssh -i ~/.ssh/your-key azureuser@<bastion-public-ip>

# From bastion, access Guardium CLI
ssh cli@10.0.0.10    # Central Manager
ssh cli@10.0.0.15    # Aggregator
ssh cli@10.0.0.20    # Collector
```

### Web Interface Access (Port Forwarding)

```bash
# Forward Guardium Web UI through bastion
ssh -L 8443:10.0.0.10:8443 -i ~/.ssh/your-key azureuser@<bastion-public-ip>

# Then open in browser
https://localhost:8443
```

### Default Credentials

| Component | Username | Default Password |
|-----------|----------|------------------|
| Guardium CLI | `cli` | `guardium` (changed during setup) |
| Guardium Web UI | `admin` | (set during deployment) |

---

## Troubleshooting

### Common Issues

#### 1. SSH Connection Timeout

```bash
# Verify bastion is reachable
nc -zv <bastion-public-ip> 22

# Check your source IP is allowed
curl ifconfig.me  # Verify your public IP
```

**Solution:** Add your IP to `allowed_source_ips`

#### 2. Guardium Not Responding After Deployment

Guardium requires ~20 minutes to fully initialize after VM creation.

```bash
# Check VM status
az vm get-instance-view --name cm01 --resource-group IBMGuardium --query instanceView.statuses

# View boot diagnostics
az vm boot-diagnostics get-boot-log --name cm01 --resource-group IBMGuardium
```

#### 3. License Installation Failed

```bash
# SSH to Guardium and check license status
ssh cli@10.0.0.10
show license
```

**Solution:** Verify license key format and validity

#### 4. Phase 2 Script Fails

**Error:** `Permission denied`
```bash
chmod +x /opt/guardium-azure/modules/central_manager/run_guardium_phase2.sh
```

**Error:** `Cannot reach IP on port 22`
- Ensure you're running from the bastion host
- Verify the Central Manager is fully booted (~20 mins after terraform apply)
- Check NSG rules allow SSH from management subnet

**Error:** `SSH authentication failed`
- Verify you're using the correct `guardium_final_pw` password
- Make sure Phase 1 terraform deployment completed successfully

**Verify Phase 2 Success:**
```bash
ssh cli@10.0.0.10
show unit type
# Should output: manager
```

**View Phase 2 Logs:**
```bash
ls -la /opt/guardium-azure/modules/central_manager/logs/
cat /opt/guardium-azure/modules/central_manager/logs/guardium_phase2_*.log
```

#### 5. Network Configuration Issues

```bash
# Verify network settings from Guardium CLI
show network interface all
show network routes defaultroute
show network resolver all
```

#### 6. Terraform State Issues

```bash
# If state is corrupted, refresh it
terraform refresh

# Import existing resources if needed
terraform import module.central_manager.azurerm_linux_virtual_machine.vm /subscriptions/.../resourceGroups/.../providers/Microsoft.Compute/virtualMachines/cm01
```

### Viewing Logs

```bash
# Configuration logs on bastion
ls -la /opt/guardium-azure/modules/*/logs/guardium_config/

# View specific log
cat /opt/guardium-azure/modules/central_manager/logs/guardium_config/guardium_config_10.0.0.10_*.log
```

### Debug Commands

```bash
# Check Guardium service status
ssh cli@10.0.0.10 "show system status"

# Verify component connectivity
ssh cli@10.0.0.10 "grdapi get_state"

# List all VMs
az vm list --resource-group IBMGuardium -o table
```

---

## Cleanup

Destroy resources in **reverse order** to avoid dependency issues:

```bash
# Phase 3: Destroy Collectors
cd /opt/guardium-azure/examples/phase3col
terraform destroy -auto-approve

# Phase 2: Destroy Aggregators
cd /opt/guardium-azure/examples/phase2agg
terraform destroy -auto-approve

# Phase 1: Destroy Central Managers
cd /opt/guardium-azure/examples/phase1cm
terraform destroy -auto-approve

# Phase 0: Destroy Infrastructure (from local machine)
cd examples/phase0bastion
terraform destroy -auto-approve
```

⚠️ **Warning:** Destroying Phase 0 from the bastion will terminate your SSH session. Run Phase 0 destroy from your local machine.

---

## Contributing

Contributions are welcome! Please follow these steps:

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines

- Follow Terraform best practices
- Include documentation for new features
- Test changes in a non-production environment
- Update examples if configuration options change

---

## License

This project is licensed under the Apache 2.0 License - see the [LICENSE](LICENSE) file for details.

```text
#
# Copyright (c) IBM Corp. 2026
# SPDX-License-Identifier: Apache-2.0
#
```

---

## Support

### IBM Guardium Support

- [IBM Guardium Documentation](https://www.ibm.com/docs/en/guardium)
- [IBM Support Portal](https://www.ibm.com/mysupport)

### Azure Support

- [Azure Documentation](https://docs.microsoft.com/en-us/azure/)
- [Terraform Azure Provider](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs)

### Project Issues

For issues related to this Terraform project, please open a [GitHub Issue](https://github.com/ibm/terraform-azure-guardium/issues).
