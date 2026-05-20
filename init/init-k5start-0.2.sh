#! /bin/bash
### BEGIN INIT INFO
# Provides:          Kerberos5-Tokens
# Required-Start:    $network $remote_fs $syslog $all
# Required-Stop:
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Initialize Kerberos 5 Token Upon Login
# Description:       Initialize Kerberos 5 Token Upon Login
### END INIT INFO
# chkconfig: 2345 08 08
### By: Peter Talbott 2019-06-01, 2019-10-19,10-20

# Define Initial String Variables
export __HOME=~
export __RUN_PREFIX="/usr/bin"
export __PID_PREFIX="/run"
export __SCRIPT_NAME="k5start"
export __PID_FILE="$__PID_PREFIX/$__SCRIPT_NAME.pid"
export __CHILD_PID_FILE="$__PID_PREFIX/$__SCRIPT_NAME.child.pid"
export __EXEC_FILE="$__RUN_PREFIX/$__SCRIPT_NAME"
export __KEYTAB="$__HOME/.config/$(whoami).keytab"
export __DAEMON_OPTIONS=""
export __KEYTAB_OPTION=""
export __PID_FILE_OPTION=""
export __LOG_OPTIONS="-L"

# Source LSB function library.
source /lib/lsb/init-functions

export VERBOSE="-q"
export RUN_CMD="$(basename $0)"
export _VER=0.2

# Define TRUE/FALSE Variables
declare -ig TRUE=1
declare -ig FALSE=0

# Define SUCCESS/FAILURE Variables
declare -ig SUCCESS=0
declare -ig FAIL=1

# Define BOOLEAN Variables
declare -ig BOL_HELP=$FALSE
declare -ig BOL_START=$FALSE
declare -ig BOL_STOP=$FALSE
declare -ig BOL_VERBOSE=$FALSE
declare -ig BOL_DAEMON=$FALSE
declare -ig BOL_QUIET=$FALSE

# Define Integer Variables
declare -ig RETVAL=$FAIL
declare -ig INTERVAL=30

# Check To See If There Are Any Command Line Options
if [ $# -eq 0 ]; then
    echo -e "$RUN_CMD Version $_VER\nUsage: $RUN_CMD {start|stop|restart}"
    exit $FAIL
fi

# Function to Report the Outcome of Another Process
function Report_Status()
{
  if [ $BOL_QUIET -eq $FALSE ]; then
    if [ $RETVAL -eq $SUCCESS ]; then
        log_success_msg "OK!"
    else
        log_failure_msg "FAIL!"
    fi
  fi
};

# Parse Command Line Options
for i in "$@"
do
case $i in
'-h' | '--help')
	export BOL_HELP=$TRUE
	;;
'-v' | '--verbose')
	export BOL_VERBOSE=$TRUE
	export VERBOSE="-v"
	;;
'-q' | '--quiet')
	export BOL_QUIET=$TRUE
	;;
'start')
	export BOL_STOP=$FALSE
        export BOL_START=$TRUE
        ;;
'stop')
        export BOL_STOP=$TRUE
	export BOL_START=$FALSE
        ;;
'restart')
        export BOL_STOP=$TRUE
        export BOL_START=$TRUE
        ;;
'-d' | '--daemon')
	export BOL_DAEMON=$TRUE
	;;
esac
done

# If Both --verbose and --quiet are included command line options
# Set --quiet as Priority and ignore --verbose
if [ $BOL_QUIET -eq $TRUE ]; then
  export BOL_VERBOSE=$FALSE
  export VERBOSE="-q"
fi

# Check To See If Keytab File Exists
if [ ! -f $__KEYTAB ]; then
  if [ $BOL_QUIET -eq $FALSE ]; then
    log_failure_msg "Error! $__KEYTAB Does Not Exist!"
  fi
  exit $FAIL
fi

# Assemble Keytab and PID File Options
export __KEYTAB_OPTION="-f $__KEYTAB"
export __PID_FILE_OPTION="-p $__PID_FILE"

# Assemble Daemon Options IF --daemon is Enabled at the Command Line
if [ $BOL_DAEMON -eq $TRUE ]; then
  export __DAEMON_OPTIONS="-a -b -K $INTERVAL $__PID_FILE_OPTION"
fi

# Assemble All 'k5start' Options
export __OPTIONS="$__KEYTAB_OPTION $__DAEMON_OPTIONS $__LOG_OPTIONS $VERBOSE"

if [ $BOL_STOP -eq $TRUE ]; then
        if [ $BOL_QUIET -eq $FALSE ]; then
		log_daemon_msg "Stopping $RUN_CMD"
	fi
	if [ -f $__PID_FILE ]; then
	  for DATA in $(cat $__PID_FILE); do
	    if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "kill $DATA"; fi
	    kill $DATA
	    export RETVAL=$?
	  done
	fi
	killall $__SCRIPT_NAME  2>/dev/null
        sleep 1
	Report_Status
fi

if [ $BOL_START -eq $TRUE ]; then
	if [ ! -f $__PID_FILE ]; then
	   if [ $BOL_QUIET -eq $FALSE ]; then
		log_daemon_msg "Starting $RUN_CMD"
	   fi
	   if [ $BOL_VERBOSE -eq $TRUE ]; then
		echo -e "$__EXEC_FILE $__OPTIONS"
	   fi
	   $__EXEC_FILE $__OPTIONS
           export RETVAL=$?
	else
	   if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Already Running!"; fi
	   export RETVAL=$SUCCESS
	fi
	Report_Status
fi

exit $RETVAL
