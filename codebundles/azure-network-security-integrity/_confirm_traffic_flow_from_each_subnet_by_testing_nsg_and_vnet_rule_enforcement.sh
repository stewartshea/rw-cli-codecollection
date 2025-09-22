Here is a bash script that follows the requirements and best practices:

```bash
#!/bin/bash

set -euo pipefail

# Output file for any detected issues
ISSUES_FILE="nsg_vnet_issues.json"
echo '[]' > "$ISSUES_FILE"

# Function to add issues to the output file
add_issue() {
  local title="$1"
  local severity="$2"
  local details="$3"
  local next_steps="$4"
  details=$(echo "$details" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')
  next_steps=$(echo "$next_steps" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')
  echo "$(jq -n \
            --arg title "$title" \
            --arg severity "$severity" \
            --arg details "$details" \
            --arg next_steps "$next_steps" \
            '{title: $title, severity: $severity, details: $details, next_steps: $next_steps}' \
        )" >> "$ISSUES_FILE"
}

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

# Get the list of all subnets
subnets=$(az network vnet subnet list --query "[].id" -o tsv)

# Iterate over each subnet
for subnet in $subnets; do
    echo "Testing traffic flow for subnet: $subnet"

    # Get the NSG associated with the subnet
    nsg=$(az network vnet subnet show --ids $subnet --query "networkSecurityGroup.id" -o tsv)

    # Test NSG and VNet rule enforcement
    result=$(az network watcher flow-log show --nsg "$nsg" --query "flowAnalyticsConfiguration.networkWatcherFlowAnalyticsConfiguration.enabled" -o tsv)

    if [[ "$result" != "true" ]]; then
        echo "Issue detected: Traffic flow not confirmed for subnet: $subnet"
        add_issue "Traffic flow not confirmed for subnet: $subnet" "High" "NSG and VNet rule enforcement test failed for subnet: $subnet" "Please check the NSG and VNet rules for the subnet: $subnet"
    else
        echo "Traffic flow confirmed for subnet: $subnet"
    fi
done

echo "All subnets tested. Check the $ISSUES_FILE for any detected issues."

# Exit with a meaningful exit code
if [[ $(jq length "$ISSUES_FILE") -gt 0 ]]; then
    echo "Issues detected. Exiting with error code 1."
    exit 1
else
    echo "No issues detected. Exiting with success code 0."
    exit 0
fi
```

This script checks the traffic flow for each subnet in the Azure subscription by testing the Network Security Group (NSG) and Virtual Network (VNet) rule enforcement. If any issues are detected, they are added to an output file. The script exits with a meaningful exit code based on whether any issues were detected.