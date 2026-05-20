#!/bin/bash
# Shell Script By: Peter Talbott
# Autostart script to run compton after system load goes below threshold

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
export VERSION="0.1"

if [ ${#WAIT_TIME} -eq 0 ]; then declare -ig WAIT_TIME=15;		fi
if [ ${#THRESHOLD} -eq 0 ]; then declare -ig THRESHOLD=300;		fi
if [ ${#SYS_LOAD}  -eq 0 ]; then declare -ig SYS_LOAD=$(GET_SYS_LOAD);	fi

while [ $((SYS_LOAD)) -gt $((THRESHOLD)) ]; do
  $SLEEP_BIN $WAIT_TIME
  SYS_LOAD=$(GET_SYS_LOAD)
done

declare -i RETVAL=$FAILURE

if [ ${#DESKTOP_SESSION} -gt 0 ]; then
  case ${DESKTOP_SESSION,,} in
    'lxde' | 'openbox' | 'openbox-session')
      $COMPTON_BIN
      export RETVAL=$?
      ;;
  esac
  LOG_RESULTS
fi

exit $RETVAL
