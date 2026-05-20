#! /bin/bash


# Define True/False Boolean Variables
declare -ig TRUE=1
declare -ig FALSE=0

# Define Success/Failure Boolean Variables
declare -ig SUCCESS=0
declare -ig FAILURE=1

# Define Directoy Prefix String Variables
export BIN_PREFIX="/bin"
export CFG_PREFIX="/etc"
export SBIN_PREFIX="/sbin"
export USER_PREFIX="/usr"
export AUTO_PREFIX="$CFG_PREFIX/xen/init"

# Define Application Binaries
export XL_BIN="$USER_PREFIX$SBIN_PREFIX/xl"
export WC_BIN="$USER_PREFIX$BIN_PREFIX/wc"
export PS_BIN="$BIN_PREFIX/ps"
export GREP_BIN="$BIN_PREFIX/grep"
export SLEEP_BIN="$BIN_PREFIX/sleep"
export KILL_BIN="$BIN_PREFIX/kill"
export OVCTL_BIN="$USER_PREFIX$BIN_PREFIX/ovs-vsctl"

# Define Application Options
export DEL_PORT_OPTION="del-port"
export SHOW_OPTION="show"
export GREP_OPTION="error:"

function ClearOVCTL()
{
  declare -i BOL_RUN=$FALSE
  declare -i RETVAL=$FAILURE
  for DATA in $( $OVCTL_BIN $SHOW_OPTION | $GREP_BIN $GREP_OPTION ); do
    if [ $BOL_RUN -eq $TRUE ]; then
      $OVCTL_BIN $DEL_PORT_OPTION $DATA
      RETVAL=$?
    fi

    if [ $DATA == 'device' ]; then
      BOL_RUN=$TRUE
    else
      BOL_RUN=$FALSE
    fi
  done
  return $RETVAL
};


