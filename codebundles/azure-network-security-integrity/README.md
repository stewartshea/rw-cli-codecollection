# Azure Network Security Integrity Codebundle

This codebundle, named `azure-network-security-integrity`, is designed for the Azure platform and focuses on network security services. Its main purpose is to ensure the integrity of your network security settings and configurations.

## Overview

This codebundle contains scripts that perform various tasks related to network security integrity. These tasks include:

- Comparing current Network Security Group (NSG) rules with the desired state managed in your repository. Any discrepancies that suggest changes made outside of the normal process will be flagged.
- Confirming the flow of traffic from each subnet by testing NSG and Virtual Network (VNet) rule enforcement.
- Querying activity logs to identify whether firewall/NSG changes were pushed through the CI/CD pipeline or made manually.
- Detecting manual changes to NSG rules.

## Prerequisites

Before you can use this codebundle, you need to have the following:

- Azure CLI installed and configured with the appropriate permissions.
- Access to the Azure subscription and resources you want to monitor.
- A configured CI/CD pipeline (if you want to compare changes against it).

## Setup

1. Clone this repository to your local machine.
2. Navigate to the directory containing the codebundle.
3. Ensure that the Azure CLI is logged in to the correct account.

## Usage

Each script in the codebundle can be run independently, depending on the task you want to perform. Here are some examples:

```bash
# To check the integrity of NSG rules
./nsg_integrity_check.sh

# To test NSG and VNet rule enforcement
./nsg_vnet_test.sh

# To query activity logs for firewall/NSG changes
./activity_log_query.sh

# To detect manual changes to NSG rules
./detect_manual_nsg_changes.sh
```

## Environment Variables

The scripts use the following environment variables:

- `AZURE_SUBSCRIPTION_ID`: The ID of your Azure subscription.
- `AZ_RESOURCE_GROUP`: The name of the resource group containing the resources you want to monitor.
- `ACR_NAME`: The name of the Azure Container Registry.
- `USAGE_THRESHOLD`: The usage threshold for storage and SKU, expressed as a percentage.

## Expected Output

The scripts output JSON files containing any issues they find. For example, the `nsg_integrity_check.sh` script outputs a `nsg_integrity_issues.json` file.

## Troubleshooting

If you encounter any issues while using this codebundle, try the following:

- Check the output of the scripts for any error messages.
- Ensure that the Azure CLI is logged in to the correct account.
- Verify that all environment variables are set correctly.
- Check the Azure documentation for any error codes.

## Documentation

For more information on Azure network security, see the [Azure documentation](https://docs.microsoft.com/en-us/azure/security/fundamentals/network-best-practices).

For more information on Azure CLI commands, see the [Azure CLI documentation](https://docs.microsoft.com/en-us/cli/azure/).

## Conclusion

This codebundle provides a comprehensive set of tools for maintaining the integrity of your Azure network security settings. By regularly running these scripts, you can detect and address any unauthorized or unexpected changes, ensuring the security and reliability of your Azure resources.