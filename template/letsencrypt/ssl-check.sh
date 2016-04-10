#!/bin/bash
#
# ssl-check.sh
#
# Display SSL/TLS certificate expiration date

# Domains and subdomains
DOMAIN[0]="coopsoleil.fr"
SUBDOM[0]="www mail cloud"

DOMAIN[1]="microlinux.eu"
SUBDOM[1]="www mail cloud"

DOMAIN[2]="radionovak.com"
SUBDOM[2]="www mail"

DOMAIN[3]="scholae.fr"
SUBDOM[3]="www mail compta"

# Colors
WHITE="\033[01;37m"
BLUE="\033[01;34m"
GREEN="\033[01;32m"
RED="\033[01;31m"
NC="\033[00m"

COUNT=0

echo "::"

for DOMAIN in ${DOMAIN[*]}; do
  echo -e ":: SSL certificate validity for domain $GREEN$DOMAIN$NC : \c"
  VALIDITY=$(echo | openssl s_client -connect $DOMAIN:443 2>/dev/null \
             | openssl x509 -noout -enddate)
  echo ${VALIDITY/notAfter=/}
  for PREFIX in ${SUBDOM[$COUNT]}; do
  echo -e ":: SSL certificate validity for subdomain $BLUE$PREFIX.$DOMAIN$NC : \c"
  VALIDITY=$(echo | openssl s_client -connect $PREFIX.$DOMAIN:443 2>/dev/null \
             | openssl x509 -noout -enddate)
  echo ${VALIDITY/notAfter=/}
  done
  echo "::"
  ((COUNT++))
done

exit 0
