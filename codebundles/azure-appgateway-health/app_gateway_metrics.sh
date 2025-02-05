#!/usr/bin/env bash
set -euo pipefail

# -----------------------------------------------------------------------------
# Hardcoded aggregator mappings. 
#   These are the known-working aggregators for your environment.
#   - "TotalRequests" => "Count"
#   - "FailedRequests" => "Count"
#   - "UnhealthyHostCount" => "Average" 
#   - "HealthyHostCount" => "Average"
#   - "CurrentConnections" => "Count"
#   - "Throughput" => "Average"
# -----------------------------------------------------------------------------
declare -A METRIC_TO_AGGREGATOR=(
  ["TotalRequests"]="Average"
  ["FailedRequests"]="Average"
  ["UnhealthyHostCount"]="Average"
  ["HealthyHostCount"]="Average"
  ["CurrentConnections"]="Average"
  ["Throughput"]="Average"
)

# Metrics you want to query
METRICS_TO_FETCH=(
  "TotalRequests"
  "FailedRequests"
  "UnhealthyHostCount"
  "HealthyHostCount"
  "CurrentConnections"
  "Throughput"
)

# -----------------------------------------------------------------------------
# ENV VARS REQUIRED:
#   APP_GATEWAY_NAME
#   AZ_RESOURCE_GROUP
#
# OPTIONAL:
#   METRIC_TIME_RANGE  (default: PT1H)
#   OUTPUT_DIR         (default: ./output)
#
# This script:
#  1) Gets the Application Gateway resource ID
#  2) For each metric, runs a single 'az monitor metrics list' 
#     with the aggregator from METRIC_TO_AGGREGATOR
#  3) Parses the result (or stores 0 on error)
#  4) Outputs JSON: { "metrics": { ... }, "issues": [...] }
# -----------------------------------------------------------------------------

: "${APP_GATEWAY_NAME:?Must set APP_GATEWAY_NAME}"
: "${AZ_RESOURCE_GROUP:?Must set AZ_RESOURCE_GROUP}"

METRIC_TIME_RANGE="${METRIC_TIME_RANGE:-PT1H}"
OUTPUT_DIR="${OUTPUT_DIR:-./output}"
mkdir -p "$OUTPUT_DIR"
OUTPUT_FILE="${OUTPUT_DIR}/app_gateway_metrics_simplified.json"

echo "Fetching metrics for Application Gateway \`$APP_GATEWAY_NAME\` in resource group \`$AZ_RESOURCE_GROUP\` over $METRIC_TIME_RANGE..."

# 1) Get the resource ID
AGW_RESOURCE_ID=$(az network application-gateway show \
  --name "$APP_GATEWAY_NAME" \
  --resource-group "$AZ_RESOURCE_GROUP" \
  --query "id" -o tsv 2>/dev/null || true)

if [[ -z "$AGW_RESOURCE_ID" ]]; then
  echo "ERROR: Could not find Application Gateway \`$APP_GATEWAY_NAME\` in \`$AZ_RESOURCE_GROUP\`."
  exit 1
fi

echo "Using resource ID: $AGW_RESOURCE_ID"

metrics_json='{}'
issues_json='{"issues": []}'

# -----------------------------------------------------------------------------
# Helper function to parse aggregator results
# -----------------------------------------------------------------------------
parse_metric_value() {
  local raw_json="$1"
  local aggregator="$2"

  # Check JSON validity
  if ! echo "$raw_json" | jq '.' >/dev/null 2>&1; then
    echo "0"
    return
  fi

  # Check if .value has data
  local val_len
  val_len=$(echo "$raw_json" | jq '.value | length')
  if [[ "$val_len" == "0" || "$val_len" == "null" ]]; then
    echo "0"
    return
  fi

  # Parse based on aggregator
  case "$aggregator" in
    "Sum")
      echo "$raw_json" | jq '[.value[].timeseries[].data[].sum // 0] | add' || echo "0"
      ;;
    "Count")
      echo "$raw_json" | jq '[.value[].timeseries[].data[].count // 0] | add' || echo "0"
      ;;
    "Average")
      echo "$raw_json" | jq '
        .value[].timeseries[].data[] | (.average // 0)
      ' | awk '{ sum+=$1; cnt++ } END { if(cnt>0){printf "%.2f", sum/cnt} else{print 0} }'
      ;;
    "Max")
      echo "$raw_json" | jq '[.value[].timeseries[].data[].max // 0] | max' || echo "0"
      ;;
    "Min")
      echo "$raw_json" | jq '[.value[].timeseries[].data[].min // 0] | min' || echo "0"
      ;;
    *)
      echo "0"
      ;;
  esac
}

# -----------------------------------------------------------------------------
# 2) Loop over METRICS_TO_FETCH
# -----------------------------------------------------------------------------
for metric_name in "${METRICS_TO_FETCH[@]}"; do
  aggregator="${METRIC_TO_AGGREGATOR[$metric_name]:-}"

  if [[ -z "$aggregator" ]]; then
    echo "No aggregator defined for \`$metric_name\`. Storing 0."
    metrics_json=$(echo "$metrics_json" | jq \
      --arg m "$metric_name" --argjson val 0 \
      '. + {($m): $val}')
    continue
  fi

  cmd="az monitor metrics list \
    --resource \"$AGW_RESOURCE_ID\" \
    --metric \"$metric_name\" \
    --interval \"$METRIC_TIME_RANGE\" \
    --aggregation \"$aggregator\" \
    -o json"

  echo "Querying metric \`$metric_name\` with aggregator \`$aggregator\`..."
  echo "Command: $cmd"

  # Simpler approach: capture stdout in cli_stdout, stderr in $OUTPUT_DIR/app_gw_metrics_errors.log
  if ! cli_stdout=$(eval "$cmd" 2>$OUTPUT_DIR/app_gw_metrics_errors.log); then
    echo "ERROR: aggregator=$aggregator for metric=$metric_name"
    cat $OUTPUT_DIR/app_gw_metrics_errors.log
    issues_json=$(echo "$issues_json" | jq \
      --arg title "Failed to Fetch Metric \`$metric_name\`" \
      --arg details "$(cat $OUTPUT_DIR/app_gw_metrics_errors.log)" \
      --arg severity "1" \
      --arg nextStep "Check aggregator or permissions. Possibly not supported in your tier/region." \
      '.issues += [{
         "title": $title,
         "details": $details,
         "next_step": $nextStep,
         "severity": ($severity | tonumber)
       }]')
    metrics_json=$(echo "$metrics_json" | jq \
      --arg m "$metric_name" --argjson val 0 \
      '. + {($m): $val}')
    rm -f $OUTPUT_DIR/app_gw_metrics_errors.log
    continue
  fi
  rm -f $OUTPUT_DIR/app_gw_metrics_errors.log

  echo "Raw CLI output for \`$metric_name\`, aggregator=\`$aggregator\`:"
  echo "$cli_stdout"

  # Parse metric value
  raw_val=$(parse_metric_value "$cli_stdout" "$aggregator")

  # Trim whitespace/newlines
  val="$(echo "$raw_val" | xargs)"

  # If empty, default to "0"
  if [[ -z "$val" ]]; then
    val="0"
  fi

  echo "Value for \`$metric_name\`: $val"

  # If $val is numeric => --argjson, else store as string
  if [[ "$val" =~ ^-?[0-9]*\.?[0-9]+$ ]]; then
    metrics_json=$(echo "$metrics_json" | jq \
      --arg m "$metric_name" \
      --argjson v "$val" \
      '. + {($m): $v}')
  else
    metrics_json=$(echo "$metrics_json" | jq \
      --arg m "$metric_name" \
      --arg v "$val" \
      '. + {($m): $v}')
  fi
done

# -----------------------------------------------------------------------------
# 3) Optional threshold checks
# -----------------------------------------------------------------------------
unhealthy=$(echo "$metrics_json" | jq '.UnhealthyHostCount // 0')
if (( $(echo "$unhealthy > 0" | bc -l) )); then
  issues_json=$(echo "$issues_json" | jq \
    --arg title "Detected Unhealthy Hosts" \
    --arg details "UnhealthyHostCount = $unhealthy" \
    --arg severity "2" \
    --arg nextStep "Check backend pool health for \`$APP_GATEWAY_NAME\`." \
    '.issues += [{
      "title": $title,
      "details": $details,
      "next_step": $nextStep,
      "severity": ($severity | tonumber)
    }]')
fi

total_requests=$(echo "$metrics_json" | jq '.TotalRequests // 0')
failed_requests=$(echo "$metrics_json" | jq '.FailedRequests // 0')

if (( $(echo "$total_requests > 0" | bc -l) )); then
  fail_rate=$(awk "BEGIN { printf \"%.2f\", $failed_requests/$total_requests * 100 }")
  if (( $(echo "$fail_rate >= 10.0" | bc -l) )); then
    issues_json=$(echo "$issues_json" | jq \
      --arg title "High Failure Rate" \
      --arg details "Failure rate is $fail_rate%, above 10% threshold." \
      --arg severity "2" \
      --arg nextStep "Investigate 4xx/5xx responses or check logs for \`$APP_GATEWAY_NAME\`." \
      '.issues += [{
         "title": $title,
         "details": $details,
         "next_step": $nextStep,
         "severity": ($severity | tonumber)
       }]')
  fi
fi

# -----------------------------------------------------------------------------
# 4) Output final JSON
# -----------------------------------------------------------------------------
final_json=$(jq -n \
  --argjson m "$metrics_json" \
  --argjson i "$(echo "$issues_json" | jq '.issues')" \
  '{ "metrics": $m, "issues": $i }'
)

echo "--------------------------------------------------"
echo "Application Gateway Metrics & Issues (Last $METRIC_TIME_RANGE):"
echo "$final_json" | jq .
echo "--------------------------------------------------"
echo "$final_json" > "$OUTPUT_FILE"
echo "Results saved to $OUTPUT_FILE."
