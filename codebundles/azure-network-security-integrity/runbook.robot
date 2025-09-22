Here is a Robot Framework file for the tasks you described:

```robot
*** Settings ***
Documentation     This suite is designed to detect manual changes in Azure Network Security Groups (NSGs)
Library           RW.Core
Suite Setup       Set Environment Variables
Suite Teardown    RW.Core.Pop Shell History
Default Tags      azure  network-security  integrity
Timeout           5 minutes

*** Variables ***
${AZURE_SUBSCRIPTION_ID}    YOUR_SUBSCRIPTION_ID
${AZURE_RESOURCE_GROUP}     YOUR_RESOURCE_GROUP
${AZURE_NSG_NAME}           YOUR_NSG_NAME

*** Tasks ***
Compare NSG Rules With Desired State
    [Documentation]     Compare the current NSG rules with the desired state and flag discrepancies
    [Tags]              NSG  compare
    ${result}=          Run Shell Script    compare_nsg_rules.sh
    Log                 ${result}
    ${status}=          Get Status From Result    ${result}
    Should Be Equal As Strings    ${status}    0

Confirm Traffic Flow
    [Documentation]     Confirm traffic flow from each subnet by testing NSG and VNet rule enforcement
    [Tags]              NSG  traffic
    ${result}=          Run Shell Script    confirm_traffic_flow.sh
    Log                 ${result}
    ${status}=          Get Status From Result    ${result}
    Should Be Equal As Strings    ${status}    0

Query Activity Logs
    [Documentation]     Query activity logs to identify whether firewall/NSG changes were pushed through CI/CD pipeline vs. manual actors
    [Tags]              NSG  logs
    ${result}=          Run Shell Script    query_activity_logs.sh
    Log                 ${result}
    ${status}=          Get Status From Result    ${result}
    Should Be Equal As Strings    ${status}    0

Detect Manual NSG Changes
    [Documentation]     Detect manual changes in NSGs
    [Tags]              NSG  manual
    ${result}=          Run Shell Script    detect_manual_nsg_changes.sh
    Log                 ${result}
    ${status}=          Get Status From Result    ${result}
    Should Be Equal As Strings    ${status}    0

*** Keywords ***
Set Environment Variables
    [Documentation]     Set necessary environment variables
    Set Environment Variable    AZURE_SUBSCRIPTION_ID    ${AZURE_SUBSCRIPTION_ID}
    Set Environment Variable    AZURE_RESOURCE_GROUP     ${AZURE_RESOURCE_GROUP}
    Set Environment Variable    AZURE_NSG_NAME           ${AZURE_NSG_NAME}

Get Status From Result
    [Arguments]         ${result}
    [Return]            ${result}[status]
```

This file assumes that you have the necessary bash scripts (`compare_nsg_rules.sh`, `confirm_traffic_flow.sh`, `query_activity_logs.sh`, `detect_manual_nsg_changes.sh`) in your PATH. Replace `YOUR_SUBSCRIPTION_ID`, `YOUR_RESOURCE_GROUP`, and `YOUR_NSG_NAME` with your actual Azure Subscription ID, Resource Group, and NSG Name, respectively.