Here is a Robot Framework file for the tasks you've mentioned:

```robot
*** Settings ***
Documentation     This suite contains tasks to detect manual NSG changes in Azure.
Library           OperatingSystem
Library           RW.Core
Suite Setup       Set Environment Variables
Force Tags        azure  network-security  integrity
Default Tags      manual-change-detection

*** Variables ***
${AZURE_SUBSCRIPTION_ID}      your_subscription_id
${AZURE_RESOURCE_GROUP}       your_resource_group
${AZURE_NSG_NAME}             your_nsg_name
${TIMEOUT}                    5 minutes

*** Tasks ***
Compare Current NSG Rules With Desired State
    [Tags]    compare-nsg-rules
    ${result}=    Run And Return Rc And Output    bash compare_nsg_rules.sh
    Log    ${result[1]}
    Should Be Equal As Integers    ${result[0]}    0

Confirm Traffic Flow From Each Subnet
    [Tags]    confirm-traffic-flow
    ${result}=    Run And Return Rc And Output    bash confirm_traffic_flow.sh
    Log    ${result[1]}
    Should Be Equal As Integers    ${result[0]}    0

Query Activity Logs For Firewall/NSG Changes
    [Tags]    query-activity-logs
    ${result}=    Run And Return Rc And Output    bash query_activity_logs.sh
    Log    ${result[1]}
    Should Be Equal As Integers    ${result[0]}    0

Detect Manual NSG Changes
    [Tags]    detect-manual-changes
    ${result}=    Run And Return Rc And Output    bash detect_manual_changes.sh
    Log    ${result[1]}
    Should Be Equal As Integers    ${result[0]}    0

*** Keywords ***
Set Environment Variables
    Set Environment Variable    AZURE_SUBSCRIPTION_ID    ${AZURE_SUBSCRIPTION_ID}
    Set Environment Variable    AZURE_RESOURCE_GROUP     ${AZURE_RESOURCE_GROUP}
    Set Environment Variable    AZURE_NSG_NAME           ${AZURE_NSG_NAME}
    Set Environment Variable    TIMEOUT                  ${TIMEOUT}
```

This Robot Framework file sets up the environment variables required for the bash scripts to run, and then executes each bash script in a separate task. The output of each script is logged, and the return code is checked to ensure the script executed successfully. If any script returns a non-zero exit code, the task will fail.

Please replace `your_subscription_id`, `your_resource_group`, and `your_nsg_name` with your actual Azure subscription ID, resource group, and NSG name.

The bash scripts `compare_nsg_rules.sh`, `confirm_traffic_flow.sh`, `query_activity_logs.sh`, and `detect_manual_changes.sh` need to be implemented according to your requirements.