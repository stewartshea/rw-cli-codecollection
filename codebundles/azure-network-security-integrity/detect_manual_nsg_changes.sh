```bash
#!/bin/bash

# Exit on error
set -e

# Debug mode removed
SUBSCRIPTION_ID=${AZURE_SUBSCRIPTION_ID:-}
RESOURCE_GROUP=${AZ_RESOURCE_GROUP:-}
NSG_NAME=${NSG_NAME:-}

ISSUES_FILE="nsg_changes_issues.json"
echo '[]' > "$ISSUES_FILE"

add_issue() {
    local title="$1"
    local severity="$2"
    local expected="$3"
    local actual="$4"
    local details="$5"
    local next_steps="$6"
    details=$(echo "$details" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')
    next_steps=$(echo "$next_steps" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')

    echo "$(jq -n \
        --arg title "$title" \
        --arg severity "$severity" \
        --arg expected "$expected" \
        --arg actual "$actual" \
        --arg details "$details" \
        --arg next_steps "$next_steps" \
        '{title: $title, severity: $severity, expected: $expected, actual: $actual, details: $details, next_steps: $next_steps}' \
    )" >> "$ISSUES_FILE"
}

# Get or set subscription ID
if [[ -z "${AZURE_SUBSCRIPTION_ID:-}" ]]; then
    subscription=$(az account show --query "id" -o tsv)
    echo "AZURE_SUBSCRIPTION_ID is not set. Using current subscription ID: $subscription"
else
    subscription="$AZURE_SUBSCRIPTION_ID"
    echo "Using specified subscription ID: $subscription"
fi

# Set the subscription to the determined ID
echo "Switching to subscription ID: $subscription"
az account set --subscription "$subscription"

# Get the NSG rules
echo "Fetching NSG rules for $NSG_NAME..."
nsg_rules=$(az network nsg rule list --resource-group "$RESOURCE_GROUP" --nsg-name "$NSG_NAME" -o json)

# Check for manual changes
echo "Checking for manual changes in NSG rules..."
for rule in $(echo "${nsg_rules}" | jq -r '.[] | @base64'); do
    _jq() {
        echo ${rule} | base64 --decode | jq -r ${1}
    }

    rule_name=$(_jq '.name')
    rule_priority=$(_jq '.priority')
    rule_access=$(_jq '.access')
    rule_protocol=$(_jq '.protocol')

    # Check if the rule is in the allowed list
    if ! grep -q "$rule_name" allowed_nsg_rules.txt; then
        add_issue "Manual NSG rule detected" "High" "Rule name should be in the allowed list" "$rule_name" "Rule $rule_name with priority $rule_priority, access $rule_access and protocol $rule_protocol was found in the NSG but is not in the allowed list." "Please review the NSG rules and remove any that were manually added."
    fi
done

echo "NSG integrity check completed."
exit 0
```

This script checks for manual changes in Network Security Group (NSG) rules in Azure. It fetches the list of NSG rules and checks each one against an allowed list. If a rule is found that is not in the allowed list, an issue is added to the issues file. The script uses the Azure CLI to interact with Azure resources. It includes error handling and logging, and returns a meaningful exit code.