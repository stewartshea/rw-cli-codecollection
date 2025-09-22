Here is a bash script that meets your requirements:

```bash
#!/bin/bash
set -euo pipefail

# Define output file
ACTIVITY_LOGS="activity_logs.json"
echo "[]" > "$ACTIVITY_LOGS"

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

# Define the query to fetch only firewall and NSG changes
query='eventTimestamp ge 2022-01-01 and (resourceType eq "MICROSOFT.NETWORK/NETWORKSECURITYGROUPS" or resourceType eq "MICROSOFT.NETWORK/AZUREFIREWALLS") and (operationName eq "Microsoft.Network/networkSecurityGroups/write" or operationName eq "Microsoft.Network/azureFirewalls/write")'

# Fetch the activity logs
echo "Fetching activity logs..."
az monitor activity-log list --query "$query" -o json > "$ACTIVITY_LOGS"

# Analyze the logs to identify the changes made through CI/CD pipeline vs. manual
echo "Analyzing activity logs..."
ci_cd_changes=$(jq '.[] | select(.caller =~ /vsts/) | .caller' "$ACTIVITY_LOGS" | wc -l)
manual_changes=$(jq '.[] | select(.caller !~ /vsts/) | .caller' "$ACTIVITY_LOGS" | wc -l)

echo "Number of changes made through CI/CD pipeline: $ci_cd_changes"
echo "Number of changes made manually: $manual_changes"

# If there are any manual changes, exit with an error code
if [[ $manual_changes -gt 0 ]]; then
    echo "ERROR: There were $manual_changes manual changes made to firewall/NSG. Please investigate."
    exit 1
fi

echo "No manual changes were made to firewall/NSG. Everything looks good."
exit 0
```

This script first sets the Azure subscription ID, either from an environment variable or from the current subscription. It then fetches the activity logs for firewall and NSG changes. The logs are analyzed to identify the changes made through the CI/CD pipeline (identified by the caller containing "vsts") and the changes made manually (identified by the caller not containing "vsts"). If there are any manual changes, the script exits with an error code. Otherwise, it exits successfully.