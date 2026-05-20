#!/bin/bash
# Shell Script By: Peter Talbott

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

# Define Command being Executed and its Version
export RUN_CMD="$(basename $0)"
export VERSION="0.1"

# Define Executable variables not defined in the include files
export NBD_BIN="/usr/bin/qemu-nbd"
export RPD_BIN="/sbin/rapiddisk"

# Define global string variables
export IMAGE="/opt/image/usr.bin.qcow2"
export TARGET_DIR="/tmp/bin"
export MAPPER="/dev/mapper"
export FINAL_TARGET="/usr/bin"
export LOG_FILE="/var/log/usr-bin.log"

# Define global integer variables
declare -ig CACHE_SIZE=64
declare -ig STOP_VAL=$SUCCESS
declare -ig START_VAL=$SUCCESS

# Define global boolean variables, if they do not already exist
if [ ${#BOL_KEEP_GOING} -eq 0 ]; then	declare -ig BOL_KEEP_GOING=$FALSE;	fi
if [ ${#BOL_QUIET}	-eq 0 ]; then 	declare -ig BOL_QUIET=$FALSE;		fi
if [ ${#BOL_WAIT}	-eq 0 ]; then	declare -ig BOL_WAIT=$TRUE;		fi

# Make sure that all needed binaries have been located by comdef.sh include file
if [ ${#FDISK_BIN}	-eq 0 ]; then echo -e "Error! Binary fdisk not found!"		| tee -a $LOG_FILE;		exit $FAILURE;	fi
if [ ${#LSMOD_BIN}	-eq 0 ]; then echo -e "Error! Binary lsmod not found!"		| tee -a $LOG_FILE;		exit $FAILURE;	fi
if [ ${#GREP_BIN}	-eq 0 ]; then echo -e "Error! Binary grep not found!"		| tee -a $LOG_FILE;		exit $FAILURE;	fi
if [ ${#MODPROBE_BIN}	-eq 0 ]; then echo -e "Error! Binary modprobe not found!"	| tee -a $LOG_FILE;		exit $FAILURE;	fi
if [ ${#MOUNT_BIN}	-eq 0 ]; then echo -e "Error! Binary mount not found!"		| tee -a $LOG_FILE;		exit $FAILURE;	fi
if [ ${#MKDIR_BIN}	-eq 0 ]; then echo -e "Errot! Binary mkdir not found!"		| tee -a $LOG_FILE;		exit $FAILURE;	fi

function LOAD_MODULES()
{
  declare -i FUNCTION_RETURN=$SUCCESS
  if [ $BOL_DEBUG -eq $TRUE ]; then SHOW_DATE_TIME | tee -a $LOG_FILE; echo -e $CLB"[Debug]\t "$CC"Checking that required kernel modules are loaded."$CN | tee -a $LOG_FILE; fi
  for MODULE in nbd rapiddisk rapiddisk-cache; do
    unset COMMAND
    if [ $BOL_DEBUG -eq $TRUE ]; then
      SHOW_DATE_TIME| tee -a $LOG_FILE;
      printf "%b" $CLB | tee -a $LOG_FILE; printf "[Debug]\t " | tee -a $LOG_FILE
      printf "%b" $CC |  tee -a $LOG_FILE; printf "Checking: " | tee -a $LOG_FILE
      printf "%b" $CY |  tee -a $LOG_FILE; printf "%s " $MODULE | tee -a $LOG_FILE
      printf "%b" $CN |  tee -a $LOG_FILE
    fi
    TEST=$($LSMOD_BIN | $GREP_BIN $MODULE)
    if [ ${#TEST} -eq 0 ]; then
      if [ $BOL_DEBUG -eq $TRUE ]; then
        printf "%b" $CLR | tee -a $LOG_FILE; printf "Not Loaded...\n" | tee -a $LOG_FILE
        SHOW_DATE_TIME   | tee -a $LOG_FILE
        printf "%b" $CLB | tee -a $LOG_FILE; printf "[Debug]\t " | 	tee -a $LOG_FILE
        printf "%b" $CC  | tee -a $LOG_FILE; printf "Loading module: "| tee -a $LOG_FILE
        printf "%b" $CY  | tee -a $LOG_FILE; printf "%s " $MODULE | tee -a $LOG_FILE
        printf "%b" $CN  | tee -a $LOG_FILE
      fi
      $MODPROBE_BIN $MODULE
      FUNCTION_RETURN=$?
      if [ $BOL_DEBUG -eq $TRUE ]; then
        export RETVAL="$FUNCTION_RETURN"
        LOG_RESULTS | tee -a $LOG_FILE
        printf "%b\n" $CN | tee -a $LOG_FILE
      fi
    else
      if [ $BOL_DEBUG -eq $TRUE ]; then
        printf "%b" $CLG; printf "Already loaded!\n" | tee -a $LOG_FILE
      fi
    fi
  done
  return $FUNCTION_RETURN
};

function FIND_AVAILABLE_NBD()
{
  FOUND=$FALSE
  RETVAL=$FAILURE
  INDEX=-1
  while [ $FOUND -ne $TRUE ]; do
    ((INDEX++))
    $FDISK_BIN --list /dev/nbd$((INDEX)) >/dev/null 2>/dev/null
    if [ $? -ne $SUCCESS ]; then
      # Found available NBD Device!
      FOUND=$TRUE
      echo "nbd$((INDEX))"
      RETVAL=$SUCCESS
    fi
  done
  return $RETVAL
};

function CMD_EXEC()
{
  declare FUNCTION_RETURN=$FAILURE
  if [ $BOL_VERBOSE -eq $TRUE ]; then SHOW_DATE_TIME | tee -a $LOG_FILE; echo -e $CLB"[Info]\t "$CLG"Executing: "$CC"$COMMAND $OPTIONS"$CN | tee -a $LOG_FILE; fi
  $COMMAND $OPTIONS >/dev/null 2>/dev/null
  FUNCTION_RETURN=$?
  if [ $BOL_WAIT -eq $TRUE ]; then $SLEEP_BIN $VAR_WAIT; fi
  if [ $BOL_VERBOSE -eq $TRUE ]; then
    SHOW_DATE_TIME | tee -a $LOG_FILE
    export RETVAL=$FUNCTION_RETURN
    printf "%b" $CLB; printf "[Results] " | tee -a $LOG_FILE
    LOG_RESULTS | tee -a $LOG_FILE
    printf "%b" $CN | tee -a $LOG_FILE
  fi
  return $FUNCTION_RETURN
};

function CMD_FAILED()
{
  if [ $BOL_QUIET -eq $FALSE ]; then
    SHOW_DATE_TIME |   tee -a $LOG_FILE
    printf "%b" $CR |  tee -a $LOG_FILE; printf "[Error]\t " | 			tee -a $LOG_FILE
    printf "%b" $CLP | tee -a $LOG_FILE; printf "Command:   " | 		tee -a $LOG_FILE
    printf "%b" $CC |  tee -a $LOG_FILE; printf "%s %s " $COMMAND $OPTIONS | 	tee -a $LOG_FILE
    printf "%b" $CR |  tee -a $LOG_FILE; printf "failed! With results: " | 	tee -a $LOG_FILE
    printf "%b" $CY |  tee -a $LOG_FILE; printf "%s" $RETVAL | 			tee -a $LOG_FILE
    printf "%b" $CN |  tee -a $LOG_FILE; printf "\n" | 				tee -a $LOG_FILE
  fi
  if [ $BOL_KEEP_GOING -eq $FALSE ]; then exit $RETVAL; fi
  if [ $BOL_QUIET -eq $FALSE ]; then printf "\n" | tee -a $LOG_FILE; fi
  return $RETVAL
};

function DO_START()
{
  # Define function string variables
  export NBD_NAME=$(FIND_AVAILABLE_NBD)
  export NBD_DEV="/dev/$NBD_NAME"
  export MOUNT_SRC="$MAPPER/rc-wa_$NBD_NAME"

  # Define function arrays
  declare -a CMD_ARRAY=( "$NBD_BIN" "$RPD_BIN" "$RPD_BIN" "$MKDIR_BIN" "$MOUNT_BIN" "$MOUNT_BIN");
  declare -a OPT_ARRAY=( "--connect $NBD_DEV --format qcow2 $IMAGE" "--attach $CACHE_SIZE" "--cache-map rd0 $NBD_DEV wa" \
    "-p $TARGET_DIR" "$MOUNT_SRC $TARGET_DIR" "-o bind $TARGET_DIR $FINAL_TARGET" );

  # Define function integer variables
  declare -i CMD_INDEX=-1

  if [ ${#NBD_NAME} -eq 0 ]; then
    echo "No available NBD Device Found!" | tee -a $LOG_FILE
    exit $FAILURE
  fi

  for COMMAND in ${CMD_ARRAY[@]}; do
    ((CMD_INDEX++))
    export OPTIONS="${OPT_ARRAY[$((CMD_INDEX))]}"
    CMD_EXEC
    export RETVAL=$?
    if [ $RETVAL -ne $SUCCESS ]; then
      CMD_FAILED
    else
      if [ $BOL_VERBOSE -eq $TRUE ]; then printf "\n" | tee -a $LOG_FILE; fi
    fi
  done

  return $RETVAL
};

function DO_STOP()
{
  # Define function string variables
  export NBD_NAME=$(FIND_AVAILABLE_NBD)
  export NBD_DEV="/dev/$NBD_NAME"
  export MOUNT_DEV="rc-wa_$NBD_NAME"
  export MOUNT_SRC="$MAPPER/$MOUNT_DEV"

  # Define function arrays
  declare -a CMD_ARRAY=( "$UMOUNT_BIN" "$UMOUNT_BIN" "$RPD_BIN" );
  declare -a OPT_ARRAY=( "$FINAL_TARGET" "$TARGET_DIR" "--cache-unmap $MOUNT_DEV" );

  # Define function integer variables
  declare -i CMD_INDEX=-1

  for COMMAND in ${CMD_ARRAY[@]}; do
    ((CMD_INDEX++))
    export OPTIONS="${OPT_ARRAY[$((CMD_INDEX))]}"
    CMD_EXEC
    export RETVAL=$?
    if [ $RETVAL -ne $SUCCESS ]; then
      CMD_FAILED
    else
      if [ $BOL_VERBOSE -eq $TRUE ]; then printf "\n" | tee -a $LOG_FILE; fi
    fi
  done

  return $RETVAL
};

for i in "$@"
do
case $i in
      'start')
        export BOL_START=$TRUE;		export BOL_STOP=$FALSE
        ;;
      'stop')
	export BOL_START=$FALSE;	export BOL_STOP=$TRUE
	;;
      'restart')
	export BOL_STOP=$TRUE;		export BOL_START=$TRUE
	;;
'-h' | '--help')
	export BOL_HELP=$TRUE;		export VERBOSE="";		export BOL_DEBUG=$FALSE;	export BOL_VERBOSE=$FALSE;	export BOL_LOG_RESULTS=$FALSE
	;;
'-d' | '--debug')
        export VERBOSE="--verbose";	export BOL_DEBUG=$TRUE;		export BOL_VERBOSE=$TRUE;	export BOL_LOG_RESULTS=$TRUE
	;;
'-v' | '--verbose')
	export VERBOSE="--verbose";	export BOL_VERBOSE=$TRUE;	export BOL_LOG_RESULTS=$TRUE
        ;;
'-q' | '--quiet')
	export VERBOSE="";		export BOL_VERBOSE=$FALSE;	export BOL_LOG_RESULTS=$FALSE;	export BOL_QUIET=$TRUE
	;;
'-t' | '--test')
	export BOL_TEST=$TRUE;		export NBD_BIN="$TRUE_BIN";	export RPD_BIN="$TRUE_BIN";	export MOUNT_BIN="$TRUE_BIN";	export UMOUNT_BIN="$TRUE_BIN";	export MKDIR_BIN="$TRUE_BIN"
	;;
'-t' | '--test-fail')
        export BOL_TEST=$TRUE;		export NBD_BIN="$FALSE_BIN";	export RPD_BIN="$FALSE_BIN";	export MOUNT_BIN="$FALSE_BIN";	export UMOUNT_BIN="$FALSE_BIN";	export MKDIR_BIN="$FALSE_BIN"
        ;;
'--keep-going')
	export BOL_KEEP_GOING=$TRUE
	;;
'--version')
	SHOW_DATE_TIME; echo -e "$RUN_CMD\tVersion: $VERSION\nBy:\t\tPeter Talbott"
	exit $SUCCESS
	;;
'--bw')
	export BOL_COLOR=$FALSE
	;;
'--color')
	export BOL_COLOR=$TRUE
	;;
'--force-color')
	export BOL_FORCE_COLOR=$TRUE
        export BOL_COLOR=$TRUE
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
	ADDITIONAL_ARRAY_LEN=${#ADDITIONAL_ARRAY[@]}
	ADDITIONAL_ARRAY[$((ADDITIONAL_ARRAY_LEN))]="$i"
	SHOW_DATE_TIME; echo -e "$RUN_CMD\tVersion: $VERSION\nDiscarded: $i\n"
	;;
esac
done

if [ $BOL_COLOR -eq $TRUE ]; then INIT_COLOR_SHORTHAND; fi
if [ $BOL_START -eq $FALSE ] && [ $BOL_STOP -eq $FALSE ]; then BOL_HELP=$TRUE; fi
if [ $BOL_HELP -eq $TRUE ]; then DO_HELP; fi

REQUIRE_ROOT_USER
LOAD_MODULES

if [ $BOL_STOP -eq $TRUE ]; then DO_STOP; STOP_VAL=$?; fi
if [ $BOL_START -eq $TRUE ]; then DO_START; START_VAL=$?; fi

export RETVAL=$((STOP_VAL+START_VAL))
exit $RETVAL
