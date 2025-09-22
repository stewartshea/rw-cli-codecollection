Here is the bash script for the task:

```bash
#!/bin/bash

set -e
set -o pipefail

# Environment Variables
SUBSCRIPTION_ID=${AZURE_SUBSCRIPTION_ID:-}
RESOURCE_GROUP=${AZ_RESOURCE_GROUP:-}
NSG_NAME=${NSG_NAME:-}
DESIRED_STATE_FILE=${DESIRED_STATE_FILE:-}

# File to store the current NSG rules
CURRENT_STATE_FILE="current_nsg_rules.json"

# Function to add issues to a JSON file
add_issue() {
    local title="$1"
    local severity="$2"
    local expected="$3"
    local actual="$4"
    local details="$5"
    local next_steps="$6"
    details=$(echo "$details" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')
    next_steps=$(echo "$next_steps" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')
    echo "$(jq --arg title "$title" --arg severity "$severity" --arg expected "$expected" --arg actual "$actual" --arg details "$details" --arg next_steps "$next_steps" '. += [{"title": $title, "severity": $severity, "expected": $expected, "actual": $actual, "details": $details, "next_steps": $next_steps}]' $ISSUES_FILE)" > $ISSUES_FILE
}

# Check if AZURE_SUBSCRIPTION_ID is set, otherwise get the current subscription ID
if [ -z "$SUBSCRIPTION_ID" ]; then
    SUBSCRIPTION_ID=$(az account show --query "id" -o tsv)
    echo "AZURE_SUBSCRIPTION_ID is not set. Using current subscription ID: $SUBSCRIPTION_ID"
else
    echo "Using specified subscription ID: $SUBSCRIPTION_ID"
fi

# Set the subscription to the determined ID
echo "Switching to subscription ID: $SUBSCRIPTION_ID"
az account set --subscription $SUBSCRIPTION_ID

# Get the current NSG rules
echo "Getting current NSG rules..."
az network nsg rule list --resource-group $RESOURCE_GROUP --nsg-name $NSG_NAME --query "[].{name:name, priority:priority, access:access, direction:direction, protocol:protocol, sourceAddressPrefix:sourceAddressPrefix, destinationAddressPrefix:destinationAddressPrefix, sourcePortRange:sourcePortRange, destinationPortRange:destinationPortRange}" > $CURRENT_STATE_FILE

# Compare current NSG rules with repo-managed desired state
echo "Comparing current NSG rules with desired state..."
DIFF=$(diff <(jq -S . $CURRENT_STATE_FILE) <(jq -S . $DESIRED_STATE_FILE))

if [ "$DIFF" != "" ]; then
    echo "NSG rules do not match desired state. See issues.json for details."
    add_issue "NSG rules do not match desired state" "High" "$(cat $DESIRED_STATE_FILE)" "$(cat $CURRENT_STATE_FILE)" "$DIFF" "Please update the NSG rules to match the desired state." 
    exit 1
else
    echo "NSG rules match desired state."
fi
```

This script first checks if the Azure subscription ID is set, and if not, it gets the current subscription ID. It then sets the subscription to the determined ID. After that, it gets the current Network Security Group (NSG) rules and stores them in a JSON file. It then compares the current NSG rules with the desired state, which is also stored in a JSON file. If the current NSG rules do not match the desired state, it logs an issue and exits with a non-zero status code. If the current NSG rules match the desired state, it prints a success message.