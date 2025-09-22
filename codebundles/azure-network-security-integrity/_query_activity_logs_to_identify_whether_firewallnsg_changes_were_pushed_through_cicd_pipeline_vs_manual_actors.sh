Here is a bash script that meets your requirements:

```bash
#!/bin/bash
set -euo pipefail

# Output file for the activity logs
ACTIVITY_LOGS_OUTPUT="activity_logs.json"
echo "[]" > "$ACTIVITY_LOGS_OUTPUT"

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

# Query activity logs for firewall/NSG changes
echo "Querying activity logs for firewall/NSG changes..."
activity_logs=$(az monitor activity-log list --query "[?contains(authorization.scope, '/firewalls/') || contains(authorization.scope, '/networkSecurityGroups/')]" -o json)

# Check if activity logs are empty
if [[ -z "$activity_logs" ]]; then
    echo "No activity logs found for firewall/NSG changes."
    exit 0
fi

# Save activity logs to output file
echo "$activity_logs" > "$ACTIVITY_LOGS_OUTPUT"
echo "Activity logs saved to $ACTIVITY_LOGS_OUTPUT"

# Identify whether changes were pushed through CI/CD pipeline vs. manual actors
echo "Identifying source of changes..."
ci_cd_changes=$(jq '.[] | select(.claims.xms_mirid | contains("/providers/Microsoft.DevOps/"))' "$ACTIVITY_LOGS_OUTPUT")
manual_changes=$(jq '.[] | select(.claims.xms_mirid | contains("/providers/Microsoft.ManagedIdentity/"))' "$ACTIVITY_LOGS_OUTPUT")

# Print results
if [[ -n "$ci_cd_changes" ]]; then
    echo "Changes pushed through CI/CD pipeline:"
    echo "$ci_cd_changes"
fi

if [[ -n "$manual_changes" ]]; then
    echo "Changes made by manual actors:"
    echo "$manual_changes"
fi

exit 0
```

This script queries the Azure activity logs for changes to firewalls and network security groups. It then identifies whether these changes were made by a CI/CD pipeline or by manual actors. The results are printed to the console and saved to a JSON file.