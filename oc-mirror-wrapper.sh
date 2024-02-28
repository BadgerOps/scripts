#!/usr/bin/bash
#
# Sometimes, in a throttled/break & inspect environment oc-mirror will not recover from RST or timeout
# It will fail with a 401 unauthorized and exit 1
# So, lets run this in a loop and re-try when that happens

# First, set umask to 0022 to resolve the issues annotated in https://github.com/openshift/oc-mirror/issues/802
umask 0022

# Default values
OC_MIRROR_PATH="/usr/bin/oc-mirror" # override if you have a specific OC Mirror version to use
CONFIG_FILE=""
DESTINATION_DIR=""
LOG_DIR="/var/quay/logs/"
# Parse command-line arguments
while getopts 'c:d:l' flag; do
  case "${flag}" in
    c) CONFIG_FILE="${OPTARG}" ;;
    d) DESTINATION_DIR="${OPTARG}" ;;
    l) LOG_DIR="${OPTARG}" ;;
    --ocpath) OC_MIRROR_PATH="${OPTARG}" ;;
    --debug) DEBUG=true ;;
    *) echo "Usage: $0 [-c CONFIG_FILE] [-d DESTINATION_DIR] [-l LOG_DIR] [--debug turns on debug] [ --ocpath /path/to/oc-mirror ]" >&2
       exit 1 ;;
  esac
done

# turn on -x if we're debuggin'
if [ "$DEBUG" = true ]; then
  set -x
fi

if [ -z $CONFIG_FILE ]; then
  echo "Please set -c or \$CONFIG_FILE"
  exit 1
fi

if [ -z $DESTINATION_DIR ]; then
  echo "Please set -d or \$DESTINATION_DIR"
  exit 1
fi

# re-set log dir:
LOG_DIR="${DESTINATION_DIR}/logs/$(date +%Y-%m-%d-%H_%M)"
mkdir -p ${DESTINATION_DIR}logs
# Script name for lock file
script_name=$(basename "$0")
lock_file="${DESTINATION_DIR}/${script_name}.lock"

# Check if the script is already running
if [ -f "$lock_file" ]; then
    echo "Another instance of the script is running as of $(date +%Y-%m-%d-%H_%M). Exiting."
    exit 1
else
  echo "Starting oc-mirror-wrapper script at $(date +%Y-%m-%d-%H_%M)"
fi

# Create lock file
touch "$lock_file"

# Function to run oc-mirror and check its exit status
run_oc_mirror() {
  if [ "$DEBUG" = true ]; then
    ${OC_MIRROR_PATH} -v 9 --skip-missing --continue-on-error --config "${CONFIG_FILE}" file://"${DESTINATION_DIR}" >> "${LOG_DIR}" 2>&1
    return $?
  else
    echo "starting mirror without verbose logging to ${LOG_DIR}"
    ${OC_MIRROR_PATH} --skip-missing --continue-on-error --config "${CONFIG_FILE}" file://"${DESTINATION_DIR}" >> "${LOG_DIR}" 2>&1
    return $?
  fi
}

# Start time and datestamp
start_time=$(date +%s)
echo "oc-mirror script started at $(date)" >> "${LOG_DIR}"

# Attempt to run oc-mirror and retry if it fails
max_attempts=10
attempt=1

while [ $attempt -le $max_attempts ]; do
  echo "Attempt $attempt of $max_attempts: Running oc-mirror..." >> "${LOG_DIR}"
  run_oc_mirror
  status=$?

  if [ $status -eq 0 ]; then
    echo "oc-mirror completed successfully." >> "${LOG_DIR}"
    break
  else
    echo "oc-mirror failed with status $status. Retrying..." >> "${LOG_DIR}"
    ((attempt++))
    sleep 60 # Wait for 10 seconds before retrying
  fi
done

# End time and total duration
end_time=$(date +%s)
total_duration=$((end_time - start_time))

echo "oc-mirror script ended at $(date)" >> "${LOG_DIR}"
echo "Total time taken: $total_duration seconds." >> "${LOG_DIR}"

rm -f "$lock_file"

if [ $status -ne 0 ]; then
  echo "oc-mirror failed after $max_attempts attempts." >> "${LOG_DIR}"
  exit $status
fi

exit 0
