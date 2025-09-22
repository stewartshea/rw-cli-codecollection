Here is a bash script for the task "Detect Manual NSG Changes":

```bash
#!/bin/bash
set -euo pipefail

# Environment variables
SUBSCRIPTION_ID=${AZURE_SUBSCRIPTION_ID:-}
RESOURCE_GROUP=${AZ_RESOURCE_GROUP:-}
NSG_NAME=${NSG_NAME:-}

ISSUES_FILE="nsg_changes_issues.json"
echo '[]' > "$ISSUES_FILE"

add_issue() {
    local title="$1"
    local severity="$2"
    local details="$3"
    local next_steps="$4"
    
    # Escape JSON characters properly
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

# Set the subscription to the determined ID
echo "Switching to subscription ID: $SUBSCRIPTION_ID"
az account set --subscription "$SUBSCRIPTION_ID"

# Get the current NSG rules
echo "Getting current NSG rules for $NSG_NAME in $RESOURCE_GROUP"
current_rules=$(az network nsg rule list --resource-group "$RESOURCE_GROUP" --nsg-name "$NSG_NAME" --output json)

# Compare the current rules with the expected rules
echo "Comparing current NSG rules with expected rules"
expected_rules=$(cat "expected_nsg_rules.json")
if [ "$current_rules" != "$expected_rules" ]; then
    echo "Detected manual changes in NSG rules"
    add_issue "Manual NSG Changes Detected" "High" "The current NSG rules do not match the expected rules. Manual changes may have been made." "Review the current NSG rules and revert any unauthorized changes."
else
    echo "No manual changes detected in NSG rules"
fi

# Print the issues file
cat "$ISSUES_FILE"

# Exit with a non-zero status if issues were found
if [ "$(jq '. | length' "$ISSUES_FILE")" -gt 0 ]; then
    exit 1
fi
```

This script follows the patterns shown in the reference examples and includes proper error handling and logging. It uses the Azure CLI to get the current Network Security Group (NSG) rules and compares them with the expected rules. If there is a difference, it adds an issue to the issues file. The script returns a non-zero exit code if any issues were found.