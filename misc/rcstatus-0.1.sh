#!/bin/bash
# Simple Script To Display Status Of All Scripts in rc5.d

# Source function library.
if [ -f /lib/lsb/init-functions ]; then
  source /lib/lsb/init-functions
else
  alias log_success_msg="echo -e"
  alias log_failure_msg="echo -e"
fi

export RUN_CMD="$(basename $0)"
export VERSION="0.5"

# Define TRUE/FALSE
declare -ig TRUE=1
declare -ig FALSE=0

# Define SUCCESS/FAILURE
declare -ig SUCCESS=0
declare -ig FAILURE=1

# Define Global Boolean Variables
declare -ig BOL_VERBOSE=$FALSE
declare -ig BOL_HELP=$FALSE

declare -ig RETVAL=$SUCCESS

export CFG_PREFIX="/etc"
export USR_PREFIX="/usr"
export BIN_PREFIX="/bin"
export SBIN_PREFIX="/sbin"
export ENABLED_PREFIX="$CFG_PREFIX/rc5.d"
export INITIAL_PREFIX="$CFG_PREFIX/init.d"

# Define Binary Variables
export SYSCTL_BIN="$BIN_PREFIX/systemctl"
export UPDATE_RC_BIN="$USER_PREFIX$SBIN_PREFIX/update-rc.d"
export SLEEP_BIN="$BIN_PREFIX/sleep"

export SYSCTL_OPT="status"

function LOG_RESULTS()
{
  if [ $RETVAL -eq $SUCCESS ]; then
    log_success_msg "$SYSCTL_BIN $SYSCTL_OPT $PROGRAM Success!"
  else
    log_failure_msg "$SYSCTL_BIN $SYSCTL_OPT $PROGRAM Failure!"
  fi
  return $RETVAL
};


for DIRECTORY in $(ls -1 $ENABLED_PREFIX); do
  export PROGRAM=${DIRECTORY:3}
  $INITIAL_PREFIX/$PROGRAM status
  export RETVAL=$?
  LOG_RESULTS
  echo -e "******************************************** \n\n"
done
