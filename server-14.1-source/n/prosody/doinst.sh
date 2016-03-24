# Create prosody group 
if ! grep -q "^prosody:" /etc/group ; then
  groupadd -g 274 prosody
  echo ":: Added prosody group."
  sleep 3
fi

# Create prosody user 
if ! grep -q "^prosody:" /etc/passwd ; then
  useradd -u 274 -d /dev/null -s /bin/false -g 274 prosody
  echo ":: Added prosody user."
  sleep 3
fi

config() {
  NEW="$1"
  OLD="$(dirname $NEW)/$(basename $NEW .new)"
  if [ ! -r $OLD ]; then
    mv $NEW $OLD
  elif [ "$(cat $OLD | md5sum)" = "$(cat $NEW | md5sum)" ]; then
    rm $NEW
  fi
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

config etc/prosody/prosody.cfg.lua.new
config etc/prosody/migrator.cfg.lua.new
config etc/prosody/certs/openssl.cnf.new
config etc/prosody/certs/localhost.key.new
config etc/prosody/certs/example.com.key.new
config etc/prosody/certs/example.com.crt.new
config etc/prosody/certs/Makefile.new
config etc/prosody/certs/localhost.cnf.new
config etc/prosody/certs/example.com.cnf.new
config etc/prosody/certs/localhost.crt.new

preserve_perms etc/rc.d/rc.prosody.new

