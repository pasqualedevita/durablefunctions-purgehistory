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
# 5. purge orchestrators history with specified parameters or run dry-run
# 6. delete temporary local.settings.json

### Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color
SPACES='\n'

POLICY_FILE=$1

function delete_sensitive_information {
  rm local.settings.json
  rm -rf azure-functions-core-tools
}

function dry_run_result {
  output="$@"
  substring='Continuation token for next set of results: '
  emptystring=''
  resultclean=`echo "${output/$substring*/$emptystring}"`
  continuation_token=${output#*$substring}
  count=`jq length <<< "${resultclean}"`
  echo -e ${SPACES}
  echo -e "--- INFO --- ${GREEN}estimated instances: ${count}${NC}"
}

function check_os {
  unameOut="$(uname -s)"
  case "${unameOut}" in
    Linux*)
      echo -e ${SPACES}
      echo "--- INFO --- current OS ${unameOut}"
      ;;
    Darwin*)
      echo -e ${SPACES}
      echo "--- INFO --- current OS ${unameOut}"
      ;;
    *)
      echo -e ${SPACES}
      echo -e "--- ERROR --- ${GREEN}OS ${unameOut} not supported${NC}"
      exit 1
  esac
}

function check_policy_file {
  if [ ! -f "${POLICY_FILE}" ]; then
    echo -e ${SPACES}
    echo -e "--- ERROR --- ${RED}policy file ${POLICY_FILE} does not exist${NC}"
    exit 1
  fi
}

function load_policy_file {
  # load env variables
  source ${POLICY_FILE}
  echo -e ${SPACES}
  echo -e "--- INFO --- using policy file: ${GREEN}${POLICY_FILE}${NC}"
  echo -e ${SPACES}
  cat ${POLICY_FILE}
}

function check_taskhub_table {
  # check taskhub table exists
  # TODO: check all azure resource that create a function app
  connectionString=$(az storage account show-connection-string --name ${STORAGE_ACCOUNT} --query 'connectionString' 2>&1)

  exit_status=$?
  if [ "${exit_status}" -ne 0 ]; then
    echo -e ${SPACES}
    echo -e "--- ERROR --- ${RED}az storage account show-connection-string FAIL${NC}"
    exit 1
  fi

  output=$(az storage table exists --name ${TASK_HUB}Instances --account-name ${STORAGE_ACCOUNT} --connection-string $connectionString --query 'exists' 2>&1)

  exit_status=$?
  if [ "${exit_status}" -ne 0 ]; then
    echo -e ${SPACES}
    echo -e "--- ERROR --- ${RED}az storage table exists FAIL${NC}"
    exit 1
  fi

  if [ "${output^^}" = FALSE ]; then
    echo -e ${SPACES}
    echo -e "--- ERROR --- ${RED}table ${TASK_HUB}Instances does not exists${NC}"
    exit 1
  fi
}

function calculate_date {
  case "${unameOut}" in
    Linux*)
      DATE_BEFORE=$(date -I -d "${DAYS_BEFORE} days")
      ;;
    Darwin*)
      DATE_BEFORE=$(date -v ${DAYS_BEFORE}d "+%Y-%m-%d")
      ;;
    *)
      echo -e ${SPACES}
      echo -e "--- ERROR --- ${RED}OS ${unameOut} not supported${NC}"
      exit 1
  esac

  echo -e ${SPACES}
  echo -e "--- INFO --- created instances with date before: ${GREEN}${DATE_BEFORE}${NC}"
}

function get_dry_run_continuation_token {

  response="$@"
  # truncate response to speedup regex
  # last 1000 characters are enough to contains the continuation token expected expression
  response_truncated=${response:(-1000)}
  
  continuation_token_startstring='Continuation token for next set of results: '
  continuation_token=`echo "${response_truncated#*$continuation_token_startstring}"`
  # remove 2 ' from continuation_token
  continuation_token=`echo "${continuation_token//"'"}"`
  continuation_token_length=`echo ${#continuation_token}`

  if [[ ${continuation_token_length} == 0 ]]; then
      echo -e "--- ERROR --- ${RED}unexpected continuation-token${NC}"
      exit 1
  fi
  
  if [[ ${continuation_token} == 'bnVsbA==' ]]; then
    continuation_token=`echo ${continuation_token} | base64 --decode`
  fi
  
}

function get_dry_run_instences_count {
  
  response="$@"

  response_clean=${response%]*}
  # previous regex command remove last ], next command add removed ]
  response_clean=${response_clean}"]"

  count_instances=`jq length <<< "${response_clean}"`
  count_instances_tot=$((count_instances_tot + count_instances))

  echo -e ${SPACES}
  echo -e "--- INFO --- retrivied instances: ${count_instances}${NC}"

}

function execute_dry_run {

  echo -e ${SPACES}
  echo -e "--- INFO --- executing ${GREEN}dry-run${NC}"
  count_instances_tot=0
  top=1000

  output=$(func durable get-instances \
        --connection-string-setting ${STORAGE_ACCOUNT}"_STORAGE" \
        --task-hub-name ${TASK_HUB} \
        --created-before ${DATE_BEFORE} \
        --runtime-status ${LIST_STATUS} \
        --top ${top} 2>&1)
  exit_status=$?

  while : ; do

      if [ "${exit_status}" -eq 0 ]; then

        get_dry_run_continuation_token $output

        get_dry_run_instences_count $output

        if [ $continuation_token == 'null' ]; then
          # no more instances 
          break
        fi

      else

        echo -e ${SPACES}
        echo -e "--- ERROR --- ${RED}purge-history FAIL${NC}"
        # remove sensitive information
        delete_sensitive_information
        exit 1

      fi
      
      output=$(func durable get-instances \
        --connection-string-setting ${STORAGE_ACCOUNT}"_STORAGE" \
        --task-hub-name ${TASK_HUB} \
        --created-before ${DATE_BEFORE} \
        --runtime-status ${LIST_STATUS} \
        --top ${top} \
        --continuation-token ${continuation_token} 2>&1)
      exit_status=$?

      [[ false ]] || break
  done

  echo -e ${SPACES}
  echo -e "--- INFO --- estimated instances: ${GREEN}${count_instances_tot}${NC}"
  echo -e "--- INFO --- list statuses: ${GREEN}${LIST_STATUS}${NC}"
  # remove sensitive information
  delete_sensitive_information
}

function execute_purge {
  echo -e ${SPACES}
  echo -e "--- INFO --- executing ${GREEN}purge-history${NC}"
  output=$(func durable purge-history \
        --connection-string-setting ${STORAGE_ACCOUNT}"_STORAGE" \
        --task-hub-name ${TASK_HUB} \
        --created-before ${DATE_BEFORE} \
        --runtime-status ${LIST_STATUS} 2>&1)

  exit_status=$?
  if [ "${exit_status}" -eq 0 ]; then
    echo -e ${SPACES}
    echo -e "--- INFO --- purge-history ok"
    # remove sensitive information
    delete_sensitive_information
    echo -e ${SPACES}
    echo ${output}
  else
    echo -e ${SPACES}
    echo -e "--- ERROR --- ${RED}purge-history FAIL${NC}"
    # remove cachesd items
    delete_sensitive_information
    exit 1
  fi
}

function purge_history {
  echo -e ${SPACES}
  echo -e "--- INFO --- start execution for storage account: ${GREEN}${STORAGE_ACCOUNT}${NC}"
  
  cd dummy-project
  # create empty local.settings.json
  touch local.settings.json

  # clear bin obj cache
  if [ "${NO_CACHE^^}" = TRUE ]; then
    # delete cache
    echo -e ${SPACES}
    echo "--- INFO --- delete cache"
    rm -rf bin
    rm -rf obj
  fi
  # rebuild project if bin folder does not exits
  if [ ! -d "bin/" ]; then
    # DOTNET_CLI_TELEMETRY_OPTOUT=1 do not send telemetry information to microsoft
    export DOTNET_CLI_TELEMETRY_OPTOUT=1
    dotnet publish -o bin
  fi

  # add a local app setting using the value from an Azure Storage account. Requires Azure login.
  output=$(func azure storage fetch-connection-string ${STORAGE_ACCOUNT} 2>&1)

  exit_status=$?
  if [ "${exit_status}" -eq 0 ]; then
    echo -e ${SPACES}
    echo "--- INFO --- fetch-connection-string"
  else
    echo -e ${SPACES}
    echo -e "--- ERROR --- ${RED}fetch-connection-string FAIL${NC}"
    exit 1
  fi

  # purge orchestration instance state, history, and blob storage for orchestrations older than the specified threshold time.
  if [ "${DRY_RUN^^}" = TRUE ]; then
    # dry run
    execute_dry_run
  else
    # real execution
    execute_purge
  fi

  echo -e ${SPACES}
  echo -e "--- INFO --- end execution for storage account: ${GREEN}${STORAGE_ACCOUNT}${NC}"
}

check_os

check_policy_file

load_policy_file

check_taskhub_table

calculate_date

purge_history
