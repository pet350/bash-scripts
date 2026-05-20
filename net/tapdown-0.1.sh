#!/bin/bash
# Shell Script By: Peter Talbott

# Source function library.
source /lib/lsb/init-functions

export RUN_CMD="$(basename $0)"
export VERSION="0.1"

# Define TRUE/FALSE
declare -ig TRUE=1
declare -ig FALSE=0

# Define SUCCESS/FAILURE
declare -ig SUCCESS=0
declare -ig FAILURE=1

declare -ig RETVAL=$SUCCESS
declare -ig INDEX=-1

# Define Directoy Prefix String Variables
export BIN_PREFIX="/bin"
export SBIN_PREFIX="/sbin"
export USER_PREFIX="/usr"

# Define Binary Executable Variables
export IP_BIN="$BIN_PREFIX/ip"
export USER="root"

# Define Global Boolean Variables
declare -ig BOL_VERBOSE=$FALSE
declare -ig BOL_HELP=$FALSE

if [ $(id -u) -gt 0 ]; then
    echo -e "$RUN_CMD\tVersion: $VERSION\nMust be ran as root"
    exit $RETVAL
fi

if [ $# -eq 0 ]; then
    echo -e "$RUN_CMD\tVersion: $VERSION\nUsage: $RUN_CMD [Tap Name]"
    exit $RETVAL
fi

function LOG_RESULTS()
{
  if [ $RETVAL -eq $SUCCESS ]; then
    log_success_msg "$IP_BIN $OPTS: Success!"
  else
    log_failure_msg "$IP_BIN $OPTS: Failure!"
  fi
  return $RETVAL
};

function do_HELP()
{
  echo -e "$RUN_CMD\tVersion: $VERSION\nUsage: $RUN_CMD [Tap Name]\n"
  printf "%-12s:\t%-26s\n" "--help" "Show This Help Section"
  printf "%-12s:\t%-26s\n" "--verbose" "Output More Details"
  printf "%-12s:\t%-26s\n\n" "[Tap Name]" "Removes TAP Device Named [Tap Name]"
  exit $SUCCESS
};

for i in "$@"
do
case $i in
'-h' | '--help')
	export BOL_HELP=$TRUE
	;;
'-v' | '--verbose')
	export BOL_VERBOSE=$TRUE
	;;
*)
	export TAP_NAME="$i"
	;;
esac
done

declare IP_OPT_ARRAY=(	"link set $TAP_NAME down" \
			"tuntap del dev $TAP_NAME mode tap" );

if [ $BOL_HELP -eq $TRUE ]; then do_HELP; fi


while [ $((INDEX+1)) -lt ${#IP_OPT_ARRAY[@]} ]; do
  ((INDEX++))
  export OPTS="${IP_OPT_ARRAY[$((INDEX))]}"
  $IP_BIN $OPTS
  export RETVAL=$?
  if [ $BOL_VERBOSE -eq $TRUE ]; then LOG_RESULTS; fi
done

exit $RETVAL