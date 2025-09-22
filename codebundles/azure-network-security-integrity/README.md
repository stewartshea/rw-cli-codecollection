# Azure Network Security Integrity Codebundle

This codebundle is designed to maintain the integrity of your Azure Network Security Group (NSG) configurations. It provides scripts to compare your current NSG rules with your desired state, flag any discrepancies, confirm traffic flow from each subnet, and query activity logs to identify whether firewall/NSG changes were pushed through CI/CD pipeline or made manually. 

## Description

The `azure-network-security-integrity` codebundle is a collection of scripts that help to ensure the integrity of your Azure Network Security. It provides a way to automate the process of checking NSG rules, testing NSG and VNet rule enforcement, and identifying the source of firewall/NSG changes. 

## Tasks

1. **Compare current NSG rules with repo-managed desired state**: This task checks the current NSG rules against the desired state defined in your repository. If there are any discrepancies, it flags them for review.

2. **Confirm traffic flow from each subnet**: This task tests the enforcement of NSG and VNet rules by confirming the traffic flow from each subnet.

3. **Query activity logs for firewall/NSG changes**: This task queries the activity logs to identify whether firewall/NSG changes were pushed through the CI/CD pipeline or made manually.

4. **Detect Manual NSG Changes**: This task detects any manual changes made to the NSG that were not pushed through the CI/CD pipeline.

## Usage

Each script in this codebundle can be run independently. To run a script, use the following command:

```bash
bash <script-name>.sh
```

Replace `<script-name>` with the name of the script you want to run.

## Prerequisites

- Azure CLI installed and configured
- Appropriate permissions to read and write to the Azure resources
- A configured Azure subscription

## Setup

1. Clone this repository to your local machine.
2. Navigate to the directory containing the scripts.
3. Run the scripts as described in the Usage section.

## Environment Variables

Each script uses environment variables for configuration. These variables should be set before running the scripts. The required variables are:

- `AZURE_SUBSCRIPTION_ID`: The ID of your Azure subscription.
- `AZ_RESOURCE_GROUP`: The name of the Azure resource group.
- `ACR_NAME`: The name of the Azure Container Registry.
- `USAGE_THRESHOLD`: The usage threshold for storage and SKU usage.

## Troubleshooting

If you encounter any issues while running the scripts, check the following:

- Ensure that all environment variables are set correctly.
- Ensure that you have the necessary permissions to access and modify the Azure resources.
- Check the Azure activity logs for any errors or warnings.

## Expected Output

Each script outputs a JSON file containing any issues it finds. The structure of the JSON file is as follows:

```json
[
  {
    "title": "Issue title",
    "severity": "Issue severity",
    "expected": "Expected value",
    "actual": "Actual value",
    "details": "Detailed description of the issue",
    "next_steps": "Steps to resolve the issue",
    "reproduce_hint": "Steps to reproduce the issue"
  },
  ...
]
```

## Documentation

For more information about Azure Network Security Groups, see the [official Azure documentation](https://docs.microsoft.com/en-us/azure/virtual-network/security-overview).

For more information about Azure CLI, see the [official Azure CLI documentation](https://docs.microsoft.com/en-us/cli/azure/).

## Conclusion

The `azure-network-security-integrity` codebundle is a valuable tool for maintaining the integrity of your Azure Network Security configurations. By automating the process of checking NSG rules and identifying the source of changes, it helps to prevent unauthorized changes and ensure that your network remains secure.