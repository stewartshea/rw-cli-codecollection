Here is a Robot Framework file for the tasks you've mentioned:

```robot
*** Settings ***
Documentation     This suite is used to perform integrity checks on Azure Network Security.
Library           RW.Core
Suite Setup       Set Environment Variables
Force Tags        azure  network-security  integrity

*** Variables ***
${AZURE_SUBSCRIPTION_ID}    ${EMPTY}
${AZURE_RESOURCE_GROUP}     ${EMPTY}
${AZURE_NSG_NAME}           ${EMPTY}
${TIMEOUT}                  5 minutes

*** Tasks ***
Compare Current NSG Rules With Repo-Managed Desired State
    [Documentation]     Compares the current NSG rules with the repo-managed desired state and flags any discrepancies.
    [Tags]              compare  nsg  repo-managed
    ${result}=          Run And Return Rc And Output  bash  ./compare_nsg_state.sh
    Should Be Equal As Integers  ${result[0]}  0
    Log To Console  ${result[1]}

Confirm Traffic Flow From Each Subnet
    [Documentation]     Confirms the traffic flow from each subnet by testing NSG and VNet rule enforcement.
    [Tags]              confirm  traffic  subnet
    ${result}=          Run And Return Rc And Output  bash  ./confirm_traffic_flow.sh
    Should Be Equal As Integers  ${result[0]}  0
    Log To Console  ${result[1]}

Query Activity Logs For Firewall/NSG Changes
    [Documentation]     Queries activity logs to identify whether firewall/NSG changes were pushed through CI/CD pipeline vs. manual actors.
    [Tags]              query  activity  logs  firewall  nsg  changes
    ${result}=          Run And Return Rc And Output  bash  ./query_activity_logs.sh
    Should Be Equal As Integers  ${result[0]}  0
    Log To Console  ${result[1]}

Detect Manual NSG Changes
    [Documentation]     Detects any manual changes made to the NSG.
    [Tags]              detect  manual  nsg  changes
    ${result}=          Run And Return Rc And Output  bash  ./detect_manual_nsg_changes.sh
    Should Be Equal As Integers  ${result[0]}  0
    Log To Console  ${result[1]}

*** Keywords ***
Set Environment Variables
    Set Environment Variable  AZURE_SUBSCRIPTION_ID  ${AZURE_SUBSCRIPTION_ID}
    Set Environment Variable  AZURE_RESOURCE_GROUP  ${AZURE_RESOURCE_GROUP}
    Set Environment Variable  AZURE_NSG_NAME  ${AZURE_NSG_NAME}
```

This Robot Framework file includes four tasks: "Compare Current NSG Rules With Repo-Managed Desired State", "Confirm Traffic Flow From Each Subnet", "Query Activity Logs For Firewall/NSG Changes", and "Detect Manual NSG Changes". Each task is tagged appropriately and includes documentation.

The "Set Environment Variables" keyword is used in the Suite Setup to set the necessary environment variables for the bash scripts.

Each task uses the RW.Core library to execute the corresponding bash script and logs the output to the console. If the return code of the bash script is not 0, the task will fail.