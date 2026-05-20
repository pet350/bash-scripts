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

# Define NON Global Variables
declare -i RETVAL=$FAILURE
declare -i COUNT=0

# Define Directoy Prefix String Variables
export BIN_PREFIX="/bin"
export SBIN_PREFIX="/sbin"
export USER_PREFIX="/usr"

# Define Binary Executable Variables
export WC_BIN="$USER_PREFIX$BIN_PREFIX/wc"
export ABS_BIN="$USER_PREFIX$BIN_PREFIX/apt-btrfs-snapshot"
export BTRFS_BIN="$BIN_PREFIX/btrfs"

# Define Option String Variables
export DELETE_OPT="delete"
export LIST_OPT="list"
export SCRUB_OPT="scrub start /"

# Define Global Boolean Variables
declare -ig BOL_VERBOSE=$FALSE
declare -ig BOL_HELP=$FALSE
declare -ig BOL_START=$FALSE
declare -ig BOL_SCRUB=$FALSE

if [ $(id -u) -gt 0 ]; then
    echo -e "$RUN_CMD\tVersion: $VERSION\nMust be ran as root"
    exit $RETVAL
fi

if [ $# -eq 0 ]; then
    echo -e "$RUN_CMD\tVersion: $VERSION\nUsage: $RUN_CMD start|--help"
    exit $RETVAL
fi

function LOG_RESULTS()
{
  if [ $RETVAL -eq $SUCCESS ]; then
    log_success_msg "Success!"
  else
    log_failure_msg "Failure!"
  fi
  return $RETVAL
};

function do_HELP()
{
  echo -e "$RUN_CMD\tVersion: $VERSION\nUsage: $RUN_CMD [options]\n"
  printf "%-12s:\t%-26s\n" "--help" "Show This Help Section"
  printf "%-12s:\t%-26s\n" "--verbose" "Output More Details"
  printf "%-12s:\t%-26s\n" "--scrub" "Run BTRFS Scrub on Root Filesystem"
  printf "%-12s:\t%-26s\n\n" "start" "Clears All Apt BTRFS Snapshots"
  exit $SUCCESS
};

function CLEAR_ABS()
{
  declare -a RETVAL=$FAILURE
  declare COUNT=0
  for TEMP_DATA in $($ABS_BIN $LIST_OPT); do
    ((COUNT++))
    if [ $COUNT -gt 2 ]; then
      if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Executing:\t$ABS_BIN $DELETE_OPT $TEMP_DATA"; fi
      $ABS_BIN $DELETE_OPT $TEMP_DATA
      export RETVAL=$?
      if [ $BOL_VERBOSE -eq $TRUE ]; then LOG_RESULTS; fi
    fi
  done
  return $RETVAL
};

function CHECK_SNAPSHOTS()
{
  declare -i SNAPSHOT_COUNT=0
  for DATA in $($ABS_BIN $LIST_OPT); do
    if [ ${DATA:0:1} == '@' ]; then ((SNAPSHOT_COUNT++)); fi
  done
  return $SNAPSHOT_COUNT
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
'--scrub')
	export BOL_SCRUB=$TRUE
	;;
'start')
	export BOL_START=$TRUE
	;;
*)
	export UNKNOWN="$i"
	echo -e "Unknown Option:\t$UNKNOWN\n"
	;;
esac
done

if [ $BOL_HELP -eq $TRUE ]; then do_HELP; fi

if [ $BOL_START -eq $TRUE ]; then
  CHECK_SNAPSHOTS
  COUNT=$?
  if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Snapshots Found: $COUNT"; fi
  if [ $COUNT -gt 0 ]; then
    CLEAR_ABS
    export RETVAL=$?
    if [ $BOL_SCRUB -eq $TRUE ]; then $BTRFS_BIN $SCRUB_OPT; fi
  else
    export RETVAL=$SUCCESS
  fi
else
  echo -e "$RUN_CMD\tVersion: $VERSION\nNothing to do!"
  export RETVAL=$FAILURE
fi

if [ $BOL_VERBOSE -eq $TRUE ]; then LOG_RESULTS; fi

exit $RETVAL