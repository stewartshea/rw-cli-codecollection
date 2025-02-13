#!/bin/bash

# -----------------------------------------------------------------------------
# Script Information and Metadata
# -----------------------------------------------------------------------------
# Author: @stewartshea
# Description: This script takes in event message strings captured from a 
# Kubernetes based system and provides more concrete issue details in json format. This is a migration away from workload_next_steps.sh in order to support dynamic severity generation and more robust next step details. 
# -----------------------------------------------------------------------------
# Input: List of event messages, related owner kind, and related owner name
messages="$1"
owner_kind="$2"  
owner_name="$3"

issue_details_array=()

add_issue() {
    local severity=$1
    local title=$2
    local details=$3
    local next_steps=$4
    issue_details="{\"severity\":\"$severity\",\"title\":\"$title\",\"details\":\"$details\",\"next_steps\":\"$next_steps\"}"
    issue_details_array+=("$issue_details")
}

# Check conditions and add issues to the array
if echo "$messages" | grep -q "ContainersNotReady" && [[ $owner_kind == "Deployment" ]]; then
    add_issue "2" "$owner_kind \`$owner_name\` has unready containers" "$messages" "Inspect Deployment Replicas for \`$owner_name\`"
fi

if echo "$messages" | grep -q "Misconfiguration" && [[ $owner_kind == "Deployment" ]]; then
    add_issue "2" "$owner_kind \`$owner_name\` has a misconfiguration" "$messages" "Check Deployment Log For Issues for \`$owner_name\`\nGet Deployment Workload Details For \`$owner_name\` and Add to Report"
fi

if echo "$messages" | grep -q "PodInitializing"; then
    add_issue "4" "$owner_kind \`$owner_name\` is initializing" "$messages" "Retry in a few minutes and verify that \`$owner_name\` is running.\nInspect $owner_kind Warning Events for \`$owner_name\`"
fi

if echo "$messages" | grep -q "Startup probe failed"; then
    add_issue "2" "$owner_kind \`$owner_name\` is unable to start" "$messages" "Check Deployment Logs for $owner_kind \`$owner_name\`\nReview Startup Probe Configuration for $owner_kind \`$owner_name\`\nIncrease Startup Probe Timeout and Threshold for $owner_kind \`$owner_name\`\nIdentify Resource Constrained Pods In Namespace \`$NAMESPACE\`"
fi

if echo "$messages" | grep -q "Liveness probe failed\|Liveness probe errored"; then
    add_issue "3" "$owner_kind \`$owner_name\` is restarting" "$messages" "Check Liveliness Probe Configuration for $owner_kind \`$owner_name\`"
fi

if echo "$messages" | grep -q "Readiness probe errored\|Readiness probe failed"; then
    add_issue "2" "$owner_kind \`$owner_name\` is unable to start" "$messages" "Check Readiness Probe Configuration for $owner_kind \`$owner_name\`"
fi

if echo "$messages" | grep -q "PodFailed"; then
    add_issue "2" "$owner_kind \`$owner_name\` has failed pods" "$messages" "Check Pod Status and Logs for Errors"
fi

if echo "$messages" | grep -q "ImagePullBackOff\|Back-off pulling image\|ErrImagePull"; then
    add_issue "2" "$owner_kind \`$owner_name\` has image access issues" "$messages" "List Images and Tags for Every Container in Failed Pods for Namespace \`$NAMESPACE\`\nList ImagePullBackoff Events and Test Path and Tags for Namespace \`$NAMESPACE\`"
fi

if echo "$messages" | grep -q "Back-off restarting failed container"; then
    add_issue "2" "$owner_kind \`$owner_name\` has failing containers" "$messages" "Check $owner_kind Log for \`$owner_name\`\nInspect Warning Events for $owner_kind \`$owner_name\`"
fi

if echo "$messages" | grep -q "forbidden: failed quota\|forbidden: exceeded quota"; then
    add_issue "3" "$owner_kind \`$owner_name\` has resources that cannot be scheduled" "$messages" "Adjust resource configuration for $owner_kind \`$owner_name\` according to issue details."
fi

if echo "$messages" | grep -q "is forbidden: \[minimum cpu usage per Container\|is forbidden: \[minimum memory usage per Container"; then
    add_issue "2" "$owner_kind \`$owner_name\` has invalid resource configuration" "$messages" "Adjust resource configuration for $owner_kind \`$owner_name\` according to issue details."
fi

if echo "$messages" | grep -q "No preemption victims found for incoming pod\|Insufficient cpu\|The node was low on resource\|nodes are available\|Preemption is not helpful"; then
    add_issue "2" "$owner_kind \`$owner_name\` cannot be scheduled - not enough cluster resources." "$messages" "Not enough node resources available to schedule pods. Escalate this issue to your cluster owner.\nIncrease Node Count in Cluster\nCheck for Quota Errors\nIdentify High Utilization Nodes for Cluster \`${CONTEXT}\`"
fi

if echo "$messages" | grep -q "max node group size reached"; then
    add_issue "2" "$owner_kind \`$owner_name\` cannot be scheduled - cannot increase cluster size." "$messages" "Not enough node resources available to schedule pods. Escalate this issue to your cluster owner.\nIncrease Max Node Group Size in Cluster\nIdentify High Utilization Nodes for Cluster \`${CONTEXT}\`"
fi

if echo "$messages" | grep -q "Health check failed after"; then
    add_issue "3" "$owner_kind \`$owner_name\` health check failed." "$messages" "Check $owner_kind \`$owner_name\` Health"
fi

if echo "$messages" | grep -q "Deployment does not have minimum availability"; then
    add_issue "3" "$owner_kind \`$owner_name\` is not available." "$messages" "Inspect Deployment Warning Events for \`$owner_name\`"
fi

if echo "$messages" | grep -q "failed to download archive"; then
    add_issue "3" "$owner_kind \`$owner_name\` has internal connectivity issues fetching source" "$messages" "Escalate connectivity issues to service owner if they continue."
fi

if echo "$messages" | grep -q "OCI runtime exec failed: exec failed: unable to start container process"; then
    add_issue "2" "Possible node or container runtime issue" "$messages" "Escalate container runtime issue to service owner if they continue."
fi


# Ignore normal messages that should not trigger an issue

if echo "$messages" | grep -q "Created container server\|no changes since last reconcilation\|Reconciliation finished\|successfully rotated K8s secret"; then
    echo "[]" | jq .
    exit 0
fi

if echo "$messages" | grep -qE "Created container|Successfully assigned|Successfully pulled image|Pulling image|Stopping container|Started container|deleting pod for node scale down"; then
    echo "[]" | jq .
    exit 0
fi


if echo "$messages" | grep -q "connect: connection refused"; then
    add_issue "3" "Internal connectivity issues detected" "$messages" "Escalate connectivity issues to service owner if they continue."
fi

### These are ChatGPT Generated and will require tuning. Please migrate above this line when tuned. 
## Removed for now - they were getting wildly off-base
### End of auto-generated message strings

if [ ${#issue_details_array[@]} -gt 0 ]; then
    issues_json=$(printf "%s," "${issue_details_array[@]}")
    issues_json="[${issues_json%,}]" # Remove the last comma and wrap in square brackets
    echo "$issues_json" | jq .
else
    echo "[{\"severity\":\"4\",\"title\":\"$owner_kind \`$owner_name\` has issues that require further investigation.\",\"details\":\"$messages\",\"next_steps\":\"Escalate issues for $owner_kind \`$owner_name\` to service owner \"}]" | jq .
fi
