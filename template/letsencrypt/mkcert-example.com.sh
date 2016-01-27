#!/bin/bash
#
# Create/renew SSL/TLS certificates for example.com

ENCRYPT="/usr/bin/letsencrypt"
CHGRP="/usr/bin/chgrp"
CHMOD="/usr/bin/chmod"
CERTGRP="certs"
EMAIL="info@microlinux.fr"
OPTIONS="certonly \
         --standalone-supported-challenges tls-sni-01 \
         --email $EMAIL \
         --renew-by-default \
         --agree-tos \
         --text \
         --standalone"

# Create $CERTGRP group 
if ! grep -q "^$CERTGRP:" /etc/group ; then
  groupadd -g 240 $CERTGRP
  echo ":: Added $CERTGRP group."
  sleep 3
fi

# Stop Apache
echo ":: Stopping Apache."
if ps ax | grep -v grep | grep httpd > /dev/null ; then
  /etc/rc.d/rc.httpd stop 1 > /dev/null 2&>1
  sleep 5
fi

$ENCRYPT $OPTIONS -d www.example.com -d example.com \
  --webroot-path /srv/httpd/vhosts/example-secure/htdocs

$ENCRYPT $OPTIONS -d mail.example.com \
  --webroot-path /srv/httpd/vhosts/example-webmail/htdocs

$ENCRYPT $OPTIONS -d cloud.example.com \
  --webroot-path /srv/httpd/vhosts/example-owncloud/htdocs

# Fix permissions
echo ":: Setting permissions."
$CHGRP -R $CERTGRP /etc/letsencrypt
$CHMOD -R g=rx /etc/letsencrypt

# Start Apache
echo ":: Starting Apache."
/etc/rc.d/rc.httpd start

