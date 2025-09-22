Here is a bash script that follows the requirements and patterns shown in the reference examples:

```bash
#!/bin/bash
set -euo pipefail

# Define output file for potential issues
ISSUES_FILE="nsg_firewall_issues.json"
echo '[]' > "$ISSUES_FILE"

# Function to add an issue to the issues file
add_issue() {
  local title="$1"
  local severity="$2"
  local details="$3"
  local next_steps="$4"
  details=$(echo "$details" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')
  next_steps=$(echo "$next_steps" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')
  echo "$(jq -n --arg title "$title" --arg severity "$severity" --arg details "$details" --arg next_steps "$next_steps" \
    '{title: $title, severity: $severity, details: $details, next_steps: $next_steps}' | \
    jq --argjson new_issue '.' ". += [$new_issue]")" > "$ISSUES_FILE"
}

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
logs=$(az monitor activity-log list --query "[?contains(authorization.scope, '/firewalls/') || contains(authorization.scope, '/networkSecurityGroups/')]" -o json)

# Parse logs and identify whether changes were pushed through CI/CD pipeline vs. manual actors
echo "Analyzing logs..."
echo "$logs" | jq -r '.[] | select(.claims.xms_mirid | contains("/providers/Microsoft.ManagedIdentity/")) | .caller' | sort | uniq -c | while read -r count caller; do
  if [[ "$caller" != "systemAssignedIdentity" ]]; then
    add_issue "Potential manual firewall/NSG changes" "High" "Caller '$caller' made $count firewall/NSG changes" "Investigate the changes made by '$caller'"
  fi
done

# Print out the issues file
cat "$ISSUES_FILE"
```

This script queries the Azure activity logs for changes to firewalls or network security groups (NSGs). It then analyzes the logs to identify whether the changes were made by a system-assigned managed identity (which would typically indicate changes pushed through a CI/CD pipeline) or by a different caller (which could indicate manual changes). If it identifies potential manual changes, it adds an issue to the issues file with details about the caller and the number of changes they made.