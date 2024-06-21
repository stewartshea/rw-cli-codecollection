#!/bin/bash

# -----------------------------------------------------------------------------
# Script Information and Metadata
# -----------------------------------------------------------------------------
# Author: @stewartshea
# Description: This script processes the output of Kubernetes get pods command, and deduplicates similar pod events.
# -----------------------------------------------------------------------------
# Input: JSON output of Kubernetes get pods command
json_input=$(cat)

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

is_duplicate() {
    local new_pod_name=$1
    local new_message=$2

    for i in "${!pod_names[@]}"; do
        local existing_pod_name=${pod_names[$i]}
        local existing_message=${messages[$i]}
        local name_similarity=$(similarity_score "$new_pod_name" "$existing_pod_name")
        local message_similarity=$(similarity_score "$new_message" "$existing_message")

        if (( $(echo "$name_similarity > 0.8" | bc -l) )) && (( $(echo "$message_similarity > 0.8" | bc -l) )); then
            return 0
        fi
    done

    return 1
}

pod_names=()
messages=()
restart_counts=()
terminated_finishedAts=()
exit_codes=()
exit_code_explanations=()

while IFS= read -r line; do
    pod_name=$(echo "$line" | jq -r '.pod_name')
    message=$(echo "$line" | jq -r '.message')
    restart_count=$(echo "$line" | jq -r '.restart_count')
    terminated_finishedAt=$(echo "$line" | jq -r '.terminated_finishedAt')
    exit_code=$(echo "$line" | jq -r '.exit_code')
    exit_code_explanation=$(echo "$line" | jq -r '.exit_code_explanation')

    if ! is_duplicate "$pod_name" "$message"; then
        pod_names+=("$pod_name")
        messages+=("$message")
        restart_counts+=("$restart_count")
        terminated_finishedAts+=("$terminated_finishedAt")
        exit_codes+=("$exit_code")
        exit_code_explanations+=("$exit_code_explanation")
    fi
done <<< "$(echo "$json_input" | jq -c '.[]')"

output='['
for i in "${!pod_names[@]}"; do
    output+=$(jq -nc --arg pod_name "${pod_names[$i]}" --arg restart_count "${restart_counts[$i]}" --arg message "${messages[$i]}" --arg terminated_finishedAt "${terminated_finishedAts[$i]}" --arg exit_code "${exit_codes[$i]}" --arg exit_code_explanation "${exit_code_explanations[$i]}" \
    '{"pod_name": $pod_name, "restart_count": $restart_count, "message": $message, "terminated_finishedAt": $terminated_finishedAt, "exit_code": $exit_code, "exit_code_explanation": $exit_code_explanation}')
    output+=','
done
output="${output%,}]"

echo "$output" | jq .
