#!/bin/bash
# this script returns the zone_id and IP address of a given subdomain

# Check if CF_TOKEN is set in the environment, if not prompt the user
if [ -z "$CF_TOKEN" ]; then
    read -p "Enter your Cloudflare API token: " CF_TOKEN
fi

# Check if DOMAIN is set in the environment, if not prompt the user
if [ -z "$DOMAIN" ]; then
    read -p "Enter your domain: " DOMAIN
fi

# Check if SUBDOMAIN is set in the environment, if not prompt the user
if [ -z "$SUBDOMAIN" ]; then
    read -p "Enter your subdomain: " SUBDOMAIN
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

# Get the A record for the specified subdomain
A_RECORD_IP=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/dns_records?type=A&name=$SUBDOMAIN.$DOMAIN" \
     -H "Authorization: Bearer $CF_TOKEN" \
     -H "Content-Type: application/json" | jq -r '.result[0].content')

# Check if the A record IP was retrieved successfully
if [ -z "$A_RECORD_IP" ]; then
    echo "Failed to retrieve the A record for $SUBDOMAIN.$DOMAIN. Please check your API token, domain, and subdomain."
    exit 1
fi

echo "A record IP address for $SUBDOMAIN.$DOMAIN: $A_RECORD_IP"

