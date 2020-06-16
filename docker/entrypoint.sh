#!/bin/bash

az account list --output table

POLICY_FILE=$1

if [ -z ${POLICY_FILE+x} ]; then
  echo "set"${POLICY_FILE}
  bash /usr/src/app/src/purge-history.sh /usr/src/app/policies/${POLICY_FILE}
else
  echo "notset"
  for policy in /usr/src/app/policies/*.env
  do
    [[ ! -e ${policy} ]] && continue  # continue, if file does not exist
    echo ${policy}
    bash /usr/src/app/src/purge-history.sh ${policy}
  done
fi
