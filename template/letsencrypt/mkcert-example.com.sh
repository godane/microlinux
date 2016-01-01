#!/bin/bash
#
# Create/renew SSL/TLS certificates for example.com

ENCRYPT="/usr/bin/letsencrypt"
EMAIL="info@microlinux.fr"
#TESTING="--test-cert"
TESTING=""
OPTIONS="certonly \
         --standalone-supported-challenges tls-sni-01 \
         --email $EMAIL \
         --renew-by-default \
         --agree-tos \
         --text \
         --standalone \
         $TESTING"

if ps ax | grep -v grep | grep httpd > /dev/null ; then
  /etc/rc.d/rc.httpd stop
  sleep 5
fi

$ENCRYPT $OPTIONS -d www.example.com -d example.com \
  --webroot-path /srv/httpd/vhosts/example-secure/htdocs

$ENCRYPT $OPTIONS -d mail.example.com \
  --webroot-path /srv/httpd/vhosts/example-webmail/htdocs

$ENCRYPT $OPTIONS -d cloud.example.com \
  --webroot-path /srv/httpd/vhosts/example-owncloud/htdocs

/etc/rc.d/rc.httpd start
