#!/usr/bin/env bash

CONF_FILE=$1

if [ ! -f "${CONF_FILE}" ]; then
  echo "--- ERROR --- ${CONF_FILE} does not exist"
  exit 1
fi

# load env variables
source ${CONF_FILE}

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
  echo "--- INFO --- purge-history DRY RUN"
  output=$(func durable get-instances \
          --connection-string-setting ${STORAGE_ACCOUNT}"_STORAGE" \
          --task-hub-name ${TASK_HUB} \
          --created-before ${DATE_BEFORE} \
          --runtime-status ${LIST_STATUS} 2>&1)
else
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
else
  echo "--- ERROR --- purge-history FAIL"
  exit 1
fi

echo "--- INFO --- END PURGE HISTORY STORAGE ACCOUNT: "${STORAGE_ACCOUNT}

# remove local.settings.json
rm local.settings.json
