Here is a bash script for the task "Detect Manual NSG Changes" following the patterns shown in the reference examples:

```bash
#!/bin/bash
set -euo pipefail

# File to store detected issues
ISSUES_FILE="nsg_changes_issues.json"
echo '[]' > "$ISSUES_FILE"

# Environment variables
SUBSCRIPTION_ID=${AZURE_SUBSCRIPTION_ID:-}
RESOURCE_GROUP=${AZ_RESOURCE_GROUP:-}
NSG_NAME=${NSG_NAME:-}

# Function to add issues to the issues file
add_issue() {
    local title="$1"
    local severity="$2"
    local details="$3"
    local next_steps="$4"
    
    # Escape JSON characters properly
    details=$(echo "$details" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')
    next_steps=$(echo "$next_steps" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')
    
    # Add issue to the issues file
    echo "$(jq --arg title "$title" --arg severity "$severity" --arg details "$details" --arg next_steps "$next_steps" '. += [{title: $title, severity: $severity, details: $details, next_steps: $next_steps}]' "$ISSUES_FILE")" > "$ISSUES_FILE"
}

# Get or set subscription ID
if [[ -z "${SUBSCRIPTION_ID:-}" ]]; then
    SUBSCRIPTION_ID=$(az account show --query "id" -o tsv)
    echo "AZURE_SUBSCRIPTION_ID is not set. Using current subscription ID: $SUBSCRIPTION_ID"
else
    echo "Using specified subscription ID: $SUBSCRIPTION_ID"
fi

# Set the subscription to the determined ID
echo "Switching to subscription ID: $SUBSCRIPTION_ID"
az account set --subscription "$SUBSCRIPTION_ID"

# Get the current NSG rules
echo "Getting current NSG rules..."
CURRENT_NSG_RULES=$(az network nsg rule list --resource-group "$RESOURCE_GROUP" --nsg-name "$NSG_NAME" -o json)

# Compare the current NSG rules with the expected rules
echo "Comparing current NSG rules with expected rules..."
EXPECTED_NSG_RULES=$(cat expected_nsg_rules.json)
if [[ "$CURRENT_NSG_RULES" != "$EXPECTED_NSG_RULES" ]]; then
    echo "Detected manual changes in NSG rules"
    add_issue "Manual changes detected in NSG rules" "High" "The current NSG rules do not match the expected rules. Manual changes may have been made." "Review the current NSG rules and revert any unauthorized changes."
else
    echo "No manual changes detected in NSG rules"
fi

# Exit with a non-zero status code if issues were detected
if [[ $(jq 'length' "$ISSUES_FILE") -gt 0 ]]; then
    echo "Issues detected. Exiting with status code 1."
    exit 1
fi

echo "No issues detected. Exiting with status code 0."
exit 0
```

This script gets the current NSG rules and compares them with the expected rules. If they do not match, it adds an issue to the issues file and exits with a non-zero status code. The expected NSG rules should be stored in a file named `expected_nsg_rules.json` in the same directory as this script.