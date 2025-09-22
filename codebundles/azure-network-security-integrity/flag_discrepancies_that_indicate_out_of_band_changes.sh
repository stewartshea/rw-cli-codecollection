Here is a bash script that follows the requirements and best practices:

```bash
#!/bin/bash

set -euo pipefail

# Define the output file for discrepancies
DISCREPANCY_FILE="network_security_discrepancies.json"
echo '[]' > "$DISCREPANCY_FILE"

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

# Function to add discrepancies to the output file
add_discrepancy() {
    local resource="$1"
    local expected="$2"
    local actual="$3"
    local details="$4"
    local next_steps="$5"

    # Escape JSON characters properly
    details=$(echo "$details" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')
    next_steps=$(echo "$next_steps" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')

    jq -n \
        --arg resource "$resource" \
        --arg expected "$expected" \
        --arg actual "$actual" \
        --arg details "$details" \
        --arg next_steps "$next_steps" \
        '{resource: $resource, expected: $expected, actual: $actual, details: $details, next_steps: $next_steps}' \
        >> "$DISCREPANCY_FILE"
}

# Get the list of network security groups
nsgs=$(az network nsg list --query "[].id" -o tsv)

# Iterate over each network security group
for nsg in $nsgs; do
    echo "Checking network security group: $nsg"

    # Get the current security rules
    current_rules=$(az network nsg rule list --nsg-name "$nsg" --query "[].{priority:priority, access:access, direction:direction}" -o json)

    # Compare the current rules with the expected rules
    # TODO: Replace "expected_rules" with the actual expected rules
    expected_rules='[{"priority": 100, "access": "Allow", "direction": "Inbound"}]'
    if [[ "$current_rules" != "$expected_rules" ]]; then
        echo "Discrepancy found in network security group: $nsg"
        add_discrepancy "$nsg" "$expected_rules" "$current_rules" "The current security rules do not match the expected rules." "Review the security rules for this network security group."
    fi
done

# Check if any discrepancies were found
if [[ $(jq length "$DISCREPANCY_FILE") -gt 0 ]]; then
    echo "Discrepancies found. See $DISCREPANCY_FILE for details."
    exit 1
else
    echo "No discrepancies found."
    exit 0
fi
```

This script checks the security rules of each network security group in the Azure subscription and compares them with the expected rules. If any discrepancies are found, they are added to a JSON file and the script exits with a non-zero status code.