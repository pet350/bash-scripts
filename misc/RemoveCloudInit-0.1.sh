#!/bin/bash

# Source function library.
source /lib/lsb/init-functions

export RUN_CMD="$(basename $0)"
export VERSION="0.1"

declare -ig TRUE=1
declare -ig FALSE=0

declare -ig SUCCESS=0
declare -ig FAILURE=1

declare -ig BOL_VERBOSE=$TRUE
declare -ig BOL_HELP=$FALSE
declare -ig BOL_WAIT=$TRUE

declare -ig EXIT_VAL=$SUCCESS
declare -ig RETVAL=$SUCCESS
declare -ig VAR_WAIT=1

if [ $(id -u) -gt 0 ]; then
    echo -e "$RUN_CMD\tVersion: $VERSION\nMust be ran as root"
    exit $EXIT_VAL
fi

# Define Directoy Prefix String Variables
export BIN_PREFIX="/bin"
export SBIN_PREFIX="/sbin"
export USER_PREFIX="/usr"

# Define Binary Variables
export FALSE_BIN="$BIN_PREFIX/false"
export TRUE_BIN="$BIN_PREFIX/true"
export RM_BIN="$BIN_PREFIX/rm"
export APT_BIN="$USER_PREFIX$BIN_PREFIX/apt"
export ECHO_BIN="$BIN_PREFIX/echo"
export SLEEP_BIN="$BIN_PREFIX/sleep"
export TEE_BIN="$USER_PREFIX$BIN_PREFIX/tee"

# Function Display Log Results
function LOG_RESULTS()
{
  if [ $RETVAL -eq $SUCCESS ]; then
        log_success_msg "Success!"
  else
        log_failure_msg "Failure!"
  fi
  return $RETVAL
};

for i in "$@"
do
case $i in
'-h' | '--help')
	export BOL_HELP=$TRUE
	;;
'-v' | '--verbose')
	export VERBOSE="--verbose"
        export BOL_VERBOSE=$TRUE
        ;;
'-q' | '--quiet')
	export VERBOSE=""
	export BOL_VERBOSE=$FALSE
	;;
'-t' | '--test')
	export APT_BIN="$TRUE_BIN"
	export RM_BIN="$TRUE_BIN"
	export ECHO_BIN="$TRUE_BIN"
	export TEE_BIN="$TRUE_BIN"
	;;
-w=* | --wait=*)
        X="${i#*=}"
        VAR_WAIT=$((X))
	export BOL_WAIT=$TRUE
        ;;
'--no-wait')
	export BOL_WAIT=$FALSE
	;;
esac
done

if [ $BOL_VERBOSE -eq $TRUE ]; then printf "Setting Datasource List:\t"; fi
$ECHO_BIN 'datasource_list: [ None ]' | $TEE_BIN /etc/cloud/cloud.cfg.d/90_dpkg.cfg
export RETVAL=$?
EXIT_VAL=$((EXIT_VAL+RETVAL))
if [ $BOL_WAIT -eq $TRUE ]; then $SLEEP_BIN $VAR_WAIT; fi
if [ $BOL_VERBOSE -eq $TRUE ]; then LOG_RESULTS; fi

if [ $BOL_VERBOSE -eq $TRUE ]; then printf "Purging Cloud Init:\t\t"; fi
$APT_BIN remove --purge -y cloud-init >/dev/null 2>/dev/null
export RETVAL=$?
EXIT_VAL=$((EXIT_VAL+RETVAL))
if [ $BOL_WAIT -eq $TRUE ]; then $SLEEP_BIN $VAR_WAIT; fi
if [ $BOL_VERBOSE -eq $TRUE ]; then LOG_RESULTS; fi

if [ $BOL_VERBOSE -eq $TRUE ]; then printf "Removing Cloud Directories:\t"; fi
$RM_BIN -rf /etc/cloud/; $RM_BIN -rf /var/lib/cloud/
export RETVAL=$?
EXIT_VAL=$((EXIT_VAL+RETVAL))
if [ $BOL_WAIT -eq $TRUE ]; then $SLEEP_BIN $VAR_WAIT; fi
if [ $BOL_VERBOSE -eq $TRUE ]; then LOG_RESULTS; fi

exit $EXIT_VAL