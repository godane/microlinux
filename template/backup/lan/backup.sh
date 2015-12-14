# backup.sh

# Network
DOMAIN="microlinux.lan"
CLIENT[0]="bernadette"
CLIENT[1]="raymonde"
CLIENT[2]="leanore"

# Colors
WHITE="\033[01;37m"
BLUE="\033[01;34m"
GREEN="\033[01;32m"
RED="\033[01;31m"
NC="\033[00m"

# Delay in seconds before running each step. Set to 0 or 1.
DELAY=0

# Where we store all backups
BACKUPDIR="/srv/backup"

# Number of snapshots, at least 2
SNAPSHOTS=30

# Excludes files by size (in MB)
MAXSIZE=500

# Exclude files by type (needs full path)
EXCLUDES=/root/scripts/exclude-list.txt

echo

# Make sure only root can run this.
if [ $EUID -ne 0 ] ; then
  echo ":: You must be root to run this script."
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
    echo -e ":: Backup directory for host $BLUE$HOST.$DOMAIN$NC exists."
    sleep $DELAY
  else
    echo -e ":: Creating backup directory for host $BLUE$HOST.$DOMAIN$NC."
    sleep $DELAY
    mkdir -p $BACKUPDIR/$DOMAIN/$HOST
  fi
done

echo "::"
echo ":: Checking if remote hosts are online..."
echo "::"
sleep $DELAY

for HOST in ${CLIENT[*]} ; do
  echo -e ":: Checking if host $BLUE$HOST.$DOMAIN$NC is online..."
  sleep $DELAY
  CONNECT=$(ssh -o BatchMode=yes -o ConnectTimeout=5 root@$HOST echo OK 2>&1)
  if [ "$CONNECT" = "OK" ] ; then
    echo -e ":: Host $BLUE$HOST.$DOMAIN$NC is ${GREEN}online${NC}."
    sleep $DELAY
  else
    echo -e ":: Host $BLUE$HOST.$DOMAIN$NC is ${RED}offline${NC}."
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
    echo -e ":: Backing up host $GREEN$HOST.$DOMAIN$NC..."
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
    # Synchronize remote host with local snapshot.0 directory
    rsync -a --delete --exclude-from $EXCLUDES --delete-excluded \
      --max-size=${MAXSIZE}mb -e ssh root@$HOST:{/home,/etc} \
      $BACKUPDIR/$DOMAIN/$HOST/snapshot.0
    # Update timestamp
    echo ":: Updating timestamp..."
    sleep $DELAY
    touch $BACKUPDIR/$DOMAIN/$HOST/snapshot.0
    echo -e ":: [${GREEN}OK${NC}]"
    sleep $DELAY
  else
    echo -e ":: Skipping unreachable host $RED$HOST.$DOMAIN$NC."
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




