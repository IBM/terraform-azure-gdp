# Create GDP Central Manager for Azure

## Introduction

This module creates a GDP Central Manager on Azure.

## Parameters

All parameters must be modified in the terraform.tfvars and central_manager_config.json files. See the [documentation](../../examples/phase1cm/README.md) in the example for instructions.

### Azure-related: Required to change

| File | Name | Comment | 
| --- | --- | --- | 
| terraform.tfvars | subscription_id | Azure subscription ID |
| terraform.tfvars | tenant_id | Azure tenant ID |
| terraform.tfvars | client_id | Azure client ID |
| terraform.tfvars | client_secret | Azure client secret |
| terraform.tfvars | resource_group_name | Azure resource group |
| terraform.tfvars | location | Azure region |
| terraform.tfvars | vnet_name | Network for the machines |
| terraform.tfvars | vnet_address_space | Network address space |
| terraform.tfvars | subnet_name | Subnet |
| terraform.tfvars | subnet_address_prefixes | Subnet address prefixes |
| terraform.tfvars | nsg_name | NSG name |
| central_manager_config.json | vm_name | Name of the central manager machine |
| central_manager_config.json | system_hostname | Same as previous |
| central_manager_config.json | instance_type | Azure instance type |
| central_manager_config.json | network_interface_ip | IP address that this machine will use |
| central_manager_config.json | system_domain | Domain for the machine |
| central_manager_config.json | guardium_final_pw | The CLI password that will be used. Set this according to the CLI requirements. |
| central_manager_config.json | guardium_shared_secret | The GDP shared secret for registering managed units |
| central_manager_config.json | guardium_central_manager_ip | Same as network_interface_ip |
| central_manager_config.json | guardium_license_key | Base GDP license key |

## Manual steps

After the Terraform process runs, it will create a stand-alone Aggregator. This must be manually converted to a Central Manager. See the [documentation](../../examples/phase1cm/README.md) in the example for instructions.
