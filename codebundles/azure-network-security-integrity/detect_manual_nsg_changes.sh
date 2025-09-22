Here is a bash script that detects manual changes in Network Security Groups (NSG) in Azure:

```bash
#!/bin/bash
set -euo pipefail

# File to store the detected issues
ISSUES_FILE="nsg_changes_issues.json"
echo '[]' > "$ISSUES_FILE"

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

# Function to add issue to the issues file
add_issue() {
    local title="$1"
    local severity="$2"
    local details="$3"
    local next_steps="$4"
    details=$(echo "$details" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')
    next_steps=$(echo "$next_steps" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')
    issue="{\"title\": \"$title\", \"severity\": \"$severity\", \"details\": \"$details\", \"next_steps\": \"$next_steps\"}"
    temp=$(mktemp)
    jq ". += [$issue]" "$ISSUES_FILE" > "$temp" && mv "$temp" "$ISSUES_FILE"
}

# Get all NSGs
nsgs=$(az network nsg list --query "[].{name:name, resourceGroup:resourceGroup}" -o tsv)

# Loop through each NSG and check for changes
while IFS=$'\t' read -r -a nsg; do
    name=${nsg[0]}
    resourceGroup=${nsg[1]}
    echo "Checking NSG: $name in resource group: $resourceGroup"

    # Get NSG rules
    rules=$(az network nsg rule list --nsg-name "$name" --resource-group "$resourceGroup" --query "[].{name:name, priority:priority, access:access, direction:direction}" -o tsv)

    # Loop through each rule and check for manual changes
    while IFS=$'\t' read -r -a rule; do
        ruleName=${rule[0]}
        rulePriority=${rule[1]}
        ruleAccess=${rule[2]}
        ruleDirection=${rule[3]}

        # Check if rule has been manually changed
        # Add your own logic here to detect manual changes
        # For example, you might check if the rule's priority is not what you expect
        if [[ "$rulePriority" -ne 100 ]]; then
            add_issue "Manual NSG Rule Change Detected" "High" "Rule $ruleName in NSG $name has been manually changed. Expected priority: 100, Actual priority: $rulePriority." "Review the NSG rule and revert the changes if necessary."
        fi
    done <<< "$rules"
done <<< "$nsgs"

# Print issues
cat "$ISSUES_FILE"

# Exit with non-zero status if issues were found
if [[ $(jq '. | length' "$ISSUES_FILE") -gt 0 ]]; then
    exit 1
fi
```

This script first gets the list of all NSGs in the subscription. Then, for each NSG, it gets the list of all rules and checks if any rule has been manually changed. If a manual change is detected, an issue is added to the issues file. At the end, if any issues were found, the script exits with a non-zero status.