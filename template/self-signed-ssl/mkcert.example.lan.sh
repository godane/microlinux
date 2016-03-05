#!/bin/sh
#
# mkcert-example.lan.sh
#
# Script to generate a self-signed certificate for multiple local domains.
#
# Usage: copy this script to an appropriate place on the system like
# /root/scripts/ or /etc/ssl/scripts/. Eventually, rename it to something like
# mkcrt.$DOMAIN.sh. Edit it to your needs and run it as root.
#
# /!\ The script creates a 'certs' system group. Certificates and keyfiles are
# owned by root:certs. Make sure you add the relevant system users 
# to the 'certs' group, so they can access the files. Example:
#
# # usermod -a -G certs prosody
#
# Niki Kovacs <info@microlinux.fr>

DOMAIN="amandine.microlinux.lan"

SSLDIR="/etc/ssl"
CRTDIR="$SSLDIR/mycerts"
KEYDIR="$SSLDIR/private"
CNFFILE="$CRTDIR/$DOMAIN.cnf"
KEYFILE="$KEYDIR/$DOMAIN.key"
CSRFILE="$CRTDIR/$DOMAIN.csr"
CRTFILE="$CRTDIR/$DOMAIN.crt"

# Testing
rm -f $CNFFILE $KEYFILE $CSRFILE $CRTFILE

# Create certs group 
if ! grep -q "^certs:" /etc/group ; then
  groupadd -g 240 certs
  echo 
  echo ":: Added certs group."
  echo 
  sleep 3
fi

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
distinguished_name          = req_distinguished_name
string_mask                 = nombstr
req_extensions              = v3_req

[req_distinguished_name]
organizationName            = Organization Name (company)
emailAddress                = Email Address
emailAddress_max            = 40
localityName                = Locality Name
stateOrProvinceName         = State or Province Name
countryName                 = Country Name (2 letter code)
countryName_min             = 2
countryName_max             = 2
commonName                  = Common Name
commonName_max              = 64
organizationName_default    = Microlinux
emailAddress_default        = info@microlinux.fr
localityName_default        = Montpezat
stateOrProvinceName_default = Gard
countryName_default         = FR
commonName_default          = $DOMAIN

[ v3_req ]
# Extensions to add to a certificate request
basicConstraints = CA:FALSE
keyUsage = nonRepudiation, digitalSignature, keyEncipherment
subjectAltName = @alt_names

[alt_names]
DNS.1 = $DOMAIN
DNS.2 = cloud.$DOMAIN
DNS.3 = cmsmadesimple.$DOMAIN
DNS.4 = ftp.$DOMAIN
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
  -sha256 \
  -days 3650 \
  -in $CSRFILE \
  -signkey $KEYFILE \
  -out $CRTFILE \
  -extensions v3_req \
  -extfile $CNFFILE

# Set permissions
chown root:certs $KEYFILE $CRTFILE
chmod 0640 $KEYFILE $CRTFILE

# Create a symlink in /etc/ssl/certs
pushd $SSLDIR/certs
  rm -f $DOMAIN.crt
  ln -s ../mycerts/$DOMAIN.crt .
popd

echo 
