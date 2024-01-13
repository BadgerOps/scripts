#!/bin/bash

# Initialize variables
input_file=""
output_file=""
warning_days_threshold=90
timeout_seconds=5

# Function to check SSL Expiry Date
check_ssl_expiry() {
    local url=$1
    local current_epoch=$(date +%s)
    local ssl_output
    local return_status

    ssl_output=$(echo | timeout $timeout_seconds openssl s_client -servername "$url" -connect "$url:443" 2>&1)
    return_status=$?

    # Check for successful SSL handshake
    if echo "$ssl_output" | grep -q 'Verify return code: 0 (ok)'; then
        local expiry_date=$(echo "$ssl_output" | openssl x509 -noout -enddate | cut -d= -f2)
        local expiry_epoch=$(date --date="$expiry_date" +%s)
        local expiry_days_left=$(( ($expiry_epoch - $current_epoch) / 86400 ))

        if [ $expiry_days_left -gt $warning_days_threshold ]; then
            echo "$url is ok, $expiry_days_left days left"
        else
            echo "$url is close to expiry, $expiry_days_left days left"
        fi
    else
        # Report the SSL error, but don't abort the entire script
        echo "Failed to find SSL certificate for $url. SSL check skipped."
    fi
}

# Remove 'http://' and 'https://' from a URL
remove_http_s() {
    local url=$1
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
    # Remove leading and trailing whitespaces, 'http://', and 'https://'
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
