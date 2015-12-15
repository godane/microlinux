#!/bin/bash
#
# sqldump.sh
#
# Written by Niki Kovacs <info@microlinux.fr>
#
# This script dumps all your MySQL databases, one by one. 
#
# Each database is backed up as a compressed backup-database-YYYYMMDD.sql.gz
# file under /root/sql. 
#
# Copy the script to a sensible place like /root/bin, edit the database
# parameters and set the script permissions to rwx------ (chmod 0700). 
#
# You might want to define a daily cronjob like this:
#
# crontab -e
#
## Backup MySQL databases every day at 11:50
#50 11 * * * /root/bin/sqldump.sh 1> /dev/null

# Databases

DBNAME[1]="database1"
DBUSER[1]="db1user"
DBPASS[1]="********"

DBNAME[2]="database2"
DBUSER[2]="db2user"
DBPASS[2]="********"

DBNAME[3]="database3"
DBUSER[3]="db3user"
DBPASS[3]="********"

# Colors
BLUE="\033[01;34m"
GREEN="\033[01;32m"
NC="\033[00m"

DELAY=1

# Where we store all backups
BACKUPDIR="/root/sql"

# Today = YYYYMMDD
TIMESTAMP=$(date "+%Y%m%d")

echo "::" 
echo ":: Starting MySQL database backup."
echo "::" 
sleep $DELAY

# Make sure only root can run this.
if [ $EUID -ne 0 ] ; then
  echo "::"
  echo ":: You must be root to run this script."
  echo "::"
  exit 1
fi

# Check if main backup directory exists.
if [ ! -d $BACKUPDIR ] ; then
  echo ":: Creating main backup directory."
  echo "::"
  sleep $DELAY
  mkdir -p $BACKUPDIR
fi

echo ":: Deleting old backups."
echo "::"
sleep $DELAY
rm -f $BACKUPDIR/*.sql
rm -f $BACKUPDIR/*.sql.gz

for (( DB=1 ; DB<=${#DBNAME[*]} ; DB++ )) ; do
  echo -e ":: Dumping database [$BLUE${DBNAME[$DB]}$NC]."
  echo "::"
  sleep $DELAY
  mysqldump -u ${DBUSER[$DB]} -p${DBPASS[$DB]} ${DBNAME[$DB]} | \
            gzip -c > $BACKUPDIR/backup-${DBNAME[$DB]}-$TIMESTAMP.sql.gz
done

echo -e ":: [${GREEN}OK${NC}]"
echo "::"

