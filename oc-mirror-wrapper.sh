#!/bin/bash

# Sometimes, in a throttled/break & inspect environment oc-mirror will not recover from RST, or we'll get a timeout
# It will fail with a 401 unauthorized and exit 1
# So, lets run this in a loop and re-try when that happens

# Just use the script name for lock file
script_name=$(basename "$0")
lock_file="/var/tmp/${script_name}.lock"

# Check if the script is already running
if [ -f "$lock_file" ]; then
    echo "Another instance of the script is running. Exiting."
    exit 1
fi

# Create lock file
touch "$lock_file"

# Default values, can override with CLI args if desired
CONFIG_FILE="/var/quay/imageset.yaml"
DESTINATION_DIR="/var/quay/oc-mirror"
LOG_FILE="/var/quay/logs/$(date +%Y-%m-%d).log"

# Parse command-line arguments
while getopts 'c:d:l:' flag; do
  case "${flag}" in
    c) CONFIG_FILE="${OPTARG}" ;;
    d) DESTINATION_DIR="${OPTARG}" ;;
    l) LOG_FILE="${OPTARG}" ;;
    *) echo "Usage: $0 [-c CONFIG_FILE] [-d DESTINATION_DIR] [-l LOG_FILE]" >&2
       exit 1 ;;
  esac
done

# Function to run oc-mirror and check its exit status
run_oc_mirror() {
  oc-mirror --config "${CONFIG_FILE}" file://"${DESTINATION_DIR}" >> "${LOG_FILE}" 2>&1
  return $?
}

# Start time and datestamp
start_time=$(date +%s)
echo "oc-mirror script started at $(date)" >> "${LOG_FILE}"

# Attempt to run oc-mirror and retry if it fails
max_attempts=10
attempt=1

while [ $attempt -le $max_attempts ]; do
  echo "Attempt $attempt of $max_attempts: Running oc-mirror..." >> "${LOG_FILE}"
  run_oc_mirror
  status=$?

  if [ $status -eq 0 ]; then
    echo "oc-mirror completed successfully." >> "${LOG_FILE}"
    break
  else
    echo "oc-mirror failed with status $status. Retrying..." >> "${LOG_FILE}"
    ((attempt++))
    sleep 60 # Wait for 10 seconds before retrying
  fi
done

# End time and total duration
end_time=$(date +%s)
total_duration=$((end_time - start_time))

echo "oc-mirror script ended at $(date)" >> "${LOG_FILE}"
echo "Total time taken: $total_duration seconds." >> "${LOG_FILE}"

# Finally, remove lock file
rm -f "$lock_file"

if [ $status -ne 0 ]; then
  echo "oc-mirror failed after $max_attempts attempts." >> "${LOG_FILE}"
  exit $status
fi

exit 0
