Here's a bash script to detect manual NSG (Network Security Group) changes in Azure:

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

# Function to add issues to the issues file
add_issue() {
    local title="$1"
    local severity="$2"
    local details="$3"
    local next_steps="$4"
    
    # Escape JSON characters properly
    details=$(echo "$details" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')
    next_steps=$(echo "$next_steps" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')
    
    # Add the issue to the issues file
    echo "$(jq --arg title "$title" --arg severity "$severity" --arg details "$details" --arg next_steps "$next_steps" '. += [{"title": $title, "severity": $severity, "details": $details, "next_steps": $next_steps}]' "$ISSUES_FILE")" > "$ISSUES_FILE"
}

# Get the list of NSGs
nsgs=$(az network nsg list --query "[].{name:name, resourceGroup:resourceGroup}" -o tsv)

# Loop through each NSG and check for manual changes
while IFS=$'\t' read -r -a nsg; do
    echo "Checking NSG: ${nsg[0]} in resource group: ${nsg[1]}"
    
    # Get the NSG rules
    rules=$(az network nsg rule list --nsg-name "${nsg[0]}" --resource-group "${nsg[1]}" --query "[].{name:name, description:description}" -o tsv)
    
    # Loop through each rule and check for manual changes
    while IFS=$'\t' read -r -a rule; do
        if [[ "${rule[1]}" != *"Automated"* ]]; then
            echo "Manual change detected in rule: ${rule[0]} of NSG: ${nsg[0]}"
            add_issue "Manual change detected in NSG" "High" "Rule: ${rule[0]} of NSG: ${nsg[0]} in resource group: ${nsg[1]} has been manually changed." "Please review the change and update the automation scripts if necessary."
        fi
    done <<< "$rules"
done <<< "$nsgs"

# Check if any issues were detected
if [[ $(jq 'length' "$ISSUES_FILE") -gt 0 ]]; then
    echo "Issues detected. Please review the issues file: $ISSUES_FILE"
    exit 1
else
    echo "No issues detected."
    exit 0
fi
```

This script first sets the Azure subscription, then retrieves a list of all NSGs in the subscription. It loops through each NSG and its rules, checking if the description of each rule does not contain the word "Automated", which is used as an indicator of manual changes. If a manual change is detected, it adds an issue to the issues file. At the end, it checks if any issues were detected and exits with an appropriate exit code.