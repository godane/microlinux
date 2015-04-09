#!/bin/bash
#
# trim.sh
#
# This script prepares the base system before building or installing additional
# software. It removes unneeded Slackware packages and installs required ones.
#
# You should configure slackpkg and run 'slackpkg update' before calling it.

CWD=$(pwd)
CATEGORIES="a ap d e f k kde kdei l n t tcl x xap xfce y" 
PKGADD=/tmp/packages
PKGDEL=/tmp/skip
PKGINFO=/tmp/pkg_database

for CATEGORY in $CATEGORIES; do
  FILE=$CWD/../tagfiles/$CATEGORY/tagfile
  awk -F: '$2 == "ADD" {print $1}' $FILE >> $PKGADD
  awk -F: '$2 == "SKP" {print $1}' $FILE >> $PKGDEL
done

CRUFT=$(egrep -v '(^\#)|(^\s+$)' $PKGDEL)
INSTALL=$(egrep -v '(^\#)|(^\s+$)' $PKGADD)

rm -rf $PKGADD $PKGDEL $PKGINFO 
mkdir $PKGINFO

echo
echo "+=============================================="
echo "| Checking installed packages on your system..."
echo "+=============================================="
echo
sleep 3
for PACKAGE in $(find /var/log/packages); do
  printf "."
  PACKAGENAME=$(echo $PACKAGE |cut -f5 -d'/' |rev |cut -f4- -d'-' |rev)
  touch $PKGINFO/$PACKAGENAME
done

echo
echo
echo "+========================================================"
echo "| Checking for packages to be removed from your system..."
echo "+========================================================"
echo
sleep 3
for PACKAGE in $CRUFT; do
  if [ -r $PKGINFO/$PACKAGE ] ; then
    PACKAGES="$PACKAGES $PACKAGE"
  fi
done

if [ ! -z "$PACKAGES" ]; then
  /usr/sbin/slackpkg remove $PACKAGES
fi

unset PACKAGE
unset PACKAGES

echo 
echo "+========================================================"
echo "| Checking for packages to be installed on your system..."
echo "+========================================================"
echo 
sleep 3
for PACKAGE in $INSTALL; do
  if [ ! -r $PKGINFO/$PACKAGE ] ; then
    PACKAGES="$PACKAGES $PACKAGE"
  fi
done

if [ ! -z "$PACKAGES" ]; then
  /usr/sbin/slackpkg install $PACKAGES
fi

rm -rf $PKGADD $PKGDEL $PKGINFO

echo
echo "+================================================================="
echo "| Your Slackware 14.0 installation has been trimmed successfully. "
echo "+================================================================="
echo
echo 

