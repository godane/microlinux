#!/bin/sh

# Script to generate a multi-domain self-signed certificate
# 
# Niki Kovacs <info@microlinux.fr>

SSLDIR="/etc/ssl"
CRTDIR="$SSLDIR/mycerts"
KEYDIR="$SSLDIR/private"
DOMAIN="slackbox.fr"
CNFFILE="$CRTDIR/$DOMAIN.cnf"
KEYFILE="$KEYDIR/$DOMAIN.key"
CSRFILE="$CRTDIR/$DOMAIN.csr"
CRTFILE="$CRTDIR/$DOMAIN.crt"

# Testing
rm -f $CNFFILE $KEYFILE $CSRFILE $CRTFILE

for DIRECTORY in $CRTDIR $KEYDIR; do
  if [ ! -d $DIRECTORY ]; then
    echo 
    echo ":: $DIRECTORY directory doesn't exist."
    echo 
    exit 1
  fi
done

for FILE in $CNFFILE $KEYFILE $CSRFILE $CRTFILE; do
  if [ -f $FILE ]; then
    echo 
    echo ":: $FILE already exists, won't overwrite."
    echo 
    exit 1
  fi
done

cat > $CNFFILE << EOF
[req]
distinguished_name  = req_distinguished_name
string_mask         = nombstr
req_extensions      = v3_req

[req_distinguished_name]
commonName          = Common Name
commonName_default  = $DOMAIN

[ v3_req ]
# Extensions to add to a certificate request
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = $DOMAIN
DNS.2 = www.$DOMAIN
EOF

# Generate private key
openssl genrsa \
  -out $KEYFILE \
  4096 

# Generate Certificate Signing Request
openssl req \
  -new \
  -sha256 \
  -out $CSRFILE \
  -key $KEYFILE \
  -config $CNFFILE

# Self-sign and generate Certificate
openssl x509 \
  -req \
  -days 3650 \
  -in $CSRFILE \
  -signkey $KEYFILE \
  -out $CRTFILE \
  -extensions v3_req \
  -extfile $CNFFILE

chmod 0600 $KEYFILE

# Create a symlink in /etc/ssl/certs
pushd $SSLDIR/certs
  rm -f $DOMAIN.crt
  ln -s ../mycerts/$DOMAIN.crt .
popd

echo 
