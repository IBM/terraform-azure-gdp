# Create bastion host for Azure

## Introduction

This module creates a bastion host on Azure.

## Parameters

All parameters must be modified in the terraform.tfvars file. See the [documentation](../../examples/phase0bastion/README.md) in the example for instructions.

### Azure-related: Required to change

| Name | Comment | 
| --- | --- | 
| subscription_id | Azure subscription ID |
| tenant_id | Azure tenant ID |
| client_id | Azure client ID |
| client_secret | Azure client secret |
| resource_group_name | Azure resource group |
| location | Azure region |
| vnet_name | Network for the machines |
| vnet_address_space | Network address space |
| subnet_name | Subnet |
| subnet_address_prefixes | Subnet address prefixes |
| nsg_name | NSG name |
| bastion_name | Name of the bastion host to be created |
| bastion__vm_size | Hardware profile of the machine |
| bastion_private_ip | Set the IP of the bastion host in the network |
| management_subnet_name | The management subnet |
| management_subnet_prefixes | Prefixes of the management subnet |
| allowed_source_ips | IPs that will be able to SSH into the bastion host |
| admin_username | The `username` you created in step 1 |
| ssh_public_key | The public key you created in step 1 |
| ssh_private_key | The private key you created in step 1 |
