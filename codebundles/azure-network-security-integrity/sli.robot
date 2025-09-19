*** Settings ***
Documentation       SLI for [TEST] Azure NSG Integrity - AI Generator Test
Metadata            Author    auto-generated
Metadata            Display Name    Azure Network Security Integrity SLI
Metadata            Supports    AZURE

Library             BuiltIn
Library             RW.Core
Library             RW.CLI
Library             RW.platform
Library             OperatingSystem

Suite Setup         Suite Initialization

*** Tasks ***
- Compare current NSG rules with repo-managed desired state SLI
    [Documentation]    SLI for - Compare current NSG rules with repo-managed desired state
    [Tags]    azure    sli    --compare-current-nsg-rules-with-repo-managed-desired-state
    ${result}=    RW.CLI.Run Bash File
    ...    bash_file=_compare_current_nsg_rules_with_repo_managed_desired_state.sh
    ...    env=${env}
    ...    include_in_history=false
    
    # Parse result and push metric
    ${issues}=    RW.CLI.Run CLI    cat ${OUTPUT_DIR}/results.json | jq '.issues | length'
    ${metric_value}=    Set Variable If    ${issues.stdout} == 0    1    0
    RW.Core.Push Metric    ${metric_value}
Flag discrepancies that indicate out-of-band changes SLI
    [Documentation]    SLI for Flag discrepancies that indicate out-of-band changes
    [Tags]    azure    sli    flag-discrepancies-that-indicate-out-of-band-changes
    ${result}=    RW.CLI.Run Bash File
    ...    bash_file=flag_discrepancies_that_indicate_out_of_band_changes.sh
    ...    env=${env}
    ...    include_in_history=false
    
    # Parse result and push metric
    ${issues}=    RW.CLI.Run CLI    cat ${OUTPUT_DIR}/results.json | jq '.issues | length'
    ${metric_value}=    Set Variable If    ${issues.stdout} == 0    1    0
    RW.Core.Push Metric    ${metric_value}
- Confirm traffic flow from each subnet by testing NSG and VNet rule enforcement SLI
    [Documentation]    SLI for - Confirm traffic flow from each subnet by testing NSG and VNet rule enforcement
    [Tags]    azure    sli    --confirm-traffic-flow-from-each-subnet-by-testing-nsg-and-vnet-rule-enforcement
    ${result}=    RW.CLI.Run Bash File
    ...    bash_file=_confirm_traffic_flow_from_each_subnet_by_testing_nsg_and_vnet_rule_enforcement.sh
    ...    env=${env}
    ...    include_in_history=false
    
    # Parse result and push metric
    ${issues}=    RW.CLI.Run CLI    cat ${OUTPUT_DIR}/results.json | jq '.issues | length'
    ${metric_value}=    Set Variable If    ${issues.stdout} == 0    1    0
    RW.Core.Push Metric    ${metric_value}

*** Keywords ***
Suite Initialization
    RW.Core.Import Service    bash
    RW.Core.Import Service    k8s
    RW.Core.Import Service    curl
    Set Suite Variable    ${OUTPUT_DIR}    /tmp/rwi_output
    Create Directory    ${OUTPUT_DIR}
