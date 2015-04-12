#!/bin/bash
#
# cleanmenu.sh
# (c) Niki Kovacs, 2014

CWD=$(pwd)
ENTRIESDIR=$CWD/desktop
ENTRIES=`ls $ENTRIESDIR` 
MENUDIRS="  /usr/share/applications \
            /usr/share/distcc \
            /opt/libreoffice4.4/share/xdg "

for MENUDIR in $MENUDIRS; do
	for ENTRY in $ENTRIES; do
		if [ -r $MENUDIR/$ENTRY ]; then
			echo ":: Updating $ENTRY."
			cat $ENTRIESDIR/$ENTRY > $MENUDIR/$ENTRY
		fi
	done
done

if [ -r /usr/share/applications/Thunar-bulk-rename.desktop ]; then
  if [ $(uname -m) == "x86_64" ]; then
    sed -i "s/\/usr\/lib\/Thunar/\/usr\/lib64\/Thunar/g" /usr/share/applications/Thunar-bulk-rename.desktop
  fi
fi



