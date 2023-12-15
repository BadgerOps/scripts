#!/bin/bash
#
# Sometimes, in a throttled/break & inspect environment oc-mirror will not recover from RST or timeout
# It will fail with a 401 unauthorized and exit 1
# So, lets run this in a loop and re-try when that happens

# Default values
ROOT_DIRECTORY="/var/oc-mirror" # Set to your oc-mirror root directory
CONFIG_FILE="${ROOT_DIRECTORY}/imageset.yaml"
DESTINATION_DIR="${ROOT_DIRECTORY}/oc-mirror"
LOG_FILE="${ROOT_DIRECTORY}/logs/$(date +%Y-%m-%d).log"
DEBUG=false

print_help(){
  echo "Usage: $0 [-c config file] [-d destination directory] [-l log file] [--debug]"
}
# Main script
set -e  # Exit on error

# Parse command line options
while [[ $# -gt 0 ]]; do
    case "$1" in
        -c)
            CONFIG_FILE="$2"
            shift 2
            ;;
        -d)
            DESTINATION_DIR="$2"
            shift 2
            ;;
        -l)
            LOG_FILE="$2"
            shift 2
            ;;
        --debug)
            DEBUG=true
            shift
            ;;
        -h|--help)
            print_help
            exit 0
            ;;
        *)
            print_help
            exit 1
            ;;
    esac
done

# Set up lock file based off script name
script_name=$(basename "$0")
lock_file="/var/tmp/${script_name}.lock"

# Check if the script is already running
if [ -f "$lock_file" ]; then
    echo "Another instance of the script is running as of $(date +%Y-%m-%d-%H_%M). Exiting."
    exit 0
else
  echo "Starting oc-mirror-wrapper script at $(date +%Y-%m-%d-%H_%M)"
fi

# Create lock file
touch "$lock_file"

# Enable debug mode if specified
if [ "$DEBUG" = true ]; then
    OC_MIRROR_DEBUG="-v 9"
    set -x
fi

# Start time and datestamp
start_time=$(date +%s)
echo "oc-mirror script started at $(date)" >> "${LOG_FILE}"

# Function to run oc-mirror and check its exit status
run_oc_mirror() {
  if [ "$DEBUG" = true ]; then
    /usr/local/bin/oc-mirror ${OC_MIRROR_DEBUG} --config "${CONFIG_FILE}" file://"${DESTINATION_DIR}" >> "${LOG_FILE}" 2>&1
    return $?
  else
    /usr/local/bin/oc-mirror --config "${CONFIG_FILE}" file://"${DESTINATION_DIR}" >> "${LOG_FILE}" 2>&1
    return $?
  fi
}

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

if [ $status -ne 0 ]; then
  echo "oc-mirror failed after $max_attempts attempts." >> "${LOG_FILE}"
  exit $status
fi

exit 0
