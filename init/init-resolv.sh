#!/bin/bash
### BEGIN INIT INFO
# Provides:          init-resolv.conf-service
# Required-Start:    $network $remote_fs $syslog $openvswitch-configuration
# Required-Stop:     $network $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Setup resolv.conf
# Description:       Setup resolv.conf
### END INIT INFO
# chkconfig: 2345 08 08

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
_VER=0.1

if [ $(id -u) -gt 0 ]; then
    echo "Must be ran as root"
    exit 1
fi

if [ $# -eq 0 ]
  then
    echo -e "$RUN_CMD Version $_VER\nUsage: $RUN_CMD { start | stop | restart } --help"
    exit 1
fi

export PREFIX="/etc"
export TARGET="$PREFIX/resolv.conf"
export TARGET_OLD="$PREFIX/resolv.old"

# Define BOOLEAN Variables
declare -ig TRUE=1
declare -ig FALSE=0

declare -ig BOL_START=$FALSE
declare -ig BOL_STOP=$FALSE
declare -ig BOL_RUN=$FALSE
declare -ig BOL_VERBOSE=$FALSE
declare -ig BOL_HELP=$FALSE

declare -ag SEARCH_ARRAY=('gigaware.lan' 'trusted.gigaware.lan');
declare -ag HEADER_ARRAY=('## resolv.conf' '## Setup with init-resolv.sh' "## Version $_VER" 'By: Peter Talbott');
declare -ag SERVER_ARRAY=('172.16.184.3' '172.16.184.2' '172.16.184.1');

declare -ig SEARCH_ARRAY_COUNT=${#SEARCH_ARRAY[@]}
declare -ig HEADER_ARRAY_COUNT=${#HEADER_ARRAY[@]}
declare -ig SEARCH_ARRAY_INDEX=$(( SEARCH_ARRAY_COUNT -1))
declare -ig HEADER_ARRAY_INDEX=$(( HEADER_ARRAY_COUNT -1))
declare -ig VAR_UNKNOWN=0
declare -ig VAR_WAIT=1

export SEARCH_STRING="search"
export NAMESERVER_STRING="nameserver"

function do_STOP()
{
   if [ -e $TARGET_OLD ]; then
	mv $TARGET_OLD $TARGET $VERBOSE
   fi
   return 0
}

function do_START()
{
   sleep $VAR_WAIT
   if [ -e $TARGET ]; then
	   mv $TARGET $TARGET_OLD $VERBOSE
   fi
   touch $TARGET
   printf "## -------------------------------" >>$TARGET
   # Write the Header of the file
   for i in ${HEADER_ARRAY[@]}; do
	if [ $i == '##' ]; then
		printf "\n" >>$TARGET
	fi
	printf "%s " $i >>$TARGET
   done
   printf "\n## -------------------------------\n" >>$TARGET
   printf "\n%s " "$SEARCH_STRING" >>$TARGET
   for i in ${SEARCH_ARRAY[@]}; do
	printf "%s " $i >>$TARGET
   done
   printf "\n\n" >>$TARGET
   for i in ${SERVER_ARRAY[@]}; do
	printf "%-11s %-16s\n" $NAMESERVER_STRING $i >>$TARGET
   done
   return 0
}

for i in "$@"
do
case $i in
'start')
        export BOL_START=$TRUE
        ;;
'stop')
	export BOL_STOP=$TRUE
	;;
'restart')
	export BOL_STOP=$TRUE
	export BOL_START=$TRUE
	;;
'-v' | '--verbose')
	export VERBOSE="--verbose"
        export BOL_VERBOSE=$TRUE
        ;;
'-h' | '--help')
	export BOL_HELP=$TRUE
	;;
*)
        (( VAR_UNKNOWN++ ))
	echo -e "Unknown Parameter $i"
        ;;
esac
done

if [ $BOL_HELP -eq $TRUE ]; then
        BOL_START=$FALSE
        BOL_STOP=$FALSE
	#do_HELP
        RETVAL=1
fi

if [ $VAR_UNKNOWN -gt 0 ]; then
	BOL_START=$FALSE
	BOL_STOP=$FALSE
	RETVAL=$VAR_UNKNOWN
fi

if [ $BOL_STOP -eq $TRUE ]; then
        log_daemon_msg "Stopping $RUNCMD"
        do_STOP
        RETVAL=$?
fi

if [ $BOL_START -eq $TRUE ]; then
        log_daemon_msg "Starting $RUNCMD"
	do_START
	RETVAL=$?
fi

if [ $RETVAL -eq 0 ]; then
        log_success_msg
else
	log_failure_msg
fi

exit $RETVAL
## Done!
