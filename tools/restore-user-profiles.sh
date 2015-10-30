#!/bin/bash

if [ -d /etc/skel/.config ]; then
  continue
else
  echo
  echo ":: Les profils par défaut ne sont pas installés."
  echo
  exit 1
fi

echo

for UTILISATEUR in $(ls /home); do
  echo ":: Mise à jour du profil de l'utilisateur $UTILISATEUR."
  rm -rf /home/$UTILISATEUR/.config
  cp -R /etc/skel/.config /home/$UTILISATEUR/
  chown -R $UTILISATEUR:users /home/$UTILISATEUR/.config
done

echo
exit 0
