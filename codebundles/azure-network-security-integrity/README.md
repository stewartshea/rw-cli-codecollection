# Azure Network Security Integrity Codebundle

This codebundle, named `azure-network-security-integrity`, is designed to ensure the integrity of your Azure Network Security Groups (NSGs) and Virtual Network (VNet) rules. It is specifically tailored for the Azure platform and focuses on the network-security service type.

## Overview

The primary purpose of this codebundle is to maintain the integrity of your Azure NSGs and VNet rules. It accomplishes this by performing the following tasks:

- Comparing the current NSG rules with the desired state managed in your repository. Any discrepancies that indicate out-of-band changes will be flagged.
- Confirming the traffic flow from each subnet by testing NSG and VNet rule enforcement.
- Querying activity logs to identify whether firewall/NSG changes were pushed through the CI/CD pipeline or made manually.
- Detecting manual NSG changes.

## Prerequisites

Before you can use this codebundle, you need to have the following:

- Azure CLI installed on your machine.
- An active Azure subscription.
- The necessary permissions to manage NSGs and VNets in your Azure subscription.

## Setup

To set up the codebundle, follow these steps:

1. Clone the repository containing the codebundle.
2. Navigate to the directory containing the codebundle.
3. Set the necessary environment variables (see the Environment Variables section below).
4. Run the scripts in your terminal.

## Environment Variables

This codebundle uses the following environment variables:

- `AZURE_SUBSCRIPTION_ID`: Your Azure subscription ID.
- `AZURE_RESOURCE_GROUP`: The Azure resource group containing your NSGs and VNets.
- `AZURE_NSG_NAME`: The name of your Azure NSG.
- `AZURE_VNET_NAME`: The name of your Azure VNet.

## Usage

To use this codebundle, run the scripts in your terminal. For example:

```bash
./nsg_comparison.sh
./vnet_traffic_test.sh
./activity_log_query.sh
./detect_manual_nsg_changes.sh
```

## Expected Output

Each script in this codebundle will output a JSON file containing the results of its tasks. For example, the `nsg_comparison.sh` script will output a `nsg_comparison.json` file.

## Troubleshooting

If you encounter any issues while using this codebundle, check the following:

- Ensure that all environment variables are set correctly.
- Ensure that you have the necessary permissions to manage NSGs and VNets in your Azure subscription.
- Check the Azure CLI documentation for any errors related to the Azure CLI commands used in the scripts.

## Documentation

For more information on Azure NSGs and VNets, see the following Azure documentation:

- [Azure Network Security Groups](https://docs.microsoft.com/en-us/azure/virtual-network/security-overview)
- [Azure Virtual Networks](https://docs.microsoft.com/en-us/azure/virtual-network/virtual-networks-overview)

## Conclusion

This codebundle provides a comprehensive solution for maintaining the integrity of your Azure NSGs and VNets. By regularly running these scripts, you can ensure that your network security remains robust and reliable.