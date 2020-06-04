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

POLICY_FILE=$1

echo "STORAGE_ACCOUNT=""'${STORAGE_ACCOUNT}'" > ${POLICY_FILE}

echo "TASK_HUB=""'${TASK_HUB}'" >> ${POLICY_FILE}

# to uppercase
if [ "${NO_DATE_FILTER^^}" = TRUE ]; then
  echo "DAYS_BEFORE=""'+1'" >> ${POLICY_FILE}
else
  echo "DAYS_BEFORE=""'${DAYS_BEFORE}'" >> ${POLICY_FILE}
fi

# to uppercase
if [ "${NO_STATUS_FILTER^^}" = TRUE ]; then
  echo "LIST_STATUS='completed terminated canceled failed'" >> ${POLICY_FILE}
else
  echo "LIST_STATUS=""'${LIST_STATUS}'" >> ${POLICY_FILE}
fi
