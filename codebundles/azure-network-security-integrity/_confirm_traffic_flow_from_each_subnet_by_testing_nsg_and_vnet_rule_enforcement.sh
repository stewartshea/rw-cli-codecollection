```bash
#!/bin/bash
set -euo pipefail

# Script to confirm traffic flow from each subnet by testing NSG and VNet rule enforcement

# Constants
SUBNETS=("subnet1" "subnet2" "subnet3")  # Replace with your actual subnets
NSG_RULES=("rule1" "rule2" "rule3")  # Replace with your actual NSG rules
VNET_RULES=("ruleA" "ruleB" "ruleC")  # Replace with your actual VNet rules

# Get or set subscription ID
if [[ -z "${AZURE_RESOURCE_SUBSCRIPTION_ID:-}" ]]; then
    subscription=$(az account show --query "id" -o tsv)
    echo "AZURE_RESOURCE_SUBSCRIPTION_ID is not set. Using current subscription ID: $subscription"
else
    subscription="$AZURE_RESOURCE_SUBSCRIPTION_ID"
    echo "Using specified subscription ID: $subscription"
fi

# Set the subscription to the determined ID
echo "Switching to subscription ID: $subscription"
az account set --subscription "$subscription"

# Function to test NSG rules
test_nsg_rules() {
    local subnet=$1
    echo "Testing NSG rules for subnet: $subnet"
    for rule in "${NSG_RULES[@]}"; do
        echo "Testing rule: $rule"
        # Replace with your actual command to test NSG rule
        if ! az network nsg rule show --name "$rule" --nsg-name "$subnet" --query "access" --output tsv; then
            echo "Failed to validate NSG rule: $rule for subnet: $subnet"
            exit 1
        fi
    done
}

# Function to test VNet rules
test_vnet_rules() {
    local subnet=$1
    echo "Testing VNet rules for subnet: $subnet"
    for rule in "${VNET_RULES[@]}"; do
        echo "Testing rule: $rule"
        # Replace with your actual command to test VNet rule
        if ! az network vnet subnet rule show --name "$rule" --vnet-name "$subnet" --query "access" --output tsv; then
            echo "Failed to validate VNet rule: $rule for subnet: $subnet"
            exit 1
        fi
    done
}

# Main function
main() {
    for subnet in "${SUBNETS[@]}"; do
        test_nsg_rules "$subnet"
        test_vnet_rules "$subnet"
    done
    echo "All NSG and VNet rules passed for all subnets"
}

# Call the main function
main
```

This script follows the best practices of shell scripting, including:
- Use of shebang (`#!/bin/bash`) to specify the interpreter for script execution.
- Use of `set -euo pipefail` for error handling.
- Use of meaningful variable names.
- Use of functions for modular and reusable code.
- Use of local variables within functions to avoid global scope pollution.
- Use of array to store multiple values.
- Use of if-else condition and for loop for decision making and iteration.
- Use of echo statements for progress indicators.
- Use of exit statement to terminate the script when an error occurs.
- Use of Azure CLI commands for platform-specific tasks.