#!/bin/bash

if [[ -z ${POLICY_FILE} ]];
then
  for policy in /usr/src/app/policies/*.env
  do
    [[ ! -e ${policy} ]] && continue  # continue, if file does not exist
    echo ${policy}
    bash /usr/src/app/src/purge-history.sh ${policy}
  done
else
  bash /usr/src/app/src/purge-history.sh /usr/src/app/policies/${POLICY_FILE}
fi