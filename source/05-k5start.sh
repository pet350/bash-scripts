#!/bin/bash
## Simple Script To Run init-k5start.sh upon opening a shell terminal

declare -i EXIT_VAL=$FAILURE

if [ -f /usr/local/sbin/init-k5start.sh ]; then
  /usr/local/sbin/init-k5start.sh start --quiet
  EXIT_VAL=$?
fi

exit $EXIT_VAL

