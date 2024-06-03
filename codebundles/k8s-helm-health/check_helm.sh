#!/bin/bash

# Function to check if helm command exists
check_helm_binary() {
    if ! command -v helm &> /dev/null
    then
        echo "Error: Helm binary is not available. Please install Helm." >&2
        exit 1
    fi
}

# Function to run a Helm command with a specific context
run_helm_command() {
    local command="$1"
    local context="$2"
    local release_name="$3"
    local chart_path="$4"

    # Construct the Helm command
    if [ -z "$chart_path" ]; then
        helm_command="helm $command $release_name --kube-context $context"
    else
        helm_command="helm $command $release_name $chart_path --kube-context $context"
    fi

    # Execute the Helm command and capture the error code
    if ! output=$($helm_command 2>&1); then
        echo "Error: Helm command failed. Check your permissions, context, or command syntax." >&2
        echo "Command output: $output" >&2
        exit 1
    else
        echo "Helm command succeeded."
    fi
}

# Main script
check_helm_binary

# Define the Helm command and parameters
COMMAND="install"           # Example command (install, upgrade, uninstall, list, template)
RELEASE_NAME="my-release"   # Example release name (optional for certain commands like list)
CHART_PATH=""               # Example chart path (omit or leave empty if not needed)
CONTEXT="my-context"        # Example Kubernetes context

# Run the Helm command with error checking
run_helm_command "$COMMAND" "$CONTEXT" "$RELEASE_NAME" "$CHART_PATH"
