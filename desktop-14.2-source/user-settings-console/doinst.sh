#!/bin/sh

config() {
  NEW="$1"
  OLD="$(dirname $NEW)/$(basename $NEW .new)"
  # If there's no config file by that name, mv it over:
  if [ ! -r $OLD ]; then
    mv $NEW $OLD
  elif [ "$(cat $OLD | md5sum)" = "$(cat $NEW | md5sum)" ]; then # toss the redundant copy
    rm $NEW
  fi
  # Otherwise, we leave the .new copy for the admin to consider...
}

config root/.bashrc.new
config root/.bash_profile.new
config root/.bash_logout.new
config etc/skel/.bashrc.new
config etc/skel/.bash_profile.new
config etc/skel/.bash_logout.new
config etc/profile.d/lang.sh.new
config etc/rc.d/rc.font.new
config usr/share/vim/vimrc.new

