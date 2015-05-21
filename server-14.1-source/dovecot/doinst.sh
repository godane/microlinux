# Create dovecot group 
if ! grep -q "^dovecot:" /etc/group ; then
groupadd -g 202 dovecot
echo ":: Added dovecot group."
sleep 3
fi

# Create dovecot user 
if ! grep -q "^dovecot:" /etc/passwd ; then
useradd -u 202 -g 202 -d /dev/null -s /bin/false dovecot
echo ":: Added dovecot user."
sleep 3
fi

# Create dovenull group 
if ! grep -q "^dovenull:" /etc/group ; then
groupadd -g 248 dovenull
echo ":: Added dovenull group."
sleep 3
fi

# Create dovenull user 
if ! grep -q "^dovenull:" /etc/passwd ; then
useradd -u 248 -g 248 -d /dev/null -s /bin/false dovenull
echo ":: Added dovenull user."
sleep 3
fi

config() {
  NEW="$1"
  OLD="$(dirname $NEW)/$(basename $NEW .new)"
  # If there's no config file by that name, mv it over:
  if [ ! -r $OLD ]; then
    mv $NEW $OLD
  elif [ "$(cat $OLD | md5sum)" = "$(cat $NEW | md5sum)" ]; then
    # toss the redundant copy
    rm $NEW
  fi
  # Otherwise, we leave the .new copy for the admin to consider...
}
preserve_perms() {
  NEW="$1"
  OLD="$(dirname $NEW)/$(basename $NEW .new)"
  if [ -e $OLD ]; then
    cp -a $OLD ${NEW}.incoming
    cat $NEW > ${NEW}.incoming
    mv ${NEW}.incoming $NEW
  fi
  config $NEW
}
preserve_perms etc/rc.d/rc.dovecot.new

