Here is a bash script that meets your requirements:

```bash
#!/bin/bash
set -euo pipefail

# Environment variables
SUBSCRIPTION_ID=${AZURE_SUBSCRIPTION_ID:-}
RESOURCE_GROUP=${AZ_RESOURCE_GROUP:-}
ACTIVITY_LOGS_FILE="activity_logs.json"
echo '[]' > "$ACTIVITY_LOGS_FILE"

# Function to add issue to the issues file
add_issue() {
    local title="$1"
    local severity="$2"
    local details="$3"
    local next_steps="$4"
    
    # Escape JSON characters properly
    details=$(echo "$details" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')
    next_steps=$(echo "$next_steps" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')

    echo "$(jq -n \
        --arg title "$title" \
        --arg severity "$severity" \
        --arg details "$details" \
        --arg next_steps "$next_steps" \
        '{title: $title, severity: $severity, details: $details, next_steps: $next_steps}' \
        )" >> "$ACTIVITY_LOGS_FILE"
}

# Function to query activity logs
query_activity_logs() {
    echo "Querying activity logs for firewall/NSG changes..."

    # Query activity logs for firewall/NSG changes
    activity_logs=$(az monitor activity-log list \
        --resource-group "$RESOURCE_GROUP" \
        --subscription "$SUBSCRIPTION_ID" \
        --query "[?contains(properties.subStatus.value, 'firewall') || contains(properties.subStatus.value, 'NSG')]" \
        --output json)

    if [ -z "$activity_logs" ]; then
        echo "No firewall/NSG changes found in activity logs."
        exit 0
    fi

    echo "Firewall/NSG changes found in activity logs."

    # Check if changes were pushed through CI/CD pipeline
    echo "Checking if changes were pushed through CI/CD pipeline..."

    for log in $activity_logs; do
        if [[ $log =~ "CI/CD" ]]; then
            echo "Change pushed through CI/CD pipeline: $log"
        else
            echo "Manual change detected: $log"
            add_issue "Manual firewall/NSG change detected" "High" "A manual change to the firewall/NSG was detected in the activity logs." "Review the activity logs and ensure that all changes are being pushed through the CI/CD pipeline."
        fi
    done
}

# Main function
main() {
    # Check if AZURE_SUBSCRIPTION_ID is set
    if [ -z "$SUBSCRIPTION_ID" ]; then
        echo "AZURE_SUBSCRIPTION_ID is not set. Exiting..."
        exit 1
    fi

    # Check if AZ_RESOURCE_GROUP is set
    if [ -z "$RESOURCE_GROUP" ]; then
        echo "AZ_RESOURCE_GROUP is not set. Exiting..."
        exit 1
    fi

    # Query activity logs
    query_activity_logs
}

# Run main function
main
```

This script queries the Azure activity logs for any changes to firewalls or network security groups (NSGs). It then checks if these changes were pushed through a CI/CD pipeline or made manually. If a manual change is detected, it adds an issue to a JSON file. The script follows the patterns shown in the reference examples and includes proper error handling and logging. It uses the Azure CLI to interact with the Azure platform.