#!/bin/bash

INCLUDE="/usr/local/scripts/include/comdef.sh"
if [ -f $INCLUDE ]; then
  . $INCLUDE
else
  echo -e "Error $INCLUDE not found!"
  exit 1
fi

unset INCLUDE

PROG="xscreensaver"
NONE=0
PROG_ID=$(pgrep $PROG)
if [ ${#PROG_ID} -ne $NONE ]; then
  killall $PROG
  RETVAL=$?
else
  echo -e "$PROG Not Running!"
  RETVAL=$SUCCESS
fi

exit $RETVAL