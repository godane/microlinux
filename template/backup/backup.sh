#!/bin/bash
#
# backup.sh
#
# Written by Niki Kovacs <info@microlinux.fr>
#
# This script generates automatic rotating snapshot-style backups on
# Linux-based systems. It's written for Slackware Linux, though it can easily
# be adapted to any Unix-based system.
#
# For clarity's sake, let's define a couple of terms. The 'server' is the
# machine running this script and hosting all your backup snapshots, whereas a
# 'client' is a remote machine - on the LAN or on the Internet - whose data you
# wish to backup.
#
# The script uses rsync over SSH, so make sure the server can connect to every
# client using SSH key authentication. If you don't know how to do this, check
# out http://www.microlinux.fr/microlinux/Linux-HOWTOs/SSH-Key-HOWTO.txt.
#
# Copy the script to a sensible place like /root/bin, edit the client
# hostnames and set the script permissions to rwx------ (chmod 0700). You might
# want to take a peek at the exclude list for ignored filetypes.
# 
# Databases on the clients are meant to be dumped in /root/sql. Check out
# http://www.microlinux.fr/microlinux/template/backup/mysql for a MySQL
# database dump script to be run on the clients, preferably right before this.
#
# You might want to define a daily cronjob like this:
#
# crontab -e
#
## Run backup every day at 13:00
#00 13 * * * /root/bin/backup.sh 1> /dev/null
# 
# This work is inspired by Mike Rubel's great tutorial from the O'Reilly book
# "Linux Server Hacks". The original tutorial is still online here:
# http://www.mikerubel.org/computers/rsync_snapshots/. 
#
# Compared to Mike Rubel's method, the backup process is simplified, since our
# script takes care of synchronizing the backup server with the remote clients
# AND snapshot rotation in one go. 

# Local Area Network
DOMAIN="microlinux.lan"
CLIENT[0]="bernadette"
CLIENT[1]="raymonde"
CLIENT[2]="leanore"

# Public servers
#DOMAIN="dedibox.fr"
#CLIENT[0]="sd-48975.dedibox.fr"
#CLIENT[1]="sd-41893.dedibox.fr"

# Colors
WHITE="\033[01;37m"
BLUE="\033[01;34m"
GREEN="\033[01;32m"
RED="\033[01;31m"
NC="\033[00m"

# Delay in seconds before running each step. Set to 0 or 1.
DELAY=1

# Where we store all backups
BACKUPDIR="/srv/backup"

# Number of snapshots, at least 2
SNAPSHOTS=30

# Excludes files by size (in MB)
MAXSIZE=500

# Exclude files by type (needs full path)
EXCLUDES=/root/bin/exclude-list.txt

echo

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
  sleep $DELAY
  mkdir -p $BACKUPDIR
fi

# Every host has its own backup subdirectory.
echo "::"
echo ":: Checking for local backup directories..."
echo "::"
sleep $DELAY

for HOST in ${CLIENT[*]} ; do
  if [ -d $BACKUPDIR/$DOMAIN/$HOST ] ; then
    echo -e ":: Backup directory for host $BLUE$HOST$NC exists."
    sleep $DELAY
  else
    echo -e ":: Creating backup directory for host $BLUE$HOST$NC."
    sleep $DELAY
    mkdir -p $BACKUPDIR/$DOMAIN/$HOST
  fi
done

echo "::"
echo ":: Checking if remote hosts are online..."
echo "::"
sleep $DELAY

for HOST in ${CLIENT[*]} ; do
  echo -e ":: Checking if host $BLUE$HOST$NC is online..."
  sleep $DELAY
  CONNECT=$(ssh -o BatchMode=yes -o ConnectTimeout=5 root@$HOST echo OK 2>&1)
  if [ "$CONNECT" = "OK" ] ; then
    echo -e ":: Host $BLUE$HOST$NC is ${GREEN}online${NC}."
    sleep $DELAY
  else
    echo -e ":: Host $BLUE$HOST$NC is ${RED}offline${NC}."
    sleep $DELAY
  fi
  echo "::"
done

echo ":: Starting backups."
echo "::"
sleep $DELAY

for HOST in ${CLIENT[*]} ; do
  CONNECT=$(ssh -o BatchMode=yes -o ConnectTimeout=5 root@$HOST echo OK 2>&1)
  if [ "$CONNECT" = "OK" ] ; then
    echo -e ":: Backing up host $GREEN$HOST$NC..."
    sleep $DELAY
    # Delete oldest snapshot if it exists
    if [ -d $BACKUPDIR/$DOMAIN/$HOST/snapshot.$SNAPSHOTS ] ; then
      echo -e ":: Deleting oldest backup snapshot.$SNAPSHOTS..."
      sleep $DELAY
      rm -rf $BACKUPDIR/$DOMAIN/$HOST/snapshot.$SNAPSHOTS
    fi
    # Rotate intermediary snapshots one by one
    for (( SNAPSHOT = $SNAPSHOTS; SNAPSHOT > 1; SNAPSHOT -= 1 )) ; do
      PREVIOUS=$(expr $SNAPSHOT - 1)
      if [ -d $BACKUPDIR/$DOMAIN/$HOST/snapshot.$PREVIOUS ] ; then
        echo ":: Moving snapshot.$PREVIOUS to snapshot.$SNAPSHOT..."
        sleep $DELAY
        mv $BACKUPDIR/$DOMAIN/$HOST/snapshot.$PREVIOUS \
          $BACKUPDIR/$DOMAIN/$HOST/snapshot.$SNAPSHOT
      fi
    done
    # Copy directory tree using hard links
    if [ -d $BACKUPDIR/$DOMAIN/$HOST/snapshot.0 ] ; then
      echo ":: Copying snapshot.0 to snapshot.1..."
      sleep $DELAY
      cp -al $BACKUPDIR/$DOMAIN/$HOST/snapshot.0 $BACKUPDIR/$DOMAIN/$HOST/snapshot.1
    fi
    # Backup /home
    echo ":: Backing up user home directories..."
    sleep $DELAY
    rsync -a --delete --exclude-from $EXCLUDES --delete-excluded \
      --max-size=${MAXSIZE}mb -e ssh root@$HOST:/home \
      $BACKUPDIR/$DOMAIN/$HOST/snapshot.0
    # Backup /etc
    echo ":: Backing up configuration files..."
    sleep $DELAY
    rsync -a --delete --exclude-from $EXCLUDES --delete-excluded \
      --max-size=${MAXSIZE}mb -e ssh root@$HOST:/etc \
      $BACKUPDIR/$DOMAIN/$HOST/snapshot.0
    # Backup /var/named if it exists
    if ssh -o BatchMode=yes -o ConnectTimeout=5 root@$HOST [ -d /var/named ] ; then
      echo ":: Backing up DNS zone files..."
      sleep $DELAY
      rsync -a --delete --exclude-from $EXCLUDES --delete-excluded \
        --max-size=${MAXSIZE}mb -e ssh root@$HOST:/var/named \
        $BACKUPDIR/$DOMAIN/$HOST/snapshot.0/var
    fi
    # Backup /var/www if it exists
    if ssh -o BatchMode=yes -o ConnectTimeout=5 root@$HOST [ -d /var/www ] ; then
      echo ":: Backing up web pages..."
      sleep $DELAY
      rsync -a --delete --exclude-from $EXCLUDES --delete-excluded \
        --max-size=${MAXSIZE}mb -e ssh root@$HOST:/var/www \
        $BACKUPDIR/$DOMAIN/$HOST/snapshot.0/var
    fi
    # Backup /root/sql if it exists
    if ssh -o BatchMode=yes -o ConnectTimeout=5 root@$HOST [ -d /root/sql ] ; then
      echo ":: Backing up MySQL databases..."
      sleep $DELAY
      rsync -a --delete --exclude-from $EXCLUDES --delete-excluded \
        --max-size=${MAXSIZE}mb -e ssh root@$HOST:/root/sql \
        $BACKUPDIR/$DOMAIN/$HOST/snapshot.0/root
    fi
    # Backup /root/bin if it exists
    if ssh -o BatchMode=yes -o ConnectTimeout=5 root@$HOST [ -d /root/bin ] ; then
      echo ":: Backing up client admin scripts..."
      sleep $DELAY
      rsync -a --delete --exclude-from $EXCLUDES --delete-excluded \
        --max-size=${MAXSIZE}mb -e ssh root@$HOST:/root/bin \
        $BACKUPDIR/$DOMAIN/$HOST/snapshot.0/root
    fi
    # Update timestamp
    echo ":: Updating timestamp..."
    sleep $DELAY
    touch $BACKUPDIR/$DOMAIN/$HOST/snapshot.0
    echo -e ":: [${GREEN}OK${NC}]"
    sleep $DELAY
  else
    echo -e ":: Skipping unreachable host $RED$HOST$NC."
    sleep $DELAY
  fi
  echo "::"
done

echo ":: Here's a summary of our local backups:"
echo 
sleep $DELAY

# Display size of local backups
printf " %-20s | %-20s\n " Host Size
for HOST in ${CLIENT[*]} ; do
  LOCALDIR="$BACKUPDIR/$DOMAIN/$HOST"
  SIZE=$(du -sh $LOCALDIR | awk '{ print $1 }')
  printf "%-20s | %-20s\n " $HOST $SIZE
  sleep $DELAY
done

echo 

exit 0




