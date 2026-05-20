#! /bin/bash
### By: Peter Talbott 2019-06-01

# Source function library.
source /lib/lsb/init-functions

# Source function library for storing XEN info
source /usr/local/src/xen-scripts.sh

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
    echo -e "$RUN_CMD\tVersion: $VERSION\nUsage: $RUN_CMD { start | stop | restart } --help"
    exit 1
fi

# Define Directoy Prefix String Variables
export BIN_PREFIX="/bin"
export SBIN_PREFIX="/sbin"
export USER_PREFIX="/usr"
export CFG_PREFIX="/etc/xen"
export CERT_PREFIX="/etc/ssl/xen"
export WEB_PREFIX="/usr/share/novnc/"

# Define Application Options
export VERBOSE=""
export CERT_FILE="$CERT_PREFIX/novnc.pem"
export SOURCE_ADDRESS="127.16.184.2"
export TARGET_ADDRESS="172.16.184.2"
export DAEMON_OPTION="--daemon"
export SSL_OPTION="--ssl-only"

# Define Application Binaries
export NMAP_BIN="$USER_PREFIX$BIN_PREFIX/nmap"
export XL_BIN="$USER_PREFIX$SBIN_PREFIX/xl"
export WC_BIN="$USER_PREFIX$BIN_PREFIX/wc"
export WS_BIN="$USER_PREFIX$BIN_PREFIX/websockify"
export PS_BIN="$BIN_PREFIX/ps"
export GREP_BIN="$BIN_PREFIX/grep"
export SLEEP_BIN="$BIN_PREFIX/sleep"
export KILL_BIN="$BIN_PREFIX/kill"

# Define Boolean Variables
declare -ig BOL_START=$FALSE
declare -ig BOL_STOP=$FALSE
declare -ig BOL_VERBOSE=$FALSE
declare -ig BOL_HELP=$FALSE
declare -ig BOL_WAIT=$TRUE

# Define Integer Variables
declare -ig VAR_UNKNOWN=$FALSE
declare -ig VAR_WAIT=1
declare -ig VNC_INIT_PORT=5900
declare -ig WEB_INIT_PORT=15900

# Define Array Data
declare -ag PID_ARRAY=();

# Define RETVAL as a NON-GLOBAL Integer
declare -i RETVAL=$FAILURE

# Function To Create a WebSocket For All Running Xen Domains
function do_WEBSOCKIFY()
{
  declare -i INDEX=-1
  declare -i RETVAL=$FAILURE
  declare -i VNC_PORT
  while [ $INDEX -lt $DOMAIN_COUNT ]; do
    ((INDEX++))
    VNC_PORT=$(($VNC_INIT_PORT+$INDEX))
    WEB_PORT=$(($WEB_INIT_PORT+$INDEX))
    if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Testing VNC Port:\t$VNC_PORT"; fi
    if [ $($NMAP_BIN $SOURCE_ADDRESS --open -p $VNC_PORT | $WC_BIN -l) -gt 3 ]; then
      if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "$WS_BIN $DAEMON_OPTION $SSL_OPTION --web=$WEB_PREFIX --cert=$CERT_FILE $TARGET_ADDRESS:$WEB_PORT $SOURCE_ADDRESS:$VNC_PORT"; fi
      $WS_BIN $DAEMON_OPTION $SSL_OPTION --web=$WEB_PREFIX --cert=$CERT_FILE $TARGET_ADDRESS:$WEB_PORT $SOURCE_ADDRESS:$VNC_PORT
      RETVAL=$?
    fi
    if [ $BOL_WAIT -eq $TRUE ]; then $SLEEP_BIN $VAR_WAIT; fi
  done
  return $RETVAL
};

function do_START()
{
  declare -ig DOMAIN_COUNT=$($XL_BIN list | $WC_BIN -l)-2
  declare -i RETVAL=$FAILURE

  if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Domain Count Found:\t$DOMAIN_COUNT"; fi
  if [ $DOMAIN_COUNT -gt 0 ]; then do_WEBSOCKIFY; fi
  RETVAL=$?
  return $RETVAL
};

# Function To Store All WebSockify PIDs
function Get_PIDs()
{
  declare -i INDEX=-1
  declare -i PID_INDEX=-1
  declare -i BOL_STORE_PID=$TRUE
  declare -a TEMP_ARRAY=();

  while IFS= read -r line; do
    INDEX=-1
    BOL_STORE_PID=$TRUE
    TEMP_ARRAY=();
    for TEMP_DATA in $line; do
      ((INDEX++))
      if [ $TEMP_DATA == $GREP_BIN ]; then BOL_STORE_PID=$FALSE; fi
      TEMP_ARRAY[$((INDEX))]="$TEMP_DATA"
    done
    if [ $BOL_STORE_PID -eq $TRUE ]; then
      ((PID_INDEX++))
      PID_ARRAY[$((PID_INDEX))]=${TEMP_ARRAY[0]}
    fi
  done < <( $PS_BIN -ax | $GREP_BIN $WS_BIN )
  return $PID_INDEX
};

function do_STOP()
{
  declare -i RETVAL=$FAILURE
  Get_PIDs
  for TEMP_DATA in ${PID_ARRAY[@]}; do
    if [ $BOL_VERBOSE -eq $TRUE ]; then printf "Stopping PID: $TEMP_DATA\t"; fi
    $KILL_BIN $TEMP_DATA
    RETVAL=$?
    if [ $BOL_VERBOSE -eq $TRUE ]; then
      if [ $RETVAL -eq $SUCCESS ]; then echo -e "Success"; fi
      if [ $RETVAL -ne $SUCCESS ]; then echo -e "Failure"; fi
    fi
    if [ $BOL_WAIT -eq $TRUE ]; then $SLEEP_BIN $VAR_WAIT; fi
  done
  return $RETVAL
};

function do_HELP()
{
  printf "HELP! %-7s\tversion: %-4s\n" "$RUN_CMD" "$VERSION"
  printf "%-15s\t\t%-25s\n" "-h or --help" "Disply This Help Message"
  printf "%-15s\t\t%-25s\n" "start" "Setup Web Access for Xen Domain's VNC Console"
  printf "%-15s\t\t%-25s\n" "stop" "Shutdown Web Access for Xen Domain's VNC Console"
  printf "%-15s\t\t%-25s\n" "-v or --verbose" "Be Verbose"
  return $SUCCESS
};

for i in "$@"
do
case $i in
'--no-wait')
	export BOL_WAIT=$FALSE
	;;
'-h' | '--help')
	export BOL_HELP=$TRUE
	export BOL_START=$FALSE
	export BOL_STOP=$FALSE
	;;
'start')
        export BOL_START=$TRUE
	export BOL_STOP=$FALSE
        ;;
'stop')
	export BOL_START=$FALSE
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
-w=* | --wait=*)
        X="${i#*=}"
        VAR_WAIT=$((X))
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
        RETVAL=$FAILURE
fi

if [ $VAR_UNKNOWN -gt 0 ]; then
	BOL_START=$FALSE
	BOL_STOP=$FALSE
	RETVAL=$_VAR_UNKNOWN
fi

StoreXenArray
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

if [ $RETVAL -eq $SUCCESS ]; then
        log_success_msg "OK!"
else
        log_failure_msg "FAIL!"
fi

## DONE!
exit $RETVAL
