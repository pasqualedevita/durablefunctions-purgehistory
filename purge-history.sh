#!/usr/bin/env bash

CONF_FILE=$1

if [ ! -f "${CONF_FILE}" ]; then
  echo "--- ERROR --- ${CONF_FILE} does not exist"
  exit 1
fi

source ${CONF_FILE}

DATE_BEFORE=$(date -I -d "-${DAYS_BEFORE} days")
echo "--- INFO --- DATE BEFORE: "$DATE_BEFORE

echo "--- INFO --- START PURGE HISTORY STORAGE ACCOUNT: "${STORAGE_ACCOUNT}
  
cd dummy-project
ls -la
# create empty local.settings.json
touch local.settings.json

# Add a local app setting using the value from an Azure Storage account. Requires Azure login.
func azure storage fetch-connection-string ${STORAGE_ACCOUNT}

# Purge orchestration instance state, history, and blob storage for orchestrations older than the specified threshold time.
# func durable purge-history \
func durable get-instances \
  --connection-string-setting ${STORAGE_ACCOUNT}"_STORAGE" \
  --task-hub-name ${TASK_HUB} \
  --created-before ${DATE_BEFORE} \
  --runtime-status ${LIST_STATUS}

echo "--- INFO --- END PURGE HISTORY STORAGE ACCOUNT: "${STORAGE_ACCOUNT}

# remove local.settings.json
rm local.settings.json
