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


# Task: Flag discrepancies that indicate out-of-band changes
echo "Executing task: Flag discrepancies that indicate out-of-band changes"

# Add your specific Azure CLI commands here
# Example: az resource list --resource-group "$AZ_RESOURCE_GROUP"

echo "Task completed: Flag discrepancies that indicate out-of-band changes"


# Output results
echo "$issues_json" > "$OUTPUT_DIR/results.json"
cat "$OUTPUT_DIR/results.json"
