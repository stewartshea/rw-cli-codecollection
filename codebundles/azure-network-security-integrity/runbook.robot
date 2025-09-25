*** Settings ***
Documentation       [TEST] Azure NSG Integrity - AI Generator Test
Metadata            Author    auto-generated
Metadata            Display Name    Azure Network Security Integrity
Metadata            Supports    AZURE

Library             BuiltIn
Library             RW.Core
Library             RW.CLI
Library             RW.platform
Library             OperatingSystem

Suite Setup         Suite Initialization

*** Tasks ***
- Compare current NSG rules with repo-managed desired state
    [Documentation]    - Compare current NSG rules with repo-managed desired state
    [Tags]    azure    --compare-current-nsg-rules-with-repo-managed-desired-state    auto-generated
    ${result}=    RW.CLI.Run Bash File
    ...    bash_file=_compare_current_nsg_rules_with_repo_managed_desired_state.sh
    ...    env=${env}
    ...    include_in_history=false
    RW.Core.Add Pre To Report    ${result.stdout}
    
    # Parse results and create issues if needed
    ${issues}=    RW.CLI.Run CLI    cat ${OUTPUT_DIR}/results.json | jq -r '.issues[]'
    IF    "${issues.stdout}" != ""
        ${issue_count}=    RW.CLI.Run CLI    cat ${OUTPUT_DIR}/results.json | jq '.issues | length'
        RW.Core.Add To Report    Found ${issue_count.stdout} issues
        
        # Add each issue
        ${parsed_issues}=    RW.CLI.Run CLI    cat ${OUTPUT_DIR}/results.json | jq -c '.issues[]'
        FOR    ${issue_line}    IN    @{parsed_issues.stdout.split('\n')}
            IF    "${issue_line}" != ""
                ${issue}=    Evaluate    json.loads('${issue_line}')    json
                RW.Core.Add Issue
                ...    severity=${issue.get('severity', 3)}
                ...    title=${issue.get('title', 'Issue Detected')}
                ...    details=${issue.get('details', 'No details available')}
                ...    next_steps=${issue.get('next_steps', 'Please investigate the reported issue')}
            END
        END
    END

Flag discrepancies that indicate out-of-band changes
    [Documentation]    Flag discrepancies that indicate out-of-band changes
    [Tags]    azure    flag-discrepancies-that-indicate-out-of-band-changes    auto-generated
    ${result}=    RW.CLI.Run Bash File
    ...    bash_file=flag_discrepancies_that_indicate_out_of_band_changes.sh
    ...    env=${env}
    ...    include_in_history=false
    RW.Core.Add Pre To Report    ${result.stdout}
    
    # Parse results and create issues if needed
    ${issues}=    RW.CLI.Run CLI    cat ${OUTPUT_DIR}/results.json | jq -r '.issues[]'
    IF    "${issues.stdout}" != ""
        ${issue_count}=    RW.CLI.Run CLI    cat ${OUTPUT_DIR}/results.json | jq '.issues | length'
        RW.Core.Add To Report    Found ${issue_count.stdout} issues
        
        # Add each issue
        ${parsed_issues}=    RW.CLI.Run CLI    cat ${OUTPUT_DIR}/results.json | jq -c '.issues[]'
        FOR    ${issue_line}    IN    @{parsed_issues.stdout.split('\n')}
            IF    "${issue_line}" != ""
                ${issue}=    Evaluate    json.loads('${issue_line}')    json
                RW.Core.Add Issue
                ...    severity=${issue.get('severity', 3)}
                ...    title=${issue.get('title', 'Issue Detected')}
                ...    details=${issue.get('details', 'No details available')}
                ...    next_steps=${issue.get('next_steps', 'Please investigate the reported issue')}
            END
        END
    END

- Confirm traffic flow from each subnet by testing NSG and VNet rule enforcement
    [Documentation]    - Confirm traffic flow from each subnet by testing NSG and VNet rule enforcement
    [Tags]    azure    --confirm-traffic-flow-from-each-subnet-by-testing-nsg-and-vnet-rule-enforcement    auto-generated
    ${result}=    RW.CLI.Run Bash File
    ...    bash_file=_confirm_traffic_flow_from_each_subnet_by_testing_nsg_and_vnet_rule_enforcement.sh
    ...    env=${env}
    ...    include_in_history=false
    RW.Core.Add Pre To Report    ${result.stdout}
    
    # Parse results and create issues if needed
    ${issues}=    RW.CLI.Run CLI    cat ${OUTPUT_DIR}/results.json | jq -r '.issues[]'
    IF    "${issues.stdout}" != ""
        ${issue_count}=    RW.CLI.Run CLI    cat ${OUTPUT_DIR}/results.json | jq '.issues | length'
        RW.Core.Add To Report    Found ${issue_count.stdout} issues
        
        # Add each issue
        ${parsed_issues}=    RW.CLI.Run CLI    cat ${OUTPUT_DIR}/results.json | jq -c '.issues[]'
        FOR    ${issue_line}    IN    @{parsed_issues.stdout.split('\n')}
            IF    "${issue_line}" != ""
                ${issue}=    Evaluate    json.loads('${issue_line}')    json
                RW.Core.Add Issue
                ...    severity=${issue.get('severity', 3)}
                ...    title=${issue.get('title', 'Issue Detected')}
                ...    details=${issue.get('details', 'No details available')}
                ...    next_steps=${issue.get('next_steps', 'Please investigate the reported issue')}
            END
        END
    END

- Query activity logs to identify whether firewall/NSG changes were pushed through CI/CD pipeline vs. manual actors
    [Documentation]    - Query activity logs to identify whether firewall/NSG changes were pushed through CI/CD pipeline vs. manual actors
    [Tags]    azure    --query-activity-logs-to-identify-whether-firewall/nsg-changes-were-pushed-through-ci/cd-pipeline-vs.-manual-actors    auto-generated
    ${result}=    RW.CLI.Run Bash File
    ...    bash_file=_query_activity_logs_to_identify_whether_firewallnsg_changes_were_pushed_through_cicd_pipeline_vs_manual_actors.sh
    ...    env=${env}
    ...    include_in_history=false
    RW.Core.Add Pre To Report    ${result.stdout}
    
    # Parse results and create issues if needed
    ${issues}=    RW.CLI.Run CLI    cat ${OUTPUT_DIR}/results.json | jq -r '.issues[]'
    IF    "${issues.stdout}" != ""
        ${issue_count}=    RW.CLI.Run CLI    cat ${OUTPUT_DIR}/results.json | jq '.issues | length'
        RW.Core.Add To Report    Found ${issue_count.stdout} issues
        
        # Add each issue
        ${parsed_issues}=    RW.CLI.Run CLI    cat ${OUTPUT_DIR}/results.json | jq -c '.issues[]'
        FOR    ${issue_line}    IN    @{parsed_issues.stdout.split('\n')}
            IF    "${issue_line}" != ""
                ${issue}=    Evaluate    json.loads('${issue_line}')    json
                RW.Core.Add Issue
                ...    severity=${issue.get('severity', 3)}
                ...    title=${issue.get('title', 'Issue Detected')}
                ...    details=${issue.get('details', 'No details available')}
                ...    next_steps=${issue.get('next_steps', 'Please investigate the reported issue')}
            END
        END
    END

**Detect Manual NSG Changes**
    [Documentation]    **Detect Manual NSG Changes**
    [Tags]    azure    **detect-manual-nsg-changes**    auto-generated
    ${result}=    RW.CLI.Run Bash File
    ...    bash_file=detect_manual_nsg_changes.sh
    ...    env=${env}
    ...    include_in_history=false
    RW.Core.Add Pre To Report    ${result.stdout}
    
    # Parse results and create issues if needed
    ${issues}=    RW.CLI.Run CLI    cat ${OUTPUT_DIR}/results.json | jq -r '.issues[]'
    IF    "${issues.stdout}" != ""
        ${issue_count}=    RW.CLI.Run CLI    cat ${OUTPUT_DIR}/results.json | jq '.issues | length'
        RW.Core.Add To Report    Found ${issue_count.stdout} issues
        
        # Add each issue
        ${parsed_issues}=    RW.CLI.Run CLI    cat ${OUTPUT_DIR}/results.json | jq -c '.issues[]'
        FOR    ${issue_line}    IN    @{parsed_issues.stdout.split('\n')}
            IF    "${issue_line}" != ""
                ${issue}=    Evaluate    json.loads('${issue_line}')    json
                RW.Core.Add Issue
                ...    severity=${issue.get('severity', 3)}
                ...    title=${issue.get('title', 'Issue Detected')}
                ...    details=${issue.get('details', 'No details available')}
                ...    next_steps=${issue.get('next_steps', 'Please investigate the reported issue')}
            END
        END
    END

*** Keywords ***
Suite Initialization
    RW.Core.Import Service    bash
    RW.Core.Import Service    k8s
    RW.Core.Import Service    curl
    Set Suite Variable    ${OUTPUT_DIR}    /tmp/rwi_output
    Create Directory    ${OUTPUT_DIR}
