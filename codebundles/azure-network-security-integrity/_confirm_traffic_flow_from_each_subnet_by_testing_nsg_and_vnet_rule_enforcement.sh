#!/bin/bash

# Check if AZURE_RESOURCE_SUBSCRIPTION_ID is set, otherwise get the current subscription ID
if [ -z "$AZURE_RESOURCE_SUBSCRIPTION_ID" ]; then
    subscription=$(az account show --query "id" -o tsv)
    echo "AZURE_RESOURCE_SUBSCRIPTION_ID is not set. Using current subscription ID: $subscription"
else
    subscription="$AZURE_RESOURCE_SUBSCRIPTION_ID"
    echo "Using specified subscription ID: $subscription"
fi

# Set the subscription to the determined ID
echo "Switching to subscription ID: $subscription"
az account set --subscription "$subscription" || { echo "Failed to set subscription."; exit 1; }

# Initialize issues JSON
issues_json='{"issues": []}'


# Check Network Security Groups
echo "Checking NSG configuration..."
NSG_LIST=$(az network nsg list --resource-group "$AZ_RESOURCE_GROUP" -o json)

if [ -z "$NSG_LIST" ] || [ "$NSG_LIST" = "[]" ]; then
    issues_json=$(echo "$issues_json" | jq \
        --arg title "No NSG Found" \
        --arg details "No Network Security Groups found in resource group $AZ_RESOURCE_GROUP" \
        --arg severity "2" \
        '.issues += [{"title": $title, "details": $details, "severity": ($severity | tonumber)}]')
else
    echo "Found NSGs: $(echo "$NSG_LIST" | jq -r '.[].name' | tr '\n' ' ')"
fi


# Output results
echo "$issues_json" > "$OUTPUT_DIR/results.json"
cat "$OUTPUT_DIR/results.json"
