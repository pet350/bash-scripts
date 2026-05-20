#!/bin/bash

# Source function library.
LSB_FUNCTIONS="/lib/lsb/init-functions"
ls /usr/local/scripts/include/*.sh >/dev/null 2>/dev/null 3>/dev/null
if [ $? -eq 0 ] && [ -f $LSB_FUNCTIONS ]; then
  for INCLUDE_FILE in $LSB_FUNCTIONS $(ls -1 /usr/local/scripts/include/*.sh); do
    . $INCLUDE_FILE
  done
else
  echo -e "Error! Missing source files!"
  exit 1
fi

export RUN_CMD="$(basename $0)"
_VER=0.2

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

for DATA in $@; do
  echo -e "Disabling Profile: $DATA"
  ln -s /etc/apparmor.d/$DATA /etc/apparmor.d/disable/
  apparmor_parser -R /etc/apparmor.d/$DATA
done

