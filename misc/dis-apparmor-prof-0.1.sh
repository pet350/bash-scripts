#!/bin/bash

export RUN_CMD="$(basename $0)"
_VER=0.1

if [ $(id -u) -gt 0 ]; then
    echo -e "Must be ran as Root!!"
    exit 1
fi

if [ $# -eq 0 ]
  then
    echo -e "$RUN_CMD Version $_VER\nUsage: $RUN_CMD {apparmor profile}"
    exit 1
fi


cd /etc/apparmor.d

ln -s /etc/apparmor.d/$1 /etc/apparmor.d/disable/
apparmor_parser -R /etc/apparmor.d/$1

