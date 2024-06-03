*** Settings ***
Documentation       This codebundle runs a series of tasks to identify potential helm release issues. Uses the Helm CLI. Requires secret read. 
Metadata            Author    stewartshea
Metadata            Display Name    Kubernetes Helm Release Health
Metadata            Supports    GKE,AKS,EKS,Helm,Kubernetes

Library             BuiltIn
Library             RW.Core
Library             RW.CLI
Library             RW.platform
Library             OperatingSystem

Suite Setup         Suite Initialization

*** Tasks ***
Get all Helm release `${HELMRELEASE}` details in Namespace `${NAMESPACE}` and Add to Report
    [Documentation]    Get Helm valies, manifests, and metadata and add to Report.    
    [Tags]        Helmrelease     Available    List    ${NAMESPACE}    ${HELMRELEASE}
    ${helmrelease_details}=    RW.CLI.Run Cli
    ...    cmd=helm get all ${HELMRELEASE} -n ${NAMESPACE} --kube-context ${CONTEXT}
    ...    env=${env}
    ...    secret_file__kubeconfig=${KUBECONFIG}
    ...    show_in_rwl_cheatsheet=true
    # ${helmrelease_details}=    RW.CLI.Run Bash File
    # ...    bash_file=check_helm.sh
    # ...    cmd_override=./check_helm.sh get all ${CONTEXT} ${HELMRELEASE}
    # ...    env=${env}
    # ...    secret_file__kubeconfig=${KUBECONFIG}
    # ...    show_in_rwl_cheatsheet=true

*** Keywords ***
Suite Initialization
    ${kubeconfig}=    RW.Core.Import Secret
    ...    kubeconfig
    ...    type=string
    ...    description=The kubernetes kubeconfig yaml containing connection configuration used to connect to cluster(s).
    ...    pattern=\w*
    ...    example=For examples, start here https://kubernetes.io/docs/concepts/configuration/organize-cluster-access-kubeconfig/
    ${KUBERNETES_DISTRIBUTION_BINARY}=    RW.Core.Import User Variable    KUBERNETES_DISTRIBUTION_BINARY
    ...    type=string
    ...    description=Which binary to use for Kubernetes CLI commands.
    ...    enum=[kubectl,oc]
    ...    example=kubectl
    ...    default=kubectl
    ${NAMESPACE}=    RW.Core.Import User Variable    NAMESPACE
    ...    type=string
    ...    description=The name of the Kubernetes namespace to scope actions and searching to. Accepts a single namespace in the format `-n namespace-name` or `--all-namespaces`. 
    ...    pattern=\w*
    ...    example=-n my-namespace
    ...    default=--all-namespaces
    ${HELMRELEASE}=    RW.Core.Import User Variable    HELMRELEASE
    ...    type=string
    ...    description=The name of the Helm release to debug. 
    ...    pattern=\w*
    ...    example=my-release
    ${CONTEXT}=    RW.Core.Import User Variable    CONTEXT
    ...    type=string
    ...    description=Which Kubernetes context to operate within.
    ...    pattern=\w*
    ...    default=default
    ...    example=my-main-cluster
    Set Suite Variable    ${KUBERNETES_DISTRIBUTION_BINARY}    ${KUBERNETES_DISTRIBUTION_BINARY}
    Set Suite Variable    ${kubeconfig}    ${kubeconfig}
    Set Suite Variable    ${HELMRELEASE}    ${HELMRELEASE}
    Set Suite Variable    ${NAMESPACE}    ${NAMESPACE}
    Set Suite Variable    ${env}    {"KUBECONFIG":"./${kubeconfig.key}"}