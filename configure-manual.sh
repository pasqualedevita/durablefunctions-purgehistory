#!/usr/bin/env bash

CONF_FILE=$1

if [ ! -f "${CONF_FILE}" ]; then
  echo "--- ERROR --- ${CONF_FILE} does not exist"
  exit 1
fi

echo STORAGE_ACCOUNT=${{ parameters.STORAGE_ACCOUNT }} >> ${CONF_FILE}

echo TASK_HUB=${{ parameters.TASK_HUB }} >> ${CONF_FILE}

if [ ${{ parameters.NO_DATE_FILTER }} ]; then
  echo "DAYS_BEFORE=+1" >> df-conf/manual.env
else
  echo "DAYS_BEFORE="${{ parameters.DAYS_BEFORE }} >> ${CONF_FILE}
fi

if [ ${{ parameters.NO_STATUS_FILTER }} ]; then
  echo "LIST_STATUS=completed terminated canceled failed" >> ${CONF_FILE}
else
  echo LIST_STATUS=${{ parameters.LIST_STATUS }} >> ${CONF_FILE}
fi