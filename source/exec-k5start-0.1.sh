#!/bin/bash
# exec-k5start.sh.sh
# Version 0.1
# Peter Talbott

## Simple Script To Run init-k5start.sh upon opening a shell terminal

case ${TERM,,} in
  dumb)
     # If running in a 'dumb' terminal, do nothing
     # This mainly occurs when transfering files via 'scp'
     ;;
  *)
     # Any other terminal we will continue
     if [ -f /usr/local/sbin/init-k5start.sh ]; then
       /usr/local/sbin/init-k5start.sh init
       ## use 'quick' instead of 'init' for detailed output
       export K5_EXIT_VAL=$?
     fi
     ;;
esac
