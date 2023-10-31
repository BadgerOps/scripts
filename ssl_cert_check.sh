#!/bin/bash
#
# This script helps to quickly identify SSL certificate age
# You can set a warning threshold (defaults to 90) to alert for certs about to expire
# use a newline separated file with URL's to  check
#

input_file=""
output_file=""
warning_days_threshold=90

check_ssl_expiry() {
    local url=$1
    local current_epoch=$(date +%s)
    local ssl_output
    local return_status

    ssl_output=$(echo | openssl s_client -servername "$url" -connect "$url:443" 2>&1)
    return_status=$?

    if [ $return_status -ne 0 ]; then
        echo "Error retrieving SSL certificate for $url. Details: $ssl_output"
        return
    fi

    local expiry_date=$(echo "$ssl_output" | openssl x509 -noout -enddate | cut -d= -f2)
    local expiry_epoch=$(date --date="$expiry_date" +%s)
    local expiry_days_left=$(( ($expiry_epoch - $current_epoch) / 86400 ))

    if [ -z "$expiry_date" ]; then
        echo "No SSL certificate found for $url"
        return
    fi

    if [ $expiry_days_left -gt $warning_days_threshold ]; then
        echo "$url is ok, $expiry_days_left days left"
    else
        echo "$url is close to expiry, $expiry_days_left days left"
    fi
}

# Remove 'http://' and 'https://' from a URL
remove_http_s() {
    local url=$1
    # Remove both https:// and http:// prefixes
    url="${url/https:\/\//}"
    url="${url/http:\/\//}"
    echo "$url"
}

# Parse command line arguments
while getopts "f:o:" opt; do
    case $opt in
        f) input_file=$OPTARG ;;
        o) output_file=$OPTARG ;;
        \?) echo "Invalid option -$OPTARG" >&2; exit 1 ;;
    esac
done

# Check if input file is provided
if [ -z "$input_file" ]; then
    echo "Input file not specified. Use -f to specify the input file."
    exit 1
fi

# Check URLs from the input file
while IFS= read -r url; do
    # Remove leading and trailing whitespaces and 'https://'
    url=$(echo $url | xargs)
    url=$(remove_http_s "$url")

    # Skip empty lines
    [ -z "$url" ] && continue

    # Check if outputting to a file
    if [ -n "$output_file" ]; then
        check_ssl_expiry "$url" >> "$output_file"
    else
        check_ssl_expiry "$url"
    fi
done < "$input_file"
