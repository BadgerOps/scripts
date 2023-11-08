#!/bin/bash

# For a single host
# ./racadm_script.sh -h <HOST_IP_OR_HOSTNAME> -u <USERNAME> -p <PASSWORD> -f <ISO_PATH> [--debug]

# For multiple hosts from a file
# ./racadm_script.sh -i hosts.txt -u <USERNAME> -p <PASSWORD>  -f <ISO_PATH> [--debug] [--restart-hosts]



# Function to unmount the old ISO
unmount_iso() {
    local password="$1"
    local host="$2"
    local username="$3"
    echo "Unmounting the old ISO on host $host..."
    racadm -r "$host" -u "$username" -p "$password" remoteimage -d
    echo "Old ISO unmounted on host $host."
}

# Function to mount a new ISO file
mount_iso() {
    local password="$1"
    local iso_path="$2"
    local host="$3"
    local username="$4"
    echo "Mounting a new ISO file from $iso_path on host $host..."
    racadm -r "$host" -u "$username" -p "$password" remoteimage -c -l "$iso_path"
    sleep 2
    racadm -r "$host" -u "$username" -p "$password" set iDRAC.VirtualMedia.BootOnce 1
    sleep 2
    racadm -r "$host" -u "$username" -p "$password" set iDrac.ServerBoot.FirstBootDevice VCD-DVD
    sleep 2
    echo "New ISO file mounted from $iso_path on host $host."
}

# Function to restart the host machine
restart_host() {
    local password="$1"
    local host="$2"
    local username="$3"
    echo "Restarting the host machine on host $host..."
    racadm -r "$host" -u "$username" -p "$password" serveraction powercycle
    echo "Host machine restarted on host $host."
}

# Function to restart the host machines (optional)
restart_hosts() {
    local password="$1"
    local input_file="$2"
    local username="$3"
    echo "Restarting the host machines..."
    while IFS= read -r host; do
        restart_host "$password" "$host" "$username"
    done < "$input_file"
}

print_help(){
  echo "Usage: $0 [-h host] [-i host_file] [-u username] [-p password] [-f iso path] [--debug] [--restart-hosts]"
}
# Main script
set -e  # Exit on error

debug=false
restart_hosts_flag=false
single_host=""
hosts_file=""
username=""
password=""
iso_path=""

# Parse command line options
while [[ $# -gt 0 ]]; do
    case "$1" in
        -h)
            single_host="$2"
            shift 2
            ;;
        -i)
            hosts_file="$2"
            shift 2
            ;;
        -u|--username)
            username="$2"
            shift 2
            ;;
        -p|--password)
            password="$2"
            shift 2
            ;;
        -f|--filepath)
            iso_path="$2"
            shift 2
            ;;
        --debug)
            debug=true
            shift
            ;;
        --restart-hosts)
            restart_hosts_flag=true
            shift
            ;;
        -h|--help)
            print_help
            exit 0
            ;;
        *)
            echo "Usage: $0 [-h host] [-i host_file] [-u username] [-p password] [-f iso path] [--debug] [--restart-hosts]"
            exit 1
            ;;
    esac
done

# Enable debug mode if specified
if [ "$debug" = true ]; then
    set -x
fi

# Print help if no args
if [ "$#" -eq 0 ]
then
  print_help
  exit 0
fi

# Check if both single_host and hosts_file options are provided
if [ -n "$single_host" ] && [ -n "$hosts_file" ]; then
    echo "Error: You cannot use both -h and -i options simultaneously."
    exit 1
fi

# Check if either single_host or hosts_file option is provided
if [ -z "$single_host" ] && [ -z "$hosts_file" ]; then
    echo "Error: Please specify either -h or -i option."
    exit 1
fi

# Check if input file exists (if -i option is used)
if [ -n "$hosts_file" ] && [ ! -f "$hosts_file" ]; then
    echo "Error: Input file '$hosts_file' does not exist."
    exit 1
fi

# Check if password is set, otherwise prompt for it
if [ -z ${password+x} ]; then
  echo "Please enter Password: "
  read -s password
  echo ""
# Process single host or hosts from the input file
if [ -n "$single_host" ]; then
    # Unmount the old ISO for the single host
    unmount_iso "$password" "$single_host" "$username"

    # Mount the new ISO for the single host
    mount_iso "$password" "$iso_path" "$single_host" "$username"
else
    # Read host IPs or hostnames from the input file and process each host
    while IFS= read -r host; do
        # Unmount the old ISO
        unmount_iso "$password" "$host" "$username"

        # Mount the new ISO
        mount_iso "$password" "$iso_path" "$host" "$username"
    done < "$hosts_file"

    # Optionally restart the host machines
    if [ "$restart_hosts_flag" = true ]; then
        restart_hosts "$password" "$hosts_file" "$username"
    fi
fi
