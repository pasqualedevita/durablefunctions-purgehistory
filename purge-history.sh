#!/usr/bin/env bash

CONF_DIR="df-conf"
DATE_BEFORE=$(date -I -d "-${DAYS_BEFORE} days")
echo "--- INFO --- DATE BEFORE: "$DATE_BEFORE

for entry in "${CONF_DIR}"/*
do

  source $entry

  echo "--- INFO --- START PURGE HISTORY STORAGE ACCOUNT: " ${STORAGE_ACCOUNT}

  cd dummy-project
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

  echo "--- INFO --- END PURGE HISTORY STORAGE ACCOUNT: " ${STORAGE_ACCOUNT}

  # remove local.settings.json
  rm local.settings.json
  cd ..

done
