#! /bin/bash
### By: Peter Talbott 2019-08-15

# Source function library.
source /lib/lsb/init-functions

export RUN_CMD="$(basename $0)"
export VERSION="0.1"

declare -ig TRUE=1
declare -ig FALSE=0

declare -ig SUCCESS=0
declare -ig FAILURE=1

if [ $(id -u) -gt 0 ]; then
    echo -e "$RUN_CMD\tVersion: $VERSION\nMust be ran as root"
    exit 1
fi

if [ $# -eq 0 ]; then
    echo -e "$RUN_CMD\tVersion: $VERSION\nUsage: $RUN_CMD { app1 app2 app3  } --help"
    exit 1
fi

# Define Directoy Prefix String Variables
export BIN_PREFIX="/bin"
export SBIN_PREFIX="/sbin"
export USER_PREFIX="/usr"

# Define Executable Binaries
export SYSCTL_BIN="$BIN_PREFIX/systemctl"
export LSMOD_BIN="$BIN_PREFIX/lsmod"
export GREP_BIN="$BIN_PREFIX/grep"
export APT_BIN="$USER_PREFIX$BIN_PREFIX/apt"
export MODPROBE_BIN="$SBIN_PREFIX/modprobe"
export SLEEP_BIN="$BIN_PREFIX/sleep"
export FALSE_BIN="$BIN_PREFIX/false"

# Define String Variables
export VERBOSE=""
export INSTALLED=""
export LIST="list"

# Define Boolean Variables
declare -ig BOL_VERBOSE=$FALSE
declare -ig BOL_HELP=$FALSE
declare -ig BOL_TEST=$FALSE
declare -ig BOL_DEBUG=$FALSE
declare -ig BOL_WAIT=$TRUE

# Define Integer Variables
declare -ig VAR_WAIT=1
declare -ig EXITVAL=$FAILURE
declare -ig CMDLINE_INDEX=-1

# Define Global Arrays
declare -ag APP_ARRAY=();

function GET_LIST()
{
  declare -i RETVAL=$FAILURE
  if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Parsing Output From: ($APT_BIN $LIST $INSTALLED 2>/dev/null | $GREP_BIN -v i386 | $GREP_BIN $TEMP_APP)"; fi
  while IFS= read -r line; do
    DATA="${line%%/*}"
    echo -e "$DATA"
  done< <($APT_BIN $LIST $INSTALLED 2>/dev/null | $GREP_BIN -v i386 | $GREP_BIN $TEMP_APP)
  RETVAL=$?
  return $RETVAL
}

for i in "$@"
do
case $i in
'--no-wait')
	export BOL_WAIT=$FALSE
	;;
'-h' | '--help')
	export BOL_HELP=$TRUE
	;;
'-t' | '--test')
	export BOL_TEST=$TRUE
	export MODPROBE_BIN=$FALSE_BIN
	export APT_BIN=$FALSE_BIN
	export GREP_BIN=$FALSE_BIN
	;;
'-i' | '--installed')
	export INSTALLED="--installed"
	;;
'-v' | '--verbose')
	export VERBOSE="--verbose"
        export BOL_VERBOSE=$TRUE
	;;
'-d' | '--debug')
        export VERBOSE="--verbose"
        export BOL_VERBOSE=$TRUE
	export BOL_DEBUG=$TRUE
        ;;
-w=* | --wait=*)
        X="${i#*=}"
        export VAR_WAIT=$((X))
	export BOL_WAIT=$TRUE
        ;;
*)
        (( CMDLINE_INDEX++ ))
	APP_ARRAY[$((CMDLINE_INDEX))]="$i"
        ;;
esac
done

for DATA in ${APP_ARRAY[@]}; do
  export TEMP_APP="$DATA"
  GET_LIST
  EXITVAL=$?
done

exit $EXITVAL
