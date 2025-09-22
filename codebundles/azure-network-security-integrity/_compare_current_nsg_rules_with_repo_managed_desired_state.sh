```bash
#!/bin/bash
set -euo pipefail

# Environment variables
SUBSCRIPTION_ID=${AZURE_SUBSCRIPTION_ID:-}
RESOURCE_GROUP=${AZ_RESOURCE_GROUP:-}
NSG_NAME=${NSG_NAME:-}
REPO_NSG_RULES_FILE=${REPO_NSG_RULES_FILE:-}

# File to store current NSG rules
CURRENT_NSG_RULES_FILE="current_nsg_rules.json"

# File to store integrity issues
ISSUES_FILE="nsg_integrity_issues.json"
echo '[]' > "$ISSUES_FILE"

add_issue() {
    local title="$1"
    local severity="$2"
    local expected="$3"
    local actual="$4"
    local details="$5"
    local next_steps="$6"
    
    # Escape JSON characters properly
    details=$(echo "$details" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')
    next_steps=$(echo "$next_steps" | sed 's/"/\\"/g' | sed ':a;N;$!ba;s/\n/\\n/g')
    
    # Add issue to the issues file
    echo "$(jq -n \
            --arg title "$title" \
            --arg severity "$severity" \
            --arg expected "$expected" \
            --arg actual "$actual" \
            --arg details "$details" \
            --arg next_steps "$next_steps" \
            '{title: $title, severity: $severity, expected: $expected, actual: $actual, details: $details, next_steps: $next_steps}' \
            | jq --slurp '. + input' "$ISSUES_FILE" > tmp && mv tmp "$ISSUES_FILE")"
}

# Get current NSG rules
echo "Fetching current NSG rules..."
az network nsg rule list --resource-group "$RESOURCE_GROUP" --nsg-name "$NSG_NAME" > "$CURRENT_NSG_RULES_FILE"

# Compare current NSG rules with repo-managed desired state
echo "Comparing current NSG rules with repo-managed desired state..."
diff=$(diff -q "$CURRENT_NSG_RULES_FILE" "$REPO_NSG_RULES_FILE") || true

if [ -n "$diff" ]; then
    echo "Integrity check failed. NSG rules do not match with repo-managed desired state."
    add_issue "NSG rules integrity check failed" "high" "NSG rules should match with repo-managed desired state" "NSG rules do not match with repo-managed desired state" "$diff" "Please update the NSG rules to match with the repo-managed desired state"
    exit 1
else
    echo "Integrity check passed. NSG rules match with repo-managed desired state."
fi

exit 0
```

This script fetches the current Network Security Group (NSG) rules using Azure CLI and compares them with the desired state stored in a file in the repository. If there is a difference, it logs the issue and exits with a non-zero status code.