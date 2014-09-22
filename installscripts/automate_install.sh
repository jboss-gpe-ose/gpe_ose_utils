#!/bin/sh

installscipt=install_fuse.sh

# Test remote host:port availability (TCP-only as UDP does not reply)
function checkRemotePort() {
    (echo >/dev/tcp/$1/$2) &>/dev/null
    if [ $? -eq 0 ]; then
        echo -en "$1:$2 is open.\n\n"
        socketIsOpen=0
    else
        echo -en "$1:$2 is closed.\n"
        socketIsOpen=1
    fi
}

for serverHost in $(cat hosts.txt)
do
  echo -en "\n\n*********	$serverHost\n"
  checkRemotePort $serverHost 22
  if [ $socketIsOpen -eq 0 ]; then
      scp $installscipt root@$serverHost:/tmp
      ssh root@$serverHost "chmod 755 /tmp/$installscipt; /tmp/$installscipt"
      echo -en "\n"
  fi
done

oo-admin-ctl-cartridge -c import-node --activate
oo-admin-broker-cache --clear --console
service openshift-broker restart
