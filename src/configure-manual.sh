#!/usr/bin/env bash

### DESCRIPTION
# This script create a .env file.
# All variables are catched from env variables setted by Azure DevOps parameters.
#
# Input: 
# $1: path to .env file to create
#
# Steps:
# 1. write variables to .env file

CONF_FILE=$1

echo "STORAGE_ACCOUNT=""'${STORAGE_ACCOUNT}'" > ${CONF_FILE}

echo "TASK_HUB=""'${TASK_HUB}'" >> ${CONF_FILE}

if [ "${NO_DATE_FILTER^^}" = TRUE ]; then
  echo "DAYS_BEFORE=""'+1'" >> ${CONF_FILE}
else
  echo "DAYS_BEFORE=""'${DAYS_BEFORE}'" >> ${CONF_FILE}
fi

if [ "${NO_STATUS_FILTER^^}" = TRUE ]; then
  echo "LIST_STATUS='completed terminated canceled failed'" >> ${CONF_FILE}
else
  echo "LIST_STATUS=""'${LIST_STATUS}'" >> ${CONF_FILE}
fi
