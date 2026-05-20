#!/bin/bash
# Down and Dirty script to start network

export RUN_CMD="$(basename $0)"
_VER=0.1

if [ $(id -u) -gt 0 ]; then
    echo -e "Must be ran as Root!!"
    exit 1
fi

declare -ig SUCCESS=0
declare -ig FAILURE=1

#if [ $# -eq 0 ]
#  then
#    echo -e "$RUN_CMD Version $_VER\nUsage: $RUN_CMD {apparmor profile}"
#    exit 1
#fi

export PING_DEST="yahoo.com"
export BIN_PREFIX="/bin"
export PING_BIN="$BIN_PREFIX/ping"

declare -ig RETVAL=$FAILURE

$PING_BIN -c 1 $PING_DEST >/dev/null
RETVAL=$?
if [ $RETVAL -ne $SUCCESS ]; then
  /etc/init.d/networking restart
  if [ $? -ne $SUCCESS ]; then RETVAL=$FAILURE; fi
fi

exit $RETVAL

