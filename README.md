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
```

## Azure role assignments

This pipeline requires to assign the role Storage Account Contributor into targets storage accounts.

## License
Please refer to [IO license agreement](https://github.com/pagopa/io-app/blob/master/LICENSE).
