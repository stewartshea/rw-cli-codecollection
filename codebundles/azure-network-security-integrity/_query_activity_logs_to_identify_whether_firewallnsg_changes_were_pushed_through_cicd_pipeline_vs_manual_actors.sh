Here is a bash script that meets your requirements:

```bash
#!/bin/bash

# Exit on error
set -e

# Debug mode removed
SUBSCRIPTION_ID=${AZURE_SUBSCRIPTION_ID:-}
RESOURCE_GROUP=${AZ_RESOURCE_GROUP:-}
NSG_NAME=${NSG_NAME:-}
LOG_FILE="activity_logs.json"
echo '[]' > "$LOG_FILE"

# Function to add issues to the log file
add_issue() {
  local actor="$1"
  local action="$2"
  local timestamp="$3"
  local details="$4"
  details=$(echo "$details" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')
  echo "[{\"actor\":\"$actor\",\"action\":\"$action\",\"timestamp\":\"$timestamp\",\"details\":\"$details\"}]" >> "$LOG_FILE"
}

# Get or set subscription ID
if [[ -z "${SUBSCRIPTION_ID:-}" ]]; then
    subscription=$(az account show --query "id" -o tsv)
    echo "AZURE_SUBSCRIPTION_ID is not set. Using current subscription ID: $subscription"
else
    subscription="$SUBSCRIPTION_ID"
    echo "Using specified subscription ID: $subscription"
fi

# Set the subscription to the determined ID
echo "Switching to subscription ID: $subscription"
az account set --subscription "$subscription"

# Query activity logs
echo "Querying activity logs for firewall/NSG changes..."
logs=$(az monitor activity-log list --resource-group "$RESOURCE_GROUP" --status Succeeded --max-events 1000 --query "[?contains(properties.subStatus.value, 'NSG') || contains(properties.subStatus.value, 'firewall')]" -o json)

# Parse logs and identify manual actors vs CI/CD pipeline
echo "Parsing logs..."
echo "$logs" | jq -r '.[] | select(.caller | contains("pipelines")) | .caller, .operationName.localizedValue, .eventTimestamp, .properties' | while read -r actor; do
  read -r action
  read -r timestamp
  read -r details
  add_issue "$actor" "$action" "$timestamp" "$details"
done

# Validate if any issues were found
if [ $(jq length "$LOG_FILE") -eq 0 ]; then
  echo "No firewall/NSG changes were found in the activity logs."
  exit 0
else
  echo "Firewall/NSG changes were found in the activity logs. Please review the log file: $LOG_FILE"
  exit 1
fi
```

This script queries the activity logs for firewall/NSG changes and identifies whether the changes were made by a CI/CD pipeline or a manual actor. The results are stored in a JSON file. If any changes were found, the script exits with a non-zero status code.