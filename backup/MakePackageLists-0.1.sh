#!/bin/bash
# Script To Log The Installed Packages
# By: Peter Talbott

source /usr/local/src/pkg-tools.sh

VERSION=0.1

BOL_ShowIndex=$FALSE
BOL_WriteIndex=$FALSE

RUN_CMD="$(basename $0)"
RUN_PREFIX="/usr/local/sbin"
LN_PREFIX="../scripts/backup"
SCRIPT_PREFIX="/usr/local/scripts/backup"

CRON_PREFIX="/etc/cron.d"
CRON_FILE="$CRON_PREFIX/${RUN_CMD%.*}_job"

# Define Random Time Variables
declare -ig RAND_MINUTE=$(printf "%f" $(/bin/date +%N)|cut --byte=1,2,3)
declare -ig RAND_HOUR=$(printf "%f" $(/bin/date +%N)|cut --byte=1,2,3)
declare -ig RAND_DOW=$(printf "%f" $(/bin/date +%N)|cut --byte=1,2,3)

# Generate A Random Minute/Hour/DOW
while [ $((RAND_MINUTE)) -gt 59 ]; do _RAND_MINUTE=$(printf "%f" $(/bin/date +%N)|cut --byte=1,3); RAND_MINUTE=$((_RAND_MINUTE)); done
while [ $((RAND_HOUR)) -gt 23 ]; do _RAND_HOUR=$(printf "%f" $(/bin/date +%N)|cut --byte=1,4); RAND_HOUR=$((_RAND_HOUR)); done
while [ $((RAND_DOW)) -gt 6 ]; do _RAND_DOW=$(printf "%f" $(/bin/date +%N)|cut --byte=1); RAND_DOW=$((_RAND_DOW));  done

if [ ! -f $RUN_PREFIX/$RUN_CMD ]; then
  cd "$RUN_PREFIX"
  ln -s "$LN_PREFIX/$RUN_CMD"
fi

if [ ! -f $CRON_FILE ]; then
  echo "## Cron File To Run $RUN_CMD Version $VERSION Daily" >$CRON_FILE
  echo "" >>$CRON_FILE
  echo "SHELL=/bin/sh" >>$CRON_FILE
  echo "PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin" >>$CRON_FILE
  echo "" >>$CRON_FILE
  echo "$RAND_MINUTE $RAND_HOUR * * * root $RUN_PREFIX/$RUN_CMD" >>$CRON_FILE
fi

StoreLists
# Done!
