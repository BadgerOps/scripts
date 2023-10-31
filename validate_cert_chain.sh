#!/bin/bash

# Usage: ./validate_cert_chain.sh <key_file> <cert_file> <root_CA_file> [<intermediate_cert_file>]

KEY_FILE="$1"
CERT_FILE="$2"
ROOT_CA_FILE="$3"
INTERMEDIATE_CERT_FILE="$4"

# Exit if not enough arguments
if [[ -z "$KEY_FILE" || -z "$CERT_FILE" || -z "$ROOT_CA_FILE" ]]; then
    echo "Usage: $0 <key_file> <cert_file> <root_CA_file> [<intermediate_cert_file>]"
    exit 1
fi

# Check if the private key matches the certificate
echo "Checking if the private key matches the certificate..."
if ! openssl x509 -noout -modulus -in "$CERT_FILE" | openssl md5 > /dev/null 2>&1; then
    echo "Error reading the certificate file."
    exit 1
fi

if ! openssl rsa -noout -modulus -in "$KEY_FILE" | openssl md5 > /dev/null 2>&1; then
    echo "Error reading the key file."
    exit 1
fi

CERT_MODULUS=$(openssl x509 -noout -modulus -in "$CERT_FILE" | openssl md5)
KEY_MODULUS=$(openssl rsa -noout -modulus -in "$KEY_FILE" | openssl md5)

if [ "$CERT_MODULUS" != "$KEY_MODULUS" ]; then
    echo "Private key does not match the certificate."
    exit 1
else
    echo "Private key matches the certificate."
fi

# Check the certificate chain
echo "Validating the certificate chain..."
if [[ -n "$INTERMEDIATE_CERT_FILE" ]]; then
    # Verify with intermediate certificate
    openssl verify -CAfile "$ROOT_CA_FILE" -untrusted "$INTERMEDIATE_CERT_FILE" "$CERT_FILE" > /dev/null 2>&1
else
    # Verify without intermediate certificate
    openssl verify -CAfile "$ROOT_CA_FILE" "$CERT_FILE" > /dev/null 2>&1
fi

if [ $? -eq 0 ]; then
    echo "Certificate chain is valid."
else
    echo "Certificate chain validation failed."
    exit 1
fi

echo "Certificate validation completed successfully."
