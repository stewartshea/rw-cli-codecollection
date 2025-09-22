# Azure Network Security Integrity Codebundle

This codebundle is designed to ensure the integrity of your Azure Network Security Groups (NSGs) and Virtual Networks (VNet). It includes scripts to compare current NSG rules with the desired state, confirm traffic flow from each subnet, and query activity logs to identify firewall/NSG changes.

## Overview

The `azure-network-security-integrity` codebundle is a collection of scripts that help maintain the integrity of your Azure Network Security Groups (NSGs) and Virtual Networks (VNet). It provides tasks to:

- Compare current NSG rules with your desired state as managed in your repository. Any discrepancies that indicate out-of-band changes are flagged.
- Confirm traffic flow from each subnet by testing NSG and VNet rule enforcement.
- Query activity logs to identify whether firewall/NSG changes were pushed through the CI/CD pipeline or were made manually.
- Detect manual NSG changes that could potentially compromise your network security.

## Prerequisites

- Azure CLI installed and configured with the appropriate permissions.
- Bash shell (version 4.0 or later).
- jq JSON processor.

## Setup

1. Clone this repository to your local machine.
2. Set the necessary environment variables (see the Environment Variables section below).
3. Run the scripts as per the Usage Instructions.

## Usage Instructions

Each script in this codebundle can be run independently. For example, to run the `aks_network.sh` script, use the following command:

```bash
./aks_network.sh
```

## Environment Variables

The following environment variables are used in the scripts:

- `AZURE_RESOURCE_SUBSCRIPTION_ID`: Your Azure subscription ID. If not set, the scripts will use the current subscription ID.
- `AZURE_SUBSCRIPTION_ID`: Your Azure subscription ID. Used in the `acr_storage_usage.sh` and `acr_usage_sku.sh` scripts.
- `AZ_RESOURCE_GROUP`: The Azure resource group. Used in the `acr_storage_usage.sh` and `acr_usage_sku.sh` scripts.
- `ACR_NAME`: The Azure Container Registry name. Used in the `acr_storage_usage.sh` and `acr_usage_sku.sh` scripts.
- `USAGE_THRESHOLD`: The usage threshold for the Azure Container Registry. Used in the `acr_storage_usage.sh` and `acr_usage_sku.sh` scripts.

## Troubleshooting

If you encounter any issues while running the scripts, check the following:

- Ensure that all the required environment variables are set.
- Check that you have the necessary permissions in Azure to run the scripts.
- Ensure that the Azure CLI is installed and configured correctly.

## Documentation

For more information on Azure Network Security Groups (NSGs) and Virtual Networks (VNet), see the [Azure documentation](https://docs.microsoft.com/en-us/azure/virtual-network/).

## Expected Output

The scripts output JSON files with the results of their checks. For example, the `acr_storage_usage.sh` script outputs a `storage_usage_issues.json` file with any issues it finds.

## Conclusion

The `azure-network-security-integrity` codebundle helps you maintain the integrity of your Azure Network Security Groups (NSGs) and Virtual Networks (VNet). By running these scripts regularly, you can ensure that your network security is always in the desired state.