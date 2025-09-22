# Azure Network Security Integrity Codebundle

This codebundle, named `azure-network-security-integrity`, is designed to ensure the integrity of your Azure Network Security Group (NSG) rules. It is built for the Azure platform and specifically targets network security services.

## Overview

The main purpose of this codebundle is to ensure the integrity of your Azure NSG rules by comparing the current state with the desired state managed in your repository. It flags any discrepancies that may indicate out-of-band changes. Furthermore, it confirms the traffic flow from each subnet by testing NSG and Virtual Network (VNet) rule enforcement. This codebundle also queries activity logs to identify whether firewall/NSG changes were pushed through the CI/CD pipeline or were made manually.

## Tasks

This codebundle performs the following tasks:

1. **Compare current NSG rules with repo-managed desired state**: This task checks for any discrepancies between the current NSG rules and the desired state as defined in your repository.

2. **Flag discrepancies that indicate out-of-band changes**: If any discrepancies are found, this task will flag them for further investigation.

3. **Confirm traffic flow from each subnet by testing NSG and VNet rule enforcement**: This task confirms that traffic is flowing correctly from each subnet by testing the enforcement of NSG and VNet rules.

4. **Query activity logs to identify whether firewall/NSG changes were pushed through CI/CD pipeline vs. manual actors**: This task checks the activity logs to determine whether changes to the firewall or NSG were made through the CI/CD pipeline or manually.

5. **Detect Manual NSG Changes**: This task detects any manual changes made to the NSG rules.

## Usage

To use this codebundle, you need to run the scripts in your Azure environment. Each script has its own specific usage instructions, which are included in the script files themselves. 

## Prerequisites and Setup

Before you can use this codebundle, you need to have the following:

- An Azure account
- Azure CLI installed
- Proper permissions to manage NSG rules in Azure

## Troubleshooting

If you encounter any issues while using this codebundle, please check the following:

- Ensure that you have the correct permissions in Azure.
- Check that your Azure CLI is installed and working correctly.
- Make sure that all environment variables are set correctly.

## Environment Variables

This codebundle uses the following environment variables:

- `AZURE_RESOURCE_SUBSCRIPTION_ID`: Your Azure subscription ID.
- `AZURE_SUBSCRIPTION_ID`: Your Azure subscription ID.
- `AZ_RESOURCE_GROUP`: The Azure resource group.
- `ACR_NAME`: The Azure Container Registry name.
- `USAGE_THRESHOLD`: The usage threshold.

## Expected Output

The output of this codebundle will vary depending on the tasks being performed. However, you can expect to see a JSON file with any flagged discrepancies, a confirmation of traffic flow, and a log of any changes made to the firewall or NSG.

## Documentation

For more information on Azure Network Security Groups, please refer to the [official Azure documentation](https://docs.microsoft.com/en-us/azure/virtual-network/security-overview).

## Conclusion

This codebundle is a comprehensive tool for maintaining the integrity of your Azure NSG rules. By regularly comparing your current NSG rules with your desired state, flagging any discrepancies, confirming traffic flow, and monitoring changes, you can ensure that your Azure network security is always in a good state.