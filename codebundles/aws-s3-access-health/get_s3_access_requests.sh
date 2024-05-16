#!/bin/bash

# Check if CloudTrail is enabled
check_cloudtrail_enabled() {
    enabled=$(aws cloudtrail describe-trails --output json | jq -r '.trailList | length')
    if [[ $enabled -eq 0 ]]; then
        echo "CloudTrail is not enabled in the AWS account."
        exit 1
    fi
}

# Convert hours to milliseconds
hours_to_milliseconds() {
    echo $(($1 * 3600000))
}


# Function to retrieve CloudTrail logs
get_cloudtrail_logs() {

    # Get current timestamp in milliseconds
    current_time=$(date +%s%3N)

    # Calculate start time by subtracting specified number of hours from current time
    hours_back=$1
    start_time=$((current_time - $(hours_to_milliseconds $hours_back)))

    # Convert start and current time to ISO 8601 format
    start_time_iso=$(date -u -d @$((start_time / 1000)) "+%Y-%m-%dT%H:%M:%SZ")
    current_time_iso=$(date -u -d @$((current_time / 1000)) "+%Y-%m-%dT%H:%M:%SZ")

    # Lookup CloudTrail events within the specified time range and save to JSON file
    aws cloudtrail lookup-events --start-time $start_time_iso --end-time $current_time_iso --output json > cloudtrail_logs.json

    echo "CloudTrail logs for the last $hours_back hours have been saved to cloudtrail_logs.json"
}

# Check if CloudTrail is enabled
check_cloudtrail_enabled

get_cloudtrail_logs

cat cloudtrail_logs.json