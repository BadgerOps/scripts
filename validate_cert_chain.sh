#!/bin/bash

# Usage: ./validate_cert.sh <key_file> <cert_file> <root_CA_file> [<intermediate_cert_file>]

KEY_FILE="$1"
CERT_FILE="$2"
ROOT_CA_FILE="$3"
INTERMEDIATE_CERT_FILE="$4"

function usage() {
    echo "Usage: ./validate_cert.sh <key_file> <cert_file> <root_CA_file> [<intermediate_cert_file>]"
}

# First, print out usage if there are no arguments
if [[ "$#" -eq 0 ]]; then
    usage
    exit 1
fi

# Check if each of the files exist and are readable.
if [[ ! -f "$ROOT_CA_FILE" ]]; then
    echo "Root CA file not found."
    exit 1
fi

if [[ ! -r "$KEY_FILE" ]]; then
    echo "Key file cannot be read."
    exit 1
fi

if [[ ! -r "$CERT_FILE" ]]; then
    echo "Cert file cannot be read."
    exit 1
fi

if [[ ! -r "$INTERMEDIATE_CERT_FILE" ]]; then
    echo "Intermedate Cert /chain file cannot be read."
    exit 1
fi

# Check if the private key is encrypted or password-protected.
if [[ "$KEY_FILE" =~ ^.*\.enc$ ]]; then
    echo "Private key is encrypted."
    exit 1
fi

# Check if the private key and certificate match.
echo "Checking if the private key matches the certificate..."
MODULUS_CERT=$(openssl x509 -noout -modulus -in "$CERT_FILE" | openssl md5)
MODULUS_KEY=$(openssl rsa -noout -modulus -in "$KEY_FILE" | openssl md5)

if [[ "$MODULUS_CERT" != "$MODULUS_KEY" ]]; then
    echo "Private key does not match the certificate."
    exit 1
fi

echo "Private key matches the certificate."

# Check if the intermediate certificate(s) are correctly ordered in the file.
if [[ -n "$INTERMEDIATE_CERT_FILE" ]]; then
    # Get the number of intermediate certificates.
    INTERMEDIATE_CERT_COUNT=$(openssl rsa -noout -modulus -in "$INTERMEDIATE_CERT_FILE" | openssl md5)

    # Check if the intermediate certificate(s) are ordered correctly.
    for ((i=1; i<=$INTERMEDIATE_CERT_COUNT; i++)); do
        INTERMEDIATE_CERT_MODULUS=$(openssl x509 -noout -modulus -in "$INTERMEDIATE_CERT_FILE" | openssl md5)
        CERT_MODULUS=$(openssl rsa -noout -modulus -in "$CERT_FILE" | openssl md5)
        if [[ "$INTERMEDIATE_CERT_MODULUS" != "$CERT_MODULUS" ]]; then
            echo "Intermediate certificate $i is not correctly ordered in the file."
            exit 1
        fi
    done
fi

# Check the certificate chain.
echo "Validating the certificate chain..."
if [[ -n "$INTERMEDIATE_CERT_FILE" ]]; then
    # Verify with intermediate certificate(s).
    openssl verify -CAfile "$ROOT_CA_FILE" -untrusted "$INTERMEDIATE_CERT_FILE" "$CERT_FILE" > /dev/null 2>&1
else
    # Verify without intermediate certificate.
    openssl verify -CAfile "$ROOT_CA_FILE" "$CERT_FILE" > /dev/null 2>&1
fi

if [[ $? -ne 0 ]]; then
    echo "Certificate chain validation failed."
    exit 1
else
    echo "Certificate chain is valid."
fi

# Print information about the SSL certificate.
echo "Subject: $(openssl x509 -noout -subject -in "$CERT_FILE" | openssl x509 -noout -subject)"
echo "Validity Period: $(openssl x509 -noout -dates -in "$CERT_FILE" | openssl x509 -noout -validity)"

exit 0
