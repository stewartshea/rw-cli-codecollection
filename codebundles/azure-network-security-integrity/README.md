# Azure Network Security Integrity Codebundle

This codebundle is designed to ensure the integrity of your Azure Network Security Group (NSG) rules. It compares the current NSG rules with the desired state, flags discrepancies that indicate out-of-band changes, confirms traffic flow from each subnet by testing NSG and VNet rule enforcement, and queries activity logs to identify whether firewall/NSG changes were pushed through the CI/CD pipeline vs. manual actors.

## Tasks

1. **Compare current NSG rules with repo-managed desired state**: This task checks the current state of your NSG rules against the desired state as defined in your repository. Any discrepancies are flagged for review.

2. **Flag discrepancies that indicate out-of-band changes**: If any discrepancies are found during the comparison, these are flagged as potential out-of-band changes that need to be investigated.

3. **Confirm traffic flow from each subnet by testing NSG and VNet rule enforcement**: This task tests the enforcement of your NSG and VNet rules by confirming the traffic flow from each subnet.

4. **Query activity logs to identify whether firewall/NSG changes were pushed through CI/CD pipeline vs. manual actors**: This task queries your activity logs to identify the source of any changes to your firewall or NSG rules. It can distinguish between changes pushed through the CI/CD pipeline and changes made manually.

5. **Detect Manual NSG Changes**: This task is designed to detect any manual changes made to your NSG rules.

## Usage Instructions

To use this codebundle, you will need to set the following environment variables:

- `AZURE_RESOURCE_SUBSCRIPTION_ID`: Your Azure subscription ID.
- `AZURE_SUBSCRIPTION_ID`: Your Azure subscription ID.
- `AZ_RESOURCE_GROUP`: The Azure resource group.
- `ACR_NAME`: The Azure Container Registry name.
- `USAGE_THRESHOLD`: The usage threshold.

Once these environment variables are set, you can run the scripts in this codebundle.

## Prerequisites and Setup

Before using this codebundle, you will need to install the Azure CLI and authenticate with your Azure account.

## Troubleshooting

If you encounter any issues while using this codebundle, check the output of the scripts for any error messages. These messages should give you a clue as to what went wrong.

## Expected Output

The output of these scripts will be a series of JSON files that contain the results of the tasks. These files can be used for further analysis or for troubleshooting purposes.

## Documentation

For more information on Azure Network Security Groups, see the [Azure documentation](https://docs.microsoft.com/en-us/azure/virtual-network/security-overview).

## Conclusion

This codebundle is a comprehensive tool for maintaining the integrity of your Azure Network Security Groups. It provides a range of tasks that can help you detect and investigate any discrepancies or changes.