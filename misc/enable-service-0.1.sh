#!/bin/bash

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

declare -ig TRUE=1
declare -ig FALSE=0

declare -ig SUCCESS=0
declare -ig FAILURE=1

declare -ig BOL_VERBOSE=$FALSE
declare -ig BOL_HELP=$FALSE
declare -ig BOL_WAIT=$TRUE

declare -ig EXIT_VAL=$FAILURE
declare -ig INDEX_VAL=-1
declare -ig VAR_WAIT=1

if [ $(id -u) -gt 0 ]; then
    echo -e "$RUN_CMD\tVersion: $VERSION\nMust be ran as root"
    exit $EXIT_VAL
fi

if [ $# -eq 0 ]; then
    echo -e "$RUN_CMD\tVersion: $VERSION\nUsage: $RUN_CMD { service1 service2 service3  } --help"
    exit $EXIT_VAL
fi

# Define Directoy Prefix String Variables
export BIN_PREFIX="/bin"
export SBIN_PREFIX="/sbin"
export USER_PREFIX="/usr"

# Define Binary Variables
export SYSCTL_BIN="$BIN_PREFIX/systemctl"
export UPDATE_RC_BIN="$USER_PREFIX$SBIN_PREFIX/update-rc.d"
export SLEEP_BIN="$BIN_PREFIX/sleep"

# Define Option Variables
export SYSCTL_OPT=""
export EXT_OPT=""

function RUN_SYSCTL()
{
  declare -i RETVAL=$FAILURE
  if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Begin Section: $SYSCTL_BIN $SYSCTL_OPT ${ARGS_ARRAY[@]} $EXT_OPT"; fi
  for DATA in ${ARGS_ARRAY[@]}; do
    if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Executing: $SYSCTL_BIN $SYSCTL_OPT $DATA $EXT_OPT"; fi
    $SYSCTL_BIN $SYSCTL_OPT $DATA $EXT_OPT
    RETVAL=$?

    if [ $RETVAL -eq $SUCCESS ]; then
        log_success_msg "$SYSCTL_BIN $SYSCTL_OPT $DATA $EXT_OPT Success!"
    else
        log_failure_msg "$SYSCTL_BIN $SYSCTL_OPT $DATA $EXT_OPT Failure!"
    fi
    if [ $BOL_WAIT -eq $TRUE ]; then $SLEEP_BIN $VAR_WAIT; fi
  done
  if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "End Section: $SYSCTL_BIN $SYSCTL_OPT ${ARGS_ARRAY[@]} $EXT_OPT"; fi
  echo -e "\n\n"
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
-w=* | --wait=*)
        X="${i#*=}"
        VAR_WAIT=$((X))
	export BOL_WAIT=$TRUE
        ;;
'--no-wait')
	export BOL_WAIT=$FALSE
	;;
*)
	(( INDEX_VAL++))
	ARGS_ARRAY[(($INDEX_VAL))]="$i"
	;;
esac
done


export SYSCTL_OPT="unmask"
RUN_SYSCTL
EXIT_VAL=$?

export SYSCTL_OPT="enable"
RUN_SYSCTL
EXIT_VAL=$EXIT_VAL+$?

export SYSCTL_OPT="start"
RUN_SYSCTL
EXIT_VAL=$EXIT_VAL+$?

export SYSCTL_OPT="-f"
export EXT_OPT="defaults enable"
export SYSCTL_BIN="$UPDATE_RC_BIN"
RUN_SYSCTL
EXIT_VAL=$EXIT_VAL+$?

if [ $EXIT_VAL -eq $SUCCESS ]; then
        log_success_msg "$RUN_CMD $@: Success!"
else
        log_failure_msg "$RUN_CMD $@: Failure!"
fi

exit $EXIT_VAL


