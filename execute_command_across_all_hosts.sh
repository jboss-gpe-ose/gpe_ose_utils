#!/bin/sh

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
      ssh root@$serverHost 'oo-admin-ctl-gears stopall'
      echo -en "\n"
  fi
done

service openshift-broker restart
