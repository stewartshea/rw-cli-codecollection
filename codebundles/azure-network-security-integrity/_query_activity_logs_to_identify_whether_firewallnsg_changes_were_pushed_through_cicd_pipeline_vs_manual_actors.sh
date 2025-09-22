Here is a bash script that meets your requirements:

```bash
#!/bin/bash
set -euo pipefail

# Script to query activity logs to identify whether firewall/NSG changes were pushed through CI/CD pipeline vs. manual actors

# Environment variables
SUBSCRIPTION_ID=${AZURE_SUBSCRIPTION_ID:-}
RESOURCE_GROUP=${AZ_RESOURCE_GROUP:-}
ACTIVITY_LOG_FILE="activity_log.json"
echo '[]' > "$ACTIVITY_LOG_FILE"

# Function to add issue to the log file
add_issue() {
    local title="$1"
    local severity="$2"
    local expected="$3"
    local actual="$4"
    local details="$5"
    local next_steps="$6"
    local reproduce_hint="$7"
    
    # Escape JSON characters properly
    details=$(echo "$details" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')
    next_steps=$(echo "$next_steps" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')
    reproduce_hint=$(echo "$reproduce_hint" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')

    # Add issue to the log file
    jq -n --arg title "$title" --arg severity "$severity" --arg expected "$expected" --arg actual "$actual" --arg details "$details" --arg next_steps "$next_steps" --arg reproduce_hint "$reproduce_hint" \
    '{title: $title, severity: $severity, expected: $expected, actual: $actual, details: $details, next_steps: $next_steps, reproduce_hint: $reproduce_hint}' >> "$ACTIVITY_LOG_FILE"
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

# Query activity logs
echo "Querying activity logs for firewall/NSG changes..."
activity_logs=$(az monitor activity-log list --resource-group "$RESOURCE_GROUP" --query "[?contains(properties.subStatus.value, 'firewall') || contains(properties.subStatus.value, 'NSG')]" -o json)

# Check if activity logs are empty
if [ -z "$activity_logs" ]; then
    echo "No firewall/NSG changes found in activity logs."
    exit 0
fi

# Check if changes were pushed through CI/CD pipeline vs. manual actors
echo "Checking if changes were pushed through CI/CD pipeline vs. manual actors..."
for log in "${activity_logs[@]}"; do
    if [[ "$log" =~ "CI/CD" ]]; then
        echo "Change pushed through CI/CD pipeline: $log"
    else
        echo "Manual change detected: $log"
        add_issue "Manual change detected" "High" "Changes should be pushed through CI/CD pipeline" "Change was made manually" "$log" "Investigate the manual change and revert if necessary" "Check the activity log for details"
    fi
done

echo "Script completed successfully."
exit 0
```

This script queries the Azure activity logs for firewall and Network Security Group (NSG) changes. It then checks if these changes were pushed through a CI/CD pipeline or made manually. If a manual change is detected, it is added to the activity log file as an issue.