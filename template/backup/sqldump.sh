#!/bin/bash
#
# sqldump.sh
#
# Written by Niki Kovacs <info@microlinux.fr>
#
# This script dumps all your MySQL databases, one by one. 
#
# Each database is backed up as a compressed backup-database-YYYYMMDD.sql.gz
# file under $BACKUPDIR. After that, all databases are dumped into one big file
# backup-all-YYYYMMDD.sql.gz.
#
# Copy the script to a sensible place like /usr/local/sbin, edit the database
# parameters and set the script permissions to rwx------ (chmod 0700). 
#
# You might want to define a daily cronjob like this:
#
# crontab -e
#
## Backup MySQL databases every day at 11:50
#50 11 * * * /usr/local/sbin/sqldump.sh 1> /dev/null

# MySQL access
MYSQLUSER="root"
MYSQLPASS="mysqlpass"

# Where we store all backups
BACKUPDIR="/sqldump"

# Colors
BLUE="\033[01;34m"
GREEN="\033[01;32m"
NC="\033[00m"

# Pause between backups
DELAY=1

# Today = YYYYMMDD
TIMESTAMP=$(date "+%Y%m%d")

# Databases

DBNAME[1]="database1"
DBUSER[1]="db1user"
DBPASS[1]="db1pass"

DBNAME[2]="database2"
DBUSER[2]="db2user"
DBPASS[2]="db2pass"

DBNAME[3]="database3"
DBUSER[3]="db3user"
DBPASS[3]="db3pass"

# Make sure only root can run this.
if [ $EUID -ne 0 ] ; then
  echo "::"
  echo ":: You must be root to run this script."
  echo "::"
  exit 1
fi

echo "::" 
echo ":: Starting MySQL database backup."
echo "::" 
sleep $DELAY

# Check if main backup directory exists.
if [ ! -d $BACKUPDIR ] ; then
  echo ":: Creating main backup directory."
  echo "::"
  sleep $DELAY
  mkdir -p -m 0750 $BACKUPDIR
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

echo -e ":: Dumping all databases."
echo "::"
sleep $DELAY
mysqldump -u $MYSQLUSER -p$MYSQLPASS --events --ignore-table=mysql.event \
  --all-databases | gzip -c > $BACKUPDIR/backup-all-$TIMESTAMP.sql.gz

echo -e ":: Setting file permissions."
chmod 0640 $BACKUPDIR/*.sql*
echo "::"

echo -e ":: [${GREEN}OK${NC}]"
echo "::"

exit 0
