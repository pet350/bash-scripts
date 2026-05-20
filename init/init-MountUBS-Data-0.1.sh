#! /bin/bash
### BEGIN INIT INFO
# Provides:          Mount-UbuntuServer-Disks
# Required-Start:    $local_fs $syslog
# Required-Stop:
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Prepare UbuntuServer Data Disks
# Description:       Prepare UbuntuServer Data Disks
### END INIT INFO
# chkconfig: 2345 12 05

### By: Peter Talbott
### Origonal: 2019-04-01
### Revised:  2019-12-02,03,08

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

if [ $(id -u) -gt 0 ]; then
    echo -e "$RUN_CMD\tVersion $VERSION\nMust be ran as root"
    exit $FAILURE
fi

if [ $# -eq 0 ]; then
    echo -e "$RUN_CMD\tVersion $VERSION\nUsage: $RUN_CMD { start | stop | restart } --help"
    exit $FAILURE
fi

# Define Global Arrays
declare -ag DEVICE_ARRAY=("/dev/sda" "/dev/sdb" "/dev/sdc" "/dev/sdd" "/dev/sde");
declare -ag TARGET_ARRAY=("/opt/prod" "/opt/usr" "/opt/video" "/opt/zm" "/opt/data.bak");

# Define Directory Prefix String Variables
export BIN_PREFIX="/bin"
export SBIN_PREFIX="/usr/sbin"
export CFG_PREFIX="/etc/xen"

# Define Application Binarys String Values
export XL_BIN="$SBIN_PREFIX/xl"
export CHOWN_BIN="$BIN_PREFIX/chown"
export SLEEP_BIN="$BIN_PREFIX/sleep"
export MOUNT_BIN="$BIN_PREFIX/mount"
export UMOUNT_BIN="$BIN_PREFIX/umount"
export NBD_BIN="/usr/bin/qemu-nbd"

# Define Other String Values
export VERBOSE=""
export OWNER="root"
export GROUP="Domain Admins"
export MOUNT_OPTION=""

# Define Global Boolean Variables
declare -ig BOL_START=$FALSE
declare -ig BOL_STOP=$FALSE
declare -ig BOL_VERBOSE=$FALSE
declare -ig BOL_HELP=$FALSE
declare -ig BOL_SLEEP=$TRUE

# Define Integer Variables
declare -ig VAR_UNKNOWN=$FALSE
declare -ig SLEEP_TIME=1

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

# Function That Performs Mounting Opperations
function do_MOUNT()
{
    declare -i RETVAL=$FAILURE

    if [ ! -d $TARGET ]; then mkdir -p $TARGET; fi
    if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Executing Command:\t$MOUNT_BIN $MOUNT_OPTION $DEVICE $TARGET $VERBOSE"; fi
    $MOUNT_BIN $MOUNT_OPTION $DEVICE $TARGET $VERBOSE
    export RETVAL=$?
    if [ $BOL_VERBOSE -eq $TRUE ]; then LOG_RESULTS; fi
    if [ $RETVAL -eq $SUCCESS ]; then $CHOWN_BIN "$OWNER":"$GROUP" "$TARGET" $VERBOSE; fi
    return $RETVAL
};

# START Function
function do_START()
{
    declare -i RETVAL=$FAILURE
    declare -i INDEX=-1

    for DATA in ${DEVICE_ARRAY[@]}; do
      ((INDEX++))
      export DEVICE="$DATA"
      export TARGET="${TARGET_ARRAY[(($INDEX))]}"
      do_MOUNT
      RETVAL=$?
      if [ $BOL_SLEEP -eq $TRUE ]; then $SLEEP_BIN $SLEEP_TIME; fi
    done
    return $RETVAL
};

# STOP Function
function do_STOP()
{
    declare -i RETVAL=$FAILURE

    for TARGET in ${TARGET_ARRAY[@]}; do
      if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Executing Command:\t$UMOUNT_BIN $TARGET"; fi
      $UMOUNT_BIN $TARGET
      export RETVAL=$?
      if [ $BOL_VERBOSE -eq $TRUE ]; then LOG_RESULTS; fi
    done
    return $RETVAL
};

# Display Help Function
function do_HELP()
{
	printf "HELP! %-7s\tversion: %-4s\n" "$RUN_CMD" "$VERSION"
	printf "%-15s\t\t%-25s\n" "-h or --help" "Disply This Help Message"
        printf "%-15s\t\t%-25s\n" "start" "Mount UbuntuServer Data Disks"
        printf "%-15s\t\t%-25s\n" "stop" "Unmount UbuntuServer Data Disks"
        printf "%-15s\t\t%-25s\n" "-v or --verbose" "Be Verbose"
};

# Loop Through and Read All Command Line Options
for i in "$@"
do
case $i in
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
        RETVAL=$SUCCESS
fi

if [ $VAR_UNKNOWN -gt 0 ]; then
	BOL_START=$FALSE
	BOL_STOP=$FALSE
	RETVAL=$VAR_UNKNOWN
fi

if [ $BOL_STOP -eq $TRUE ]; then
        log_daemon_msg "Stopping $RUNCMD Version $VERSION"
	do_STOP
	export RETVAL=$?
	LOG_RESULTS
fi

if [ $BOL_START -eq $TRUE ]; then
        log_daemon_msg "Starting $RUNCMD Version $VERSION"
	do_START
	export RETVAL=$?
	LOG_RESULTS
fi

## DONE!
exit $RETVAL
