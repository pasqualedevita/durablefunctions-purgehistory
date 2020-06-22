# durablefunctions-purgehistory

This repository contains the Azure pipelines to purge durable functions history using the [Azure Functions Core Tools](https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local).

It includes two pipelines:
1. azure-pipelines-policies.yml: pipeline that apply policy files with .env in policies folder
1. azure-pipelines-custom.yml: pipeline with specified parameters, policies folder is ignored

Policies pipeline is scheduled to run every night.

Azure pipeline overview: https://dev.azure.com/pagopa-io/durablefunctions-purgehistory

azure-pipelines-policies.yml  
[![Build Status](https://dev.azure.com/pagopa-io/durablefunctions-purgehistory/_apis/build/status/pagopa.df-purgehistory-policies?branchName=master)](https://dev.azure.com/pagopa-io/durablefunctions-purgehistory/_build/latest?definitionId=22&branchName=master)

azure-pipelines-custom.yml  
[![Build Status](https://dev.azure.com/pagopa-io/durablefunctions-purgehistory/_apis/build/status/pagopa.df-purgehistory-custom?branchName=master)](https://dev.azure.com/pagopa-io/durablefunctions-purgehistory/_build/latest?definitionId=23&branchName=master)

## Repo structure

    .
    ├── dummy-project                     # dummy project used by Azure Functions Core Tools
    │   └── host.json
    ├── policies                          # policies folder, specify here the policy in .env files
    │   └── ...
    └── src                               # scripts folder
        ├── configure-custom.sh           # create an .env file for custom executions
        └── purge-history.sh              # purge history script

## Sample policy

```bash
STORAGE_ACCOUNT='set_storage_account'
TASK_HUB='set_task_hub'
# number of days to apply date filter (negative -> past, positive -> future)
DAYS_BEFORE='-30'
# Can provide multiple (space separated) statuses: completed terminated canceled failed
LIST_STATUS='completed'
# Optional you can override DRY_RUN variable
# DRY_RUN='True'
```

## Azure role assignments

This pipeline requires to assign the role Storage Account Contributor into targets storage accounts.

## Run on local machine

Requirements:
1. [az cli](https://docs.microsoft.com/it-it/cli/azure/install-azure-cli)
1. [Azure Functions Core Tools](https://docs.microsoft.com/en-us/azure/azure-functions/functions-run-local)
1. [jq](https://stedolan.github.io/jq/download)

### 1. Login with azure cli

```bash
az login
az account set --subscription "SET_SUBSCRIPTION"
az account list --output table
```

### 2. Run

```bash
cd durablefunctions-purgehistory
bash src/purge-history.sh policies/df-sample.env.sample
```

## Run with Docker from local machine

Requirements:
1. [az cli](https://docs.microsoft.com/it-it/cli/azure/install-azure-cli)
1. [docker](https://docs.docker.com/get-docker)

### 1. Build docker image

```bash
cd durablefunctions-purgehistory
docker build -t durablefunctions-purgehistory:v0.1 docker
```

### 2. Login with azure cli

```bash
az login
az account set --subscription "SET_SUBSCRIPTION"
az account list --output table
```

### 3. Run

```bash
# DRY_RUN='True' check only connections without apply any changes
# POLICY_FILE='df-sample.env.sample' apply only specified policy
# Empty POLICY_FILE apply policy files with .env in policies folder

cd durablefunctions-purgehistory
docker run --rm -it \
       -v ${HOME}/.azure:/root/.azure \
       -v ${PWD}:/usr/src/app \
       -e DRY_RUN='True' \
       -e POLICY_FILE='df-sample.env.sample' \
       durablefunctions-purgehistory:v0.1
```

## known issues

Running on local machine you can get in an error with az cli access token with expired UTC time.

https://github.com/Azure/azure-cli/issues/4722

https://github.com/Azure/azure-powershell/issues/6585

As workaround, run an az command without parameters to refresh the token.

```bash
# sample command to refresh access token
az account list-locations
```

## License
Please refer to [IO license agreement](https://github.com/pagopa/io-app/blob/master/LICENSE).
