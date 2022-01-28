#!/usr/bin/env bash
#
# This script generates a new SSL certificate and key for a given domain,
# signed by a local, private certificate authority. If the CA certificate
# and key do not exist then they will also be created.
#
# The domain certificate has subject alternate names for some common
# sub-domains used for a TAP installation.
#
# DO NOT USE THIS FOR PRODUCTION ENVIRONMENTS!

set -e

lifetime=365

domain=${1-$DOMAIN}
if [[ -z "$domain" ]]
then
  cat >&2 <<EOF
Usage: $0 [domain-name]

Please supply a base domain name for the certificate.

The domain-name is taken from the command-line, or the DOMAIN
environment variable, if that is se.
EOF
  exit 1
fi

config_file=$domain.config
cat > $config_file <<EOF
[req]
distinguished_name = req_distinguished_name
req_extensions = v3_req
prompt = no
[req_distinguished_name]
C = US
ST = CA
L = Palo Alto
O = VMware Inc.
OU = Tanzu
CN = $domain
[v3_req]
keyUsage =  digitalSignature, nonRepudiation, keyEncipherment, dataEncipherment
extendedKeyUsage = serverAuth
subjectAltName = @alt_names
[alt_names]
DNS.1 = $domain
DNS.2 = *.$domain
DNS.3 = tap-gui.$domain
DNS.4 = *.apps.$domain
DNS.5 = *.learn.$domain
EOF

if [[ ! -f "$domain.key" ]]
then
  echo "Generating new key: $domain.key"
  openssl genrsa -out "$domain.key" 2048
else
  echo "Using existing key file: $domain.key"
fi

echo "Generating certificate signing request: $domain.csr"
openssl req -new -nodes \
  -key "$domain.key" -config $config_file \
  -out "$domain.csr" -sha256

if $self_signed
then
  echo "Generating self-signed certificate: $domain.crt"
  openssl x509 -req -days $lifetime \
    -in "$domain.csr" -signkey "$domain.key" \
    -out "$domain.crt" -sha256 \
    -extfile "$domain.config" -extensions v3_req
fi