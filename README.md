# durablefunctions-purgehistory

This repository contains the Azure pipelines to purge durable functions history.
It includes two pipelines:
1. azure-pipelines-policies.yml: pipeline that apply policy files with .env in policies folder
1. azure-pipelines-custom.yml: pipeline with specified parameters, policies folder is ignored

Policies pipeline is scheduled to run every night.

azure-pipelines-policies.yml  
[![Build Status](https://dev.azure.com/pasqdvt/df-purgehistory/_apis/build/status/df-purgehistory-policies?branchName=master)](https://dev.azure.com/pasqdvt/df-purgehistory/_build/latest?definitionId=1&branchName=master)

azure-pipelines-custom.yml  
[![Build Status](https://dev.azure.com/pasqdvt/df-purgehistory/_apis/build/status/df-purgehistory-custom?branchName=master)](https://dev.azure.com/pasqdvt/df-purgehistory/_build/latest?definitionId=2&branchName=master)

## Project structure

    .
    ├── dummy-project                     # dummy project used by Azure Functions Core Tools
    │   └── host.json
    ├── policies                          # policies folder, specify here the policy in .env files
    │   └── ...
    └── src                               # scripts folder
        ├── configure-custom.sh           # create an .env file for custom executions
        └── purge-history.sh              # purge history script

## Sample policy

Here a sample policy

```bash
STORAGE_ACCOUNT='set_storage_account'
TASK_HUB='set_task_hub'
# number of days to apply date filter (negative -> past, positive -> future)
DAYS_BEFORE='-30'
# Can provide multiple (space separated) statuses: completed terminated canceled failed
LIST_STATUS='completed'
```
