Here is a bash script that follows the requirements and patterns shown in the reference examples:

```bash
#!/bin/bash
set -e

# File to store the detected changes
DETECTED_CHANGES_FILE="nsg_changes.json"
echo '[]' > "$DETECTED_CHANGES_FILE"

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

# Function to add detected changes to the file
add_change() {
    local change="$1"
    local details="$2"
    details=$(echo "$details" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')
    echo "[{\"change\": \"$change\", \"details\": \"$details\"}]" > "$DETECTED_CHANGES_FILE"
}

# Get the list of all NSGs
nsgs=$(az network nsg list --query "[].{name:name, resourceGroup:resourceGroup}" -o tsv)

# Loop through each NSG
while IFS=$'\t' read -r -a nsg; do
    echo "Checking NSG: ${nsg[0]} in resource group: ${nsg[1]}"

    # Get the NSG rules
    rules=$(az network nsg rule list --nsg-name "${nsg[0]}" --resource-group "${nsg[1]}" --query "[].{name:name, priority:priority}" -o tsv)

    # Loop through each rule
    while IFS=$'\t' read -r -a rule; do
        echo "Checking rule: ${rule[0]} with priority: ${rule[1]}"

        # Check if the rule priority is less than 100 (indicating a manually created rule)
        if (( rule[1] < 100 )); then
            echo "Detected manual NSG change: Rule ${rule[0]} with priority ${rule[1]} in NSG ${nsg[0]} in resource group ${nsg[1]}"
            add_change "Manual NSG Change" "Rule ${rule[0]} with priority ${rule[1]} in NSG ${nsg[0]} in resource group ${nsg[1]}"
        fi
    done <<< "$rules"
done <<< "$nsgs"

# Check if any changes were detected
if [[ $(cat "$DETECTED_CHANGES_FILE") == '[]' ]]; then
    echo "No manual NSG changes detected"
    exit 0
else
    echo "Manual NSG changes detected. See $DETECTED_CHANGES_FILE for details"
    exit 1
fi
```

This script checks all Network Security Groups (NSGs) in the specified Azure subscription for any rules with a priority less than 100, which indicates a manually created rule. If any such rules are found, they are added to a JSON file and the script exits with a non-zero status code.