#!/bin/bash
### BEGIN INIT INFO
# Provides:          Init-ZoneMinder
# Required-Start:    $network $remote_fs $syslog $all
# Required-Stop:     $network $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Check Remote MYSQL and Start ZoneMinder Accordingly
# Description:       Check Remote MYSQL and Start ZoneMinder Accordingly
### END INIT INFO
# chkconfig: 2345 08 08

# Source function library.
source /lib/lsb/init-functions

export RUN_CMD="$(basename $0)"
_VER=0.3

if [ $(id -u) -gt 0 ]; then
    echo "Must be ran as root"
    exit 1
fi

if [ $# -eq 0 ]; then
    echo -e "$RUN_CMD Version $_VER\nUsage: $RUN_CMD { start | stop | restart } --help"
    exit 1
fi

# Define BOOLEAN Variables
declare -ig TRUE=1
declare -ig FALSE=0

declare -ig BOL_START=$FALSE
declare -ig BOL_STOP=$FALSE
declare -ig BOL_RUN=$FALSE
declare -ig BOL_VERBOSE=$FALSE
declare -ig BOL_HELP=$FALSE
declare -ig BOL_LOCAL_SERVICE_RUNNING=$FALSE
declare -ig BOL_REMOTE_SERVICE_RUNNING=$FALSE
declare -ig BOL_INIT_UVCVIDEO=$FALSE

# Declare Integers
declare -ig VAR_UNKNOWN=0
declare -ig VAR_TIME=30		# Seconds to wait
declare -ig VAR_GIVE_UP=60	# Loop "x" times before giving up

export BIN_PREFIX="/bin"
export USR_PREFIX="/usr"
export INIT_PREFIX="/etc/init.d"

export SYSCTL_BIN="$BIN_PREFIX/systemctl"
export ZMUPDATE_BIN="$USR_PREFIX$BIN_PREFIX/zmupdate.pl"

export LOCAL_SERVICE="zmdc.pl"
export LOCAL_SERVICE_NAME="zoneminder"

export MYSQL_ADMIN="$USR_PREFIX$BIN_PREFIX/mysqladmin"
export MYSQL_SERVER="sql.gigaware.lan"
export MYSQL_USER="ping"
export MYSQL_PASS="ping"

export ZMUPDATE_OPTS="-noi"

function CheckLocalService()
{
    RETVAL=$FALSE
    RESULT=$(pgrep $LOCAL_SERVICE)
    RESULT=$((RESULT)) # Force RESULT to be an INTEGER
    if [ $RESULT -gt 0 ]; then
        if [ $BOL_VERBOSE -eq $TRUE ]; then
		echo "$LOCAL_SERVICE_NAME: PID: $RESULT is Running!"
	fi
	RETVAL=$TRUE
    fi
    return $RETVAL
};

## First, create a user with no privileges
## mysql> GRANT USAGE ON *.* TO ping@'%' IDENTIFIED BY 'ping';
function CheckRemoteMYSQL()
{
    RETVAL=$FALSE
    MYSQL_OPTIONS="ping --host=$MYSQL_SERVER --user=$MYSQL_USER --password=$MYSQL_PASS"
    $MYSQL_ADMIN $MYSQL_OPTIONS 2>/dev/null 1>/dev/null
    RESULT=$?
    RESULT=$((RESULT)) # Force RESULT to be an INTEGER
    if [ $RESULT -eq 0 ]; then
        if [ $BOL_VERBOSE -eq $TRUE ]; then
                printf "SQL IS running on: %-25s" "$MYSQL_SERVER"
        fi
        RETVAL=$TRUE
    else
        if [ $BOL_VERBOSE -eq $TRUE ]; then
                printf "SQL IS NOT running on: %-25s" "$MYSQL_SERVER"
        fi
        RETVAL=$FALSE
    fi

    if [ $BOL_VERBOSE -eq $TRUE ]; then
            printf "\n"
    fi
    return $RETVAL
};

function do_START()
{
    COUNT=0
    CheckRemoteMYSQL
    BOL_REMOTE_SERVICE_RUNNING=$?
    if [ $BOL_VERBOSE -eq $TRUE ]; then
       printf "\n"
    fi
    while [ $BOL_REMOTE_SERVICE_RUNNING -eq $FALSE ]; do
	if [ $BOL_VERBOSE -eq $TRUE ]; then
                printf "%d / %d)" $((COUNT)) $((VAR_GIVE_UP))
	fi
	CheckRemoteMYSQL
	BOL_REMOTE_SERVICE_RUNNING=$?
	if [ $BOL_VERBOSE -eq $TRUE ]; then
		printf ": Waiting %-3d Seconds\n" $((VAR_TIME))
	fi
	sleep $((VAR_TIME))s
	(( COUNT++ ))
	if [ $COUNT -gt $VAR_GIVE_UP ]; then
		echo "Gave Up!"
		exit 1
	fi
    done
    if [ $BOL_INIT_UVCVIDEO -eq $TRUE ]; then /usr/local/sbin/init-uvcvideo.sh; fi
    $ZMUPDATE_BIN $ZMUPDATE_OPTS
    $SYSCTL_BIN start $LOCAL_SERVICE_NAME
    RETVAL=$?
    return $RETVAL
};

function do_STOP()
{
    $SYSCTL_BIN stop $LOCAL_SERVICE_NAME
    RETVAL=$?
    return $RETVAL
};

function do_HELP()
{
	printf "HELP! %-7s\tversion: %-4s\n" "$RUN_CMD" "$_VER"
	printf "%-15s\t\t%-25s\n\n" "-h or --help" "Disply This Help Message"
        printf "%-15s\t\t%-25s\n" "start" "Check SQL Connecttion and Start Local ZoneMinder Accordingly"
        printf "%-15s\t\t%-25s\n" "stop" "Stop ZoneMinder on Local Server"
        printf "%-15s\t\t%-25s\n\n" "restart" "Effectively runs stop and then start"
        printf "%-15s\t%-25s\t%-10s %d; %-10s %d\n" "-t=xx or --time=xx" "Set Wait Time To xx Seconds;" "Default is: " $((VAR_DFLT_TIME)) "Currently: " $((VAR_TIME))
        printf "%-15s\t%-25s\t%-10s %d; %-10s %d\n" "-g=xx or --give-up=xx" "Set xx Attempts Before Give Up;" "Default is: " $((VAR_DFLT_GIVE_UP)) "Currently: " $((VAR_GIVE_UP))
        printf "%-15s\t%-25s\t%-10s %-10s\n" "-s=yy or --server=yy" "Set yy to Server Host Name;" "Currently : " "$MYSQL_SERVER"
        printf "%-15s\t%-25s\n\n" "-v    or --verbose" "Be Verbose"
};


declare -ig VAR_DFLT_TIME=$((VAR_TIME))
declare -ig VAR_DFLT_GIVE_UP=$((VAR_GIVE_UP))

## Time to parse console options
## Best way I found was to set booleans to true or false here
for i in "$@"
do
case $i in
'-h' | '--help')
	export BOL_HELP=$TRUE
	;;
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
'--with-uvcvideo')
	export BOL_INIT_UVCVIDEO=$TRUE
	;;
-t=* | --time=*)
	VAR_TIME="${i#*=}"
	VAR_TIME=$((VAR_TIME))
	;;
-g=* | --give-up=*)
	VAR_GIVE_UP="${i#*=}"
	VAR_GIVE_UP=$((VAR_GIVE_UP))
	;;
-s=* | --server=*)
	MYSQL_SERVER="${i#*=}"
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
	do_HELP
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
fi

CheckLocalService
BOL_LOCAL_SERVICE_RUNNING=$?

if [ $BOL_LOCAL_SERVICE_RUNNING -eq $TRUE ]; then
        BOL_START=$FALSE
	if [ $BOL_VERBOSE -eq $TRUE ]; then
	        echo "Local Service is Currently Running!"
	fi
        RETVAL=0
fi

if [ $BOL_START -eq $TRUE ]; then
        log_daemon_msg "Starting $RUNCMD"
	do_START
fi

## Done!

