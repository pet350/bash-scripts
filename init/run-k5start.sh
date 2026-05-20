#!/bin/sh
PREFIX="/usr/local/sbin"
SCRIPT="init-k5start.sh"
OPTIONS="start --verbose --daemon --renew=60"
if [ -f $PREFIX/$SCRIPT ]; then
  $PREFIX/$SCRIPT $OPTIONS
  RETVAL=$?
  klist
else
  echo -e "Script Not Found!"
  RETVAL=1
fi
exit $RETVAL
