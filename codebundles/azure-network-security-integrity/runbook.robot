Here is a Robot Framework file for the tasks you mentioned:

```robot
*** Settings ***
Documentation     A test suite for detecting manual NSG changes and ensuring network security integrity in Azure.
Library           RW.Core
Suite Setup       Set Environment Variables
Force Tags        azure  network-security  integrity
Default Tags      azure-network-security-integrity

*** Variables ***
${AZURE_SUBSCRIPTION_ID}    YOUR_SUBSCRIPTION_ID
${AZURE_RESOURCE_GROUP}     YOUR_RESOURCE_GROUP
${AZURE_NSG_NAME}           YOUR_NSG_NAME
${TIMEOUT}                  60s

*** Tasks ***
Compare NSG Rules With Repo State
    [Documentation]   Compare current NSG rules with repo-managed desired state.
    [Tags]            comparison  state-integrity
    ${result}=        Run And Return Rc And Output   bash ./compare_nsg_rules.sh
    Should Be Equal As Integers   ${result.rc}   0

Confirm Traffic Flow From Each Subnet
    [Documentation]   Confirm traffic flow from each subnet by testing NSG and VNet rule enforcement.
    [Tags]            traffic-flow  rule-enforcement
    ${result}=        Run And Return Rc And Output   bash ./confirm_traffic_flow.sh
    Should Be Equal As Integers   ${result.rc}   0

Query Activity Logs For Firewall/NSG Changes
    [Documentation]   Query activity logs to identify whether firewall/NSG changes were pushed through CI/CD pipeline vs. manual actors.
    [Tags]            activity-logs  ci/cd  manual-changes
    ${result}=        Run And Return Rc And Output   bash ./query_activity_logs.sh
    Should Be Equal As Integers   ${result.rc}   0

Detect Manual NSG Changes
    [Documentation]   Detect manual NSG changes.
    [Tags]            manual-changes  detection
    ${result}=        Run And Return Rc And Output   bash ./detect_manual_changes.sh
    Should Be Equal As Integers   ${result.rc}   0

*** Keywords ***
Set Environment Variables
    Set Environment Variable   AZURE_SUBSCRIPTION_ID   ${AZURE_SUBSCRIPTION_ID}
    Set Environment Variable   AZURE_RESOURCE_GROUP    ${AZURE_RESOURCE_GROUP}
    Set Environment Variable   AZURE_NSG_NAME          ${AZURE_NSG_NAME}

*** Keywords ***
Run And Return Rc And Output
    [Arguments]   ${command}
    ${rc}   ${output}=   Run And Return Rc And Output   ${command}   timeout=${TIMEOUT}
    Log   ${output}
    [Return]   ${rc}   ${output}
```

Please replace `YOUR_SUBSCRIPTION_ID`, `YOUR_RESOURCE_GROUP`, and `YOUR_NSG_NAME` with your actual Azure Subscription ID, Resource Group, and NSG Name respectively. Also, you need to create the bash scripts `compare_nsg_rules.sh`, `confirm_traffic_flow.sh`, `query_activity_logs.sh`, and `detect_manual_changes.sh` and place them in the same directory as this Robot Framework file.