#!/bin/bash

# Prompt for the domain key and CSR file names
read -p "Enter the domain key name (e.g., mydomain.com): " mydomain
read -p "Enter the domain csr name (e.g., mydomain.csr): " csrfile

# Update the system and install OpenSSL
sudo apt update -y
sudo apt install openssl -y

# Generate the private key
openssl genpkey -algorithm RSA -out "$mydomain.key"

# Generate the CSR using the private key
openssl req -new -key "$mydomain.key" -out "$csrfile"

# Display the contents of the CSR
openssl req -noout -text -in "$csrfile"

echo "Private key and CSR have been successfully created."
