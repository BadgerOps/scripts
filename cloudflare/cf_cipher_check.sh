#!/bin/bash
# this script checks to see if any custom ciphers are set on the specified domain

# Check if CF_TOKEN is set in the environment, if not prompt the user
if [ -z "$CF_TOKEN" ]; then
    read -p "Enter your Cloudflare API token: " CF_TOKEN
fi

# Check if DOMAIN is set in the environment, if not prompt the user
if [ -z "$DOMAIN" ]; then
    read -p "Enter your domain: " DOMAIN
fi

# Get the Zone ID for the specified domain
ZONE_ID=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones?name=$DOMAIN" \
     -H "Authorization: Bearer $CF_TOKEN" \
     -H "Content-Type: application/json" | jq -r '.result[0].id')

# Check if the Zone ID was retrieved successfully
if [ -z "$ZONE_ID" ]; then
    echo "Failed to retrieve the Zone ID. Please check your API token and domain."
    exit 1
fi

echo "Zone ID for $DOMAIN: $ZONE_ID"

# Get the list of ciphers for the specified domain
CIPHERS=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/settings/ciphers" \
     -H "Authorization: Bearer $CF_TOKEN" \
     -H "Content-Type: application/json" | jq -r '.result.value')

# Check if ciphers were retrieved successfully
if [ -z "$CIPHERS" ]; then
    echo "Failed to retrieve the ciphers. Please check your API token and domain."
    exit 1
fi

echo "Ciphers for $DOMAIN:"
echo "$CIPHERS"
