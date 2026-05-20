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

# Define Global Boolean Variables
declare -ig BOL_VERBOSE=$FALSE
declare -ig BOL_HELP=$FALSE
declare -ig BOL_TEMP=$FALSE
declare -ig BOL_DEBUG=$FALSE
declare -ig BOL_WAIT=$TRUE
declare -ig BOL_LOG_RESULTS=$TRUE

# Define Global SYSCTL Boolean Variables
declare -ig BOL_START=$FALSE
declare -ig BOL_STOP=$FALSE
declare -ig BOL_STATUS=$FALSE
declare -ig BOL_ENABLE=$FALSE
declare -ig BOL_DISABLE=$FALSE

# Define Directoy Prefix String Variables
export BIN_PREFIX="/bin"
export SBIN_PREFIX="/sbin"
export USER_PREFIX="/usr"
export NFS_PREFIX="/nfs"

# Define Binary Variables
export GREP_BIN="$BIN_PREFIX/grep"
export NMAP_BIN="$USER_PREFIX$BIN_PREFIX/nmap"
export SLEEP_BIN="$BIN_PREFIX/sleep"
export IPCALC_BIN="$BIN_PREFIX/ipcalc"
export IFCONFIG_BIN="$SBIN_PREFIX/ifconfig"
export MOUNT_BIN="$SBIN_PREFIX/mount.nfs"
export MNT_BIN="$BIN_PREFIX/mount"
export UMOUNT_BIN="$BIN_PREFIX/umount"

# Define Option Variables
export SYSCTL_OPT=""
export MOUNT_OPT="-s"
export SUBNET=""

# Define Global Integer Variables
declare -ig EXIT_VAL=$SUCCESS
declare -ig RETVAL=$SUCCESS
declare -ig INDEX_VAL=-1
declare -ig VAR_WAIT=1

function LOG_RESULTS()
{
  if [ $RETVAL -eq $SUCCESS ]; then
    log_success_msg "Success!"
  else
    log_failure_msg "Failure!"
  fi
  return $RETVAL
};

if [ $(id -u) -gt 0 ]; then
    echo -e "$RUN_CMD\tVersion: $VERSION\nMust be ran as root"
    exit $EXIT_VAL
fi

if [ $# -eq 0 ]; then
    echo -e "$RUN_CMD\tVersion: $VERSION\nUsage: $RUN_CMD [options] { start | stop | restart  } --help"
    exit $EXIT_VAL
fi

function DO_MOUNT()
{
  declare -i RETVAL=$SUCCESS

  if [ ! -d $NFS_PREFIX ]; then mkdir -p $NFS_PREFIX; fi
  for TEMP_FQDN in ${SERVER_FQDN_ARRAY[@]}; do
    MOUNT_POINT="$NFS_PREFIX/$TEMP_FQDN"
    if [ ! -d $MOUNT_POINT ]; then mkdir -p $MOUNT_POINT; fi
    if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Executing: $MOUNT_BIN $MOUNT_OPT $VERBOSE $TEMP_FQDN:/ $MOUNT_POINT"; fi
    $MOUNT_BIN $MOUNT_OPT $VERBOSE "$TEMP_FQDN:/" "$MOUNT_POINT"
    export RETVAL=$?
    if [ $BOL_VERBOSE -eq $TRUE ]; then LOG_RESULTS; fi
  done

  return $RETVAL
};

function SHOW_NFS_SERVERS()
{
  declare -i INDEX=-1
  echo -e "Getting Server Information for Subnet:\t$SUBNET"
  for TEMP_FQDN in ${SERVER_FQDN_ARRAY[@]}; do
    ((INDEX++))
    TEMP_IP="${SERVER_IP_ARRAY[$((INDEX))]}"
    printf "FQDN: %-25s\t\tIP: %-18s\n" "$TEMP_FQDN" "$TEMP_IP"
  done
  return $SUCCESS
};

function STORE_NFS_SERVERS()
{
  # Define Integer Variables
  declare -i NFS_PORT=2049
  declare -i INDEX=-1
  declare -i COUNT=0

  # Define Global Arrays
  declare -ag SERVER_FQDN_ARRAY=();
  declare -ag SERVER_IP_ARRAY=();

  # Define String Values
  export GREP_OPT="Nmap scan report for "
  export NMAP_OPT="$SUBNET --open -p $NFS_PORT"

  while IFS= read LINE; do
    ((INDEX++))
    COUNT=0
    for DATA in $LINE; do
      ((COUNT++))
      if [ $COUNT -eq 5 ]; then SERVER_FQDN_ARRAY[$((INDEX))]="$DATA"; fi
      if [ $COUNT -eq 6 ]; then SERVER_IP_ARRAY[$((INDEX))]="$DATA"; fi
    done
  done < <( $NMAP_BIN $NMAP_OPT | $GREP_BIN "$GREP_OPT" )

  return $INDEX
};

function GET_SUBNET()
{
  declare -i INDEX=-1

  declare -i BOL_NET=$FALSE
  declare -i BOL_PRE=$FALSE

  declare -ag IP_ADDRESS=();
  declare -ag SUBNET_MASK=();

  # Define String Values
  export LOOPBACK="127.0.0.1"
  export INET6="inet6"

  if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Getting Network Information"; fi
  while IFS= read LINE; do
    for DATA in $LINE; do
      case $DATA in
        addr:*)
	  ((INDEX++))
	  TEMP="${DATA#*:}"
	  if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "INDEX $INDEX IP Address:\t\t$TEMP"; fi
          IP_ADDRESS[$((INDEX))]="$TEMP"
	  ;;
        Mask:*)
          TEMP="${DATA#*:}"
          if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "INDEX $INDEX Net Mask:\t\t$TEMP"; fi
          SUBNET_MASK[$((INDEX))]="$TEMP"
          ;;
	*)
	  if [ $BOL_DEBUG -eq $TRUE ]; then echo -e "[Debug] [Case] [Data]:\t\t$DATA";fi
	  ;;
      esac
    done
  done < <( $IFCONFIG_BIN | $GREP_BIN -v "$LOOPBACK" | $GREP_BIN -v "$INET6" )

  INDEX=-1
  for TEMP_ADDRESS in ${IP_ADDRESS[@]}; do
    ((INDEX++))
    BOL_NET=$FALSE
    BOL_PRE=$FALSE
    TEMP_MASK="${SUBNET_MASK[$((INDEX))]}"
    for DATA in $($IPCALC_BIN $TEMP_ADDRESS $TEMP_MASK); do
      case $DATA in
	NETWORK=*)
	  BOL_NET=$TRUE
	  TEMP_NET="${DATA#*=}"
	  ;;
	PREFIX=*)
	  BOL_PRE=$TRUE
	  TEMP_PRE="${DATA#*=}"
	  ;;
	*)
          if [ $BOL_DEBUG -eq $TRUE ]; then echo -e "[Debug] [Case] [Data]:\t\t$DATA"; fi
          ;;
      esac
      TEMP_SUBNET="$TEMP_NET/$TEMP_PRE"
      if [ $BOL_NET -eq $TRUE ]; then
	if [ $BOL_PRE -eq $TRUE ]; then
          if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "INDEX $INDEX Network:\t\t$TEMP_SUBNET\n"; fi
          SUBNET_ARRAY[$((INDEX))]="$TEMP_SUBNET"
	fi
      fi
    done
  done
  return $INDEX
};

function UNMOUNT()
{
  declare -i RETVAL=$SUCCESS
  declare -i COUNT=-1
  declare -i INDEX=-1

  declare -ag NFS_MOUNT=();

  export UMOUNT_OPT="-f"

  if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Unmounting Currently Mounted NFS Shares"; fi
  while IFS= read LINE; do
    COUNT=-1
    ((INDEX++))
    for DATA in $LINE; do
      ((COUNT++))
      if [ $COUNT -eq 2 ]; then NFS_MOUNT[$((INDEX))]="$DATA"; fi
    done
  done < <( $MNT_BIN | $GREP_BIN "nfs" )

  for TEMP_MOUNT in ${NFS_MOUNT[@]}; do
    if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Executing: $UMOUNT_BIN $UMOUNT_OPT $TEMP_MOUNT"; fi
    $UMOUNT_BIN $UMOUNT_OPT "$TEMP_MOUNT"
    export RETVAL=$?
    if [ $BOL_VERBOSE -eq $TRUE ]; then LOG_RESULTS; fi
  done
  return $RETVAL
};

for i in "$@"
do
case $i in
'-h' | '--help')
	export BOL_HELP=$TRUE
        export VERBOSE=""
        export BOL_DEBUG=$FALSE
        export BOL_VERBOSE=$FALSE
        export BOL_LOG_RESULTS=$FALSE
	;;
'-d' | '--debug')
        export VERBOSE="--verbose"
	export BOL_DEBUG=$TRUE
        export BOL_VERBOSE=$TRUE
        export BOL_LOG_RESULTS=$TRUE
	;;
'-v' | '--verbose')
	export VERBOSE="-v"
        export BOL_VERBOSE=$TRUE
	export BOL_LOG_RESULTS=$TRUE
        ;;
'-q' | '--quiet')
	export VERBOSE=""
	export BOL_VERBOSE=$FALSE
	export BOL_LOG_RESULTS=$FALSE
	;;
-w=* | --wait=*)
        X="${i#*=}"
        VAR_WAIT=$((X))
	export BOL_WAIT=$TRUE
        ;;
'--no-wait')
	export BOL_WAIT=$FALSE
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
	export BOL_START=$TRUE
	export BOL_STOP=$TRUE
	;;
esac
done

if [ $BOL_HELP -eq $TRUE ]; then do_HELP; fi

if [ $BOL_STOP -eq $TRUE ]; then
  UNMOUNT
  for TEMP_MOUNT in $(ls -1 $NFS_PREFIX); do
    rmdir $NFS_PREFIX/$TEMP_MOUNT
  done
fi

if [ $BOL_START -eq $TRUE ]; then
  GET_SUBNET
  for TEMP_SUBNET in ${SUBNET_ARRAY[@]}; do
    export SUBNET="$TEMP_SUBNET"
    STORE_NFS_SERVERS
    if [ $BOL_VERBOSE -eq $TRUE ]; then SHOW_NFS_SERVERS; fi
    DO_MOUNT
    RETVAL=$?
  done
fi

if [ $BOL_VERBOSE -eq $TRUE ]; then LOG_RESULTS; fi
exit $RETVAL
