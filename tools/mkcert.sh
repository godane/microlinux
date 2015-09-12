#!/bin/sh

# Script to generate a self-signed certificate
# 
# Niki Kovacs <info@microlinux.fr>

SSLDIR="/etc/ssl"
CRTDIR="$SSLDIR/mycerts"
KEYDIR="$SSLDIR/private"

DOMAIN="slackbox.fr"
EXPIRE="3650"
CRTFILE="$CRTDIR/$DOMAIN.pem"
KEYFILE="$KEYDIR/$DOMAIN.key"

if [ ! -d $CRTDIR ]; then
  echo 
  echo ":: $SSLDIR/certs directory doesn't exist."
  echo 
  exit 1
fi

if [ ! -d $KEYDIR ]; then
  echo 
  echo ":: $SSLDIR/private directory doesn't exist."
  echo 
  exit 1
fi

if [ -f $CRTFILE ]; then
  echo 
  echo ":: $CRTFILE already exists, won't overwrite."
  echo 
  exit 1
fi

if [ -f $KEYFILE ]; then
  echo 
  echo ":: $KEYFILE already exists, won't overwrite."
  echo 
  exit 1
fi

openssl req \
  -new \
  -x509 \
  -days $EXPIRE \
  -sha256 \
  -nodes \
  -newkey rsa:4096 \
  -subj "/C=FR/ST=Gard/O=Microlinux/CN=$DOMAIN/emailAddress=info@microlinux.fr" \
  -reqexts SAN
  -config <(cat /etc/ssl/openssl.cnf <(printf "[SAN]\nsubjectAltName=DNS:$DOMAIN,DNS:www.$DOMAIN"))
  -out $CRTFILE \
  -keyout $KEYFILE \
  || exit 2

chmod 0600 $KEYFILE

# Create a symlink in /etc/ssl/certs
pushd $SSLDIR/certs
  rm -f $DOMAIN.pem
  ln -s ../mycerts/$DOMAIN.pem .
popd

echo 

openssl x509 \
  -subject \
  -fingerprint \
  -noout \
  -in $CRTFILE \
  || exit 2
