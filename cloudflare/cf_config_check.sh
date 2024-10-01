#!/bin/bash
# This script checks all accessible cloudflare zones to see if the following features are enabled:
# HTTP/3
# 0-RTT Connection Resumption
# Enhanced HTTP/2 Edge Prioritization 

if [ -z "$CF_TOKEN" ]; then
    read -p "Enter your Cloudflare API token: " CF_TOKEN
fi

# Cloudflare API endpoint
CF_API="https://api.cloudflare.com/client/v4"

# CSV output file
output_file="cloudflare_zones_report.csv"

# Write CSV headers
echo "zone,domain,plan,http_3,0_rtt,h2_prioritization" > $output_file

# Function to fetch zones with pagination
fetch_zones() {
    local page=$1
    curl -s -X GET "$CF_API/zones?per_page=100&page=$page" \
         -H "Authorization: Bearer $CF_TOKEN" \
         -H "Content-Type: application/json"
}

# Initialize page number
page=1
total_pages=1

# Loop through all pages to get zones
while [ $page -le $total_pages ]; do
    response=$(fetch_zones $page)
    zones=$(echo "$response" | jq -r '.result[] | .id')
    total_pages=$(echo "$response" | jq -r '.result_info.total_pages')

    # Iterate over each zone
    for zone in $zones; do
        echo "Checking zone: $zone"

        # Get the plan for the zone (Enterprise or Free)
        plan_name=$(curl -s -X GET "$CF_API/zones/$zone" \
             -H "Authorization: Bearer $CF_TOKEN" \
             -H "Content-Type: application/json" | jq -r '.result.plan.name')

        # Get zone settings for HTTP/3, 0-RTT, and Enhanced HTTP/2
        http3=$(curl -s -X GET "$CF_API/zones/$zone/settings/http3" \
             -H "Authorization: Bearer $CF_TOKEN" \
             -H "Content-Type: application/json" | jq -r '.result.value')
        
        zero_rtt=$(curl -s -X GET "$CF_API/zones/$zone/settings/0rtt" \
             -H "Authorization: Bearer $CF_TOKEN" \
             -H "Content-Type: application/json" | jq -r '.result.value')

        h2_prioritization=$(curl -s -X GET "$CF_API/zones/$zone/settings/h2_prioritization" \
             -H "Authorization: Bearer $CF_TOKEN" \
             -H "Content-Type: application/json" | jq -r '.result.value')

        # Get the domain name for the zone
        domain=$(curl -s -X GET "$CF_API/zones/$zone" \
             -H "Authorization: Bearer $CF_TOKEN" \
             -H "Content-Type: application/json" | jq -r '.result.name')

        # Output the results to the console
        echo "Domain: $domain"
        echo "  - Plan: $plan_name"
        echo "  - HTTP/3: $http3"
        echo "  - 0-RTT Connection Resumption: $zero_rtt"
        echo "  - Enhanced HTTP/2 Edge Prioritization: $h2_prioritization"
        echo

        # Write results to the CSV file
        echo "$zone,$domain,$plan_name,$http3,$zero_rtt,$h2_prioritization" >> $output_file
    done

    # Increment page number
    ((page++))
done
