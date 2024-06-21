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

declare -A issue_titles
declare -A issue_details
declare -A issue_next_steps

# Function to calculate the Levenshtein distance between two strings
levenshtein() {
    if [ "$1" == "$2" ]; then
        echo 0
        return
    fi

    local str1len=$((${#1} + 1))
    local str2len=$((${#2} + 1))

    for ((i = 0; i < str1len; i++)); do
        costs[$i]=i
    done

    for ((j = 1; j < str2len; j++)); do
        costs[0]=$j
        local nw=$((j - 1))
        for ((i = 1; i < str1len; i++)); do
            local cj=$((costs[$i] + 1))
            local cs=$((costs[$i - 1] + 1))
            if [ "${1:i-1:1}" == "${2:j-1:1}" ]; then
                local cost=$nw
            else
                local cost=$((nw + 1))
            fi
            costs[$i]=$(( $(min $cj $cs $cost) ))
            nw=${costs[$i]}
        done
    done

    echo ${costs[str1len-1]}
}

min() {
    local min=$1
    for n in "$@"; do
        ((n < min)) && min=$n
    done
    echo $min
}

similarity_score() {
    local len1=${#1}
    local len2=${#2}
    local max_len=$((len1 > len2 ? len1 : len2))
    local dist=$(levenshtein "$1" "$2")
    local similarity=$(echo "scale=2; 1 - $dist / $max_len" | bc)
    echo $similarity
}

add_issue() {
    local severity=$1
    local title=$2
    local details=$3
    local next_steps=$4

    # Check for similar existing details
    for key in "${!issue_details[@]}"; do
        local similarity=$(similarity_score "$key" "$details")
        if (( $(echo "$similarity > 0.8" | bc -l) )); then
            return
        fi
    done

    issue_titles["$title"]=$severity
    issue_details["$details"]=$details
    issue_next_steps["$title"]=$next_steps
}

# Check conditions and add issues to the array
if [[ $messages =~ "ContainersNotReady" && $owner_kind == "Deployment" ]]; then
    add_issue "2" "$owner_kind \`$owner_name\` has unready containers" "$messages" "Inspect Deployment Replicas for \`$owner_name\`"
fi

if [[ $messages =~ "Container runtime did not kill the pod within specified grace period" ]]; then
    add_issue "3" "$owner_kind \`$owner_name\` timed out during reschedule attempt." "$messages" "Identify High Utilization Nodes for Cluster \`${CONTEXT}\`"
fi

if [[ $messages =~ "Misconfiguration" && $owner_kind == "Deployment" ]]; then
    add_issue "2" "$owner_kind \`$owner_name\` has a misconfiguration" "$messages" "Check Deployment Log For Issues for \`$owner_name\`\nGet Deployment Workload Details For \`$owner_name\` and Add to Report"
fi

if [[ $messages =~ "PodInitializing" ]]; then
    add_issue "4" "$owner_kind \`$owner_name\` is initializing" "$messages" "Retry in a few minutes and verify that \`$owner_name\` is running.\nInspect $owner_kind Warning Events for \`$owner_name\`"
fi

if [[ $messages =~ "Liveness probe failed" || $messages =~ "Liveness probe errored" ]]; then
    add_issue "3" "$owner_kind \`$owner_name\` is restarting" "$messages" "Check Liveliness Probe Configuration for $owner_kind \`$owner_name\`"
fi

if [[ $messages =~ "Readiness probe errored" || $messages =~ "Readiness probe failed" ]]; then
    add_issue "2" "$owner_kind \`$owner_name\` is unable to start" "$messages" "Check Readiness Probe Configuration for $owner_kind \`$owner_name\`"
fi

if [[ $messages =~ "PodFailed" ]]; then
    add_issue "2" "$owner_kind \`$owner_name\` has failed pods" "$messages" "Check Pod Status and Logs for Errors"
fi

if [[ $messages =~ "ImagePullBackOff" || $messages =~ "Back-off pulling image" || $messages =~ "ErrImagePull" ]]; then
    add_issue "2" "$owner_kind \`$owner_name\` has image access issues" "$messages" "List Images and Tags for Every Container in Failed Pods for Namespace \`$NAMESPACE\`\nList ImagePullBackoff Events and Test Path and Tags for Namespace \`$NAMESPACE\`"
fi

if [[ $messages =~ "Back-off restarting failed container" ]]; then
    add_issue "2" "$owner_kind \`$owner_name\` has failing containers" "$messages" "Check $owner_kind Log for \`$owner_name\`\nInspect Warning Events for $owner_kind \`$owner_name\`"
fi

if [[ $messages =~ "forbidden: failed quota" || $messages =~ "forbidden: exceeded quota" ]]; then
    add_issue "3" "$owner_kind \`$owner_name\` has resources that cannot be scheduled" "$messages" "Adjust resource configuration for $owner_kind \`$owner_name\` according to issue details."
fi

if [[ $messages =~ "is forbidden: [minimum cpu usage per Container" || $messages =~ "is forbidden: [minimum memory usage per Container" ]]; then
    add_issue "2" "$owner_kind \`$owner_name\` has invalid resource configuration" "$messages" "Adjust resource configuration for $owner_kind \`$owner_name\` according to issue details."
fi

if [[ $messages =~ "No preemption victims found for incoming pod" || $messages =~ "Insufficient cpu" || $messages =~ "The node was low on resource" ]]; then
    add_issue "2" "$owner_kind \`$owner_name\` cannot be scheduled - not enough cluster resources." "$messages" "Not enough node resources available to schedule pods. Escalate this issue to your cluster owner.\nIncrease Node Count for Cluster \`${CONTEXT}\` \nCheck for Quota Errors\nIdentify High Utilization Nodes for Cluster \`${CONTEXT}\`"
fi

if [[ $messages =~ "max node group size reached" ]]; then
    add_issue "2" "$owner_kind \`$owner_name\` cannot be scheduled - cannot increase cluster size." "$messages" "Not enough node resources available to schedule pods. Escalate this issue to your cluster owner.\nIncrease Max Node Group Size in Cluster\nIdentify High Utilization Nodes for Cluster \`${CONTEXT}\`"
fi

if [[ $messages =~ "Health check failed after" && $owner_kind == "Kustomization" ]]; then
    add_issue "3" "$owner_kind \`$owner_name\` health check failed." "$messages" "Get details for unready Kustomizations in Namespace \`${NAMESPACE}\`"
fi

if [[ $messages =~ "Health check failed after" ]]; then
    add_issue "3" "$owner_kind \`$owner_name\` health check failed." "$messages" "Check $owner_kind \`$owner_name\` Health"
fi

if [[ $messages =~ "Deployment does not have minimum availability" ]]; then
    add_issue "3" "$owner_kind \`$owner_name\` is not available." "$messages" "Inspect Deployment Warning Events for \`$owner_name\`"
fi

if [[ $messages =~ "failed to download archive" ]]; then
    add_issue "3" "$owner_kind \`$owner_name\` has internal connectivity issues fetching source" "$messages" "Escalate connectivity issues to service owner if they continue."
fi

if [[ $messages =~ "connect: connection refused" ]]; then
    add_issue "3" "Internal connectivity issues detected" "$messages" "Escalate connectivity issues to service owner if they continue."
fi

if [[ $messages =~ "OCI runtime exec failed: exec failed: unable to start container process" ]]; then
    add_issue "2" "Possible node or container runtime issue" "$messages" "Escalate container runtime issue to service owner if they continue."
fi

if [[ $messages =~ "Created container" || $messages =~ "no changes since last reconciliation" || $messages =~ "Reconciliation finished" || $messages =~ "Pulling image" || $messages =~ "Successfully pulled" || $messages =~ "Started container" || $messages =~ "Successfully assigned" || $messages =~ "already present on machine" ]]; then
    # Don't generate any issue data, these are normal strings
    echo "[]" | jq .
    exit 0
fi

### These are ChatGPT Generated and will require tuning. Please migrate above this line when tuned. 
## Removed for now - they were getting wildly off-base
### End of auto-generated message strings

if [ ${#issue_titles[@]} -gt 0 ]; then
    issues_json="["
    for title in "${!issue_titles[@]}"; do
        details="${issue_details[${issue_details[$title]}]}"
        issues_json+="{\"severity\":\"${issue_titles[$title]}\",\"title\":\"$title\",\"details\":\"${issue_details[$details]}\",\"next_steps\":\"${issue_next_steps[$title]}\"},"
    done
    issues_json="${issues_json%,}]" # Remove the last comma and wrap in square brackets
    echo "$issues_json" | jq .
else
    echo "[{\"severity\":\"4\",\"title\":\"$owner_kind \`$owner_name\` has issues that require further investigation.\",\"details\":\"$messages\",\"next_steps\":\"Escalate issues for $owner_kind \`$owner_name\` to service owner \"}]" | jq .
fi
