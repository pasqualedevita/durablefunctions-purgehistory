#!/usr/bin/env bash

### DESCRIPTION
# This script purge durable function history with specified variables.
# To avoid possible console log data exposure, all outputs commands are catched
#
# Input: 
# $1: path to .env file variables
#
# Steps:
# 1. check .env file exists and load parameters
# 2. check taskhub table exists
# 3. calculate ${DATE_BEFORE}
# 4. get connection string to storage account and save it in temporary local.settings.json
# 5. purge orchestrators history with specified parameters
# 6. delete temporary local.settings.json

POLICY_FILE=$1

if [ ! -f "${POLICY_FILE}" ]; then
  echo "--- ERROR --- policy file ${POLICY_FILE} does not exist"
  exit 1
fi

# load env variables
source ${POLICY_FILE}

# check taskhub table exists
# TODO: check all azure resource that create a function app
connectionString=$(az storage account show-connection-string --name ${STORAGE_ACCOUNT} --query 'connectionString' 2>&1)

exit_status=$?
if [ "${exit_status}" -ne 0 ]; then
  echo "--- ERROR --- az storage account show-connection-string FAIL"
  exit 1
fi

output=$(az storage table exists --name ${TASK_HUB}Instances --account-name ${STORAGE_ACCOUNT} --connection-string $connectionString --query 'exists' 2>&1)

exit_status=$?
if [ "${exit_status}" -ne 0 ]; then
  echo "--- ERROR --- az storage table exists FAIL"
  exit 1
fi

if [ "${output^^}" = FALSE ]; then
  echo "--- ERROR --- table ${TASK_HUB}Instances does not exists"
  exit 1
fi

echo "--- INFO --- policy file "${POLICY_FILE}
cat ${POLICY_FILE}

DATE_BEFORE=$(date -I -d "${DAYS_BEFORE} days")
echo "--- INFO --- DATE BEFORE: "$DATE_BEFORE

echo "--- INFO --- START PURGE HISTORY STORAGE ACCOUNT: "${STORAGE_ACCOUNT}
  
cd dummy-project
# create empty local.settings.json
touch local.settings.json

# add a local app setting using the value from an Azure Storage account. Requires Azure login.
output=$(func azure storage fetch-connection-string ${STORAGE_ACCOUNT} 2>&1)

exit_status=$?
if [ "${exit_status}" -eq 0 ]; then
  echo "--- INFO --- fetch-connection-string OK"
else
  echo "--- ERROR --- fetch-connection-string FAIL"
  exit 1
fi

# purge orchestration instance state, history, and blob storage for orchestrations older than the specified threshold time.
if [ "${DRY_RUN^^}" = TRUE ]; then
  # dry run
  echo "--- INFO --- purge-history DRY RUN"
  output=$(func durable get-instances \
          --connection-string-setting ${STORAGE_ACCOUNT}"_STORAGE" \
          --task-hub-name ${TASK_HUB} \
          --created-before ${DATE_BEFORE} \
          --runtime-status ${LIST_STATUS} 2>&1)
else
  # real execution
  echo "--- INFO --- purge-history"
  # func durable purge-history \
  output=$(func durable get-instances \
          --connection-string-setting ${STORAGE_ACCOUNT}"_STORAGE" \
          --task-hub-name ${TASK_HUB} \
          --created-before ${DATE_BEFORE} \
          --runtime-status ${LIST_STATUS} 2>&1)
fi

exit_status=$?
if [ "${exit_status}" -eq 0 ]; then
  echo "--- INFO --- purge-history OK"
  # remove local.settings.json
  rm local.settings.json
else
  echo "--- ERROR --- purge-history FAIL"
  # remove local.settings.json
  rm local.settings.json
  exit 1
fi

echo "--- INFO --- END PURGE HISTORY STORAGE ACCOUNT: "${STORAGE_ACCOUNT}
