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

export RUN_CMD="$(basename $0)"
export VERSION="0.1"
export AUTHOR="Peter Talbott"
export MODIFIED="2023-04-06"

# Unsetting variables that maybe defined in Environment
unset IDNUM

# Define a few more binary variables
for DATA in curl crelay inotifywait iwatch egrep chown sleep cat wc find true; do
  export TEMP="$DATA"
  TEMP_BIN=$(GET_BIN)
  if [ $? -eq $SUCCESS ]; then
    export "${DATA^^}_BIN"="$TEMP_BIN"
  else
    echo -e "Missing required binary: $DATA"
    exit $FAILURE
  fi
  unset TEMP_BIN
  unset TEMP
done

function SHOW_RESULTS()
{
  if [ $RETVAL -eq $SUCCESS ]; then
    echo -e "Success. Return Value: $RETVAL"
  else
    echo -e "Failure. Return Value: $RETVAL"
  fi
};

function SHOW_DATE_TIME()
{
  printf "%b[ %10s @ %5s ] %b" $COLOR_LT_GREEN $(date +%F) $(date +%R) $COLOR_NORMAL
  return $SUCCESS
};

function SHOW_HEADER()
{
  echo -e "$RUN_CMD\t\tVersion: $VERSION\nBy: $AUTHOR\tDated: $MODIFIED"
  return $SUCCESS
};

function DEBUG_START_MESSAGE()
{
  declare -i RETVAL=$FAILURE
  if [ ${#1} -gt 0 ]; then
    SHOW_DATE_TIME
    CLB_TEXT; printf "[Debug] "
    CY_TEXT;  printf "Starting: "
    CC_TEXT;  printf "%s" "$1"
    CN_TEXT;  printf "\n"
    RETVAL=$SUCCESS
  else
    RETVAL=$FAILURE
  fi
  return $RETVAL
};

function DEBUG_EXEC_MESSAGE()
{
  declare -i RETVAL=$FAILURE
  if [ ${#1} -gt 0 ]; then
    SHOW_DATE_TIME
    CLB_TEXT; printf "[Debug] "
    CY_TEXT;  printf "Executing: "
    CC_TEXT;  printf "%s" "$1"
    CN_TEXT;  printf "\n"
    RETVAL=$SUCCESS
  else
    RETVAL=$FAILURE
  fi
  return $RETVAL
};

function DEBUG_FOUND_MESSAGE()
{
  declare -i RETVAL=$FAILURE
  if [ ${#1} -gt 0 ]; then
    SHOW_DATE_TIME
    CLB_TEXT; printf "[Debug] "
    CY_TEXT;  printf "Found: "
    CC_TEXT;  printf "%s" "$1"
    CN_TEXT;  printf "\n"
    RETVAL=$SUCCESS
  else
    RETVAL=$FAILURE
  fi
  return $RETVAL
};

function DEBUG_DONE_MESSAGE()
{
  if [ ${#1} -gt 0 ]; then
    SHOW_DATE_TIME
    CLB_TEXT; printf "[Debug] "
    CY_TEXT;  printf "Finished: "
    CC_TEXT;  printf "%s %s" "$1" "$(SHOW_RESULTS)"
    CN_TEXT;  printf "\n\n"
  fi
  return $RETVAL
};

# Check command line for arguments
for OPTIONS in $@; do
  case $OPTIONS in
    -v | --verbose)	declare -i BOL_VERBOSE=$TRUE;;
    -d | --daemon)	declare -i BOL_DAEMON=$TRUE;;
    --version)		SHOW_HEADER;	exit $SUCCESS;;
    [0-9])		declare -i DOOR=$OPTIONS;;
  esac
done


if [ $BOL_COLOR   -eq $TRUE     ]; then INIT_COLOR_SHORTHAND;                                   fi
if [ ${#OUTPUT}           -eq 0 ]; then declare -x OUTPUT="/dev/stderr";                        fi

# Simple function to get the Device IDs
# (Serial Numbers) of all USB Relay Modules
function GET_DEVID()
{
  declare -i RETVAL=$FAILURE
  while IFS= read LINE; do
    declare -i BOL_SERIAL=$FALSE
    for WORD in $LINE; do
      case $WORD in
        '#'[0-9])
            for SERIAL in $LINE; do $TRUE_BIN; done
	    declare -i LEN=${#SERIAL}
	    if [ $LEN -gt 1 ]; then
	        declare -x DEVID=${SERIAL:0:$((LEN-1))}
		declare -i RETVAL=$SUCCESS
		echo -e "$DEVID"
	    fi
	    ;;
      esac
    done
  done < <($CRELAY_BIN -i)
  return $RETVAL
};

function UNLOCK()
{
  declare -x DEVICE=$1
  declare -i DOOR=$2
  declare -i RETVAL=$SUCCESS
  if [ $BOL_VERBOSE -eq $TRUE ]; then DEBUG_START_MESSAGE "function UNLOCK()" 2>$OUTPUT; 	fi
  if [ ${#DEVICE} -ne 0 ] && [ ${#DOOR} -ne 0 ]; then
     if [ $BOL_VERBOSE -eq $TRUE ]; then DEBUG_EXEC_MESSAGE "$CRELAY_BIN -s $DEVICE $DOOR on";	fi
     $CRELAY_BIN -s $DEVICE $DOOR on
     if [ $BOL_VERBOSE -eq $TRUE ]; then DEBUG_DONE_MESSAGE "$CRELAY_BIN" 2>$OUTPUT;            fi
     RETVAL=$((RETVAL+$?))
     if [ ${#WAIT} -ne 0 ]; then $SLEEP_BIN $WAIT; fi
     if [ $BOL_VERBOSE -eq $TRUE ]; then DEBUG_EXEC_MESSAGE "$CRELAY_BIN -s $DEVICE $DOOR off"; fi
     $CRELAY_BIN -s $DEVICE $DOOR off
     if [ $BOL_VERBOSE -eq $TRUE ]; then DEBUG_DONE_MESSAGE "$CRELAY_BIN" 2>$OUTPUT;            fi
     RETVAL=$((RETVAL+$?))
  fi
  if [ $BOL_VERBOSE -eq $TRUE ]; then DEBUG_DONE_MESSAGE "function UNLOCK()" 2>$OUTPUT;         fi
  return $RETVAL
};

function TEST_FILE()
{
    declare -i RETVAL=$SUCCESS
    declare -i TARGET_LEN=$($CAT_BIN "$TARGET_FILE" | $WC_BIN -c)
    declare -x TARGET_DATA=$($CAT_BIN "$TARGET_FILE")

    if [ $BOL_VERBOSE -eq $TRUE ]; then DEBUG_START_MESSAGE "function TEST_FILE()" 2>$OUTPUT;         fi
    if [ -f "$TARGET_FILE" ]; then
	if [ $TARGET_LEN -lt 3 ]; then
	    case $TARGET_DATA in
		[0-9])	RETVAL=$SUCCESS;;
		*)	RETVAL=$FAILURE;;
	    esac
	else
	    RETVAL=$FAILURE
	fi
    else
	RETVAL=$FAILURE
    fi
    if [ $BOL_VERBOSE -eq $TRUE ]; then DEBUG_DONE_MESSAGE "function TEST_FILE()" 2>$OUTPUT;         fi
    return $RETVAL
};

# Function that monitors $MONITOR_PREFIX
function MONITOR_IO()
{
    declare -i RETVAL=$FAILURE
    if [ $BOL_VERBOSE -eq $TRUE ]; then DEBUG_START_MESSAGE "$INOTIFYWAIT_BIN" 2>$OUTPUT;        fi
    $INOTIFYWAIT_BIN ${INOTIFY_OPTS[@]} $MONITOR_PREFIX 2>/dev/null
    TEST_FILE
    if [ $? -eq $SUCCESS ]; then
        UNLOCK $DEVID $(cat "$TARGET_FILE")
        RETVAL=$?
        CC_TEXT; rm -vf "$TARGET_FILE"; CN_TEXT
    fi
    return $RETVAL
};

# Function that puts MONITOR_IO inside an infinite
function MONITOR_LOOP()
{
    declare -i RETVAL=$FAILURE
    CC_TEXT; if [ -f "$TARGET_FILE" ]; then rm -vf "$TARGET_FILE"; fi; CN_TEXT
    while [ $TRUE -eq $TRUE ]; do
        MONITOR_IO
        RETVAL=$?
    done
    return $RETVAL
};

if [ ${#INOTIFY_OPTS[@]}		-eq 0	   ]; then declare -a INOTIFY_OPTS=("--timeout 0" "--recursive" "--event modify" "--event create" "--event delete");	fi
if [ ${#MONITOR_PREFIX}	  		-eq 0      ]; then declare -x MONITOR_PREFIX="/var/lib/vsftpd/chroot/jail/door";						fi
if [ ${#DATA_FILE}			-eq 0	   ]; then declare -x DATA_FILE="door.dat";										fi
if [ ${#TARGET_FILE}			-eq 0	   ]; then declare -x TARGET_FILE="$MONITOR_PREFIX"/"$DATA_FILE";							fi
if [ ${#BOL_VERBOSE}	  		-eq 0      ]; then declare -i BOL_VERBOSE=$FALSE;										fi
if [ ${#BOL_DAEMON}       		-eq 0      ]; then declare -i BOL_DAEMON=$FALSE;                            						        fi
if [ $BOL_VERBOSE 			-eq $TRUE  ]; then SHOW_HEADER;													fi
if [ ${#WAIT}		  		-eq 0      ]; then declare -i WAIT=3;												fi
if [ ${#DEVID} 	          		-eq 0 	   ]; then declare -x DEVID=$(GET_DEVID); declare -i DEVIDRET=$?;							fi
if [ $BOL_VERBOSE -eq $TRUE ] && [ $DEVIDRET -eq 0 ]; then DEBUG_FOUND_MESSAGE "$DEVID" 2>$OUTPUT;									fi
if [ $BOL_DAEMON 			-eq $TRUE  ]; then MONITOR_LOOP;												fi
if [ $BOL_DAEMON -eq $FALSE ] && [ ${#DOOR}  -ne 0 ]; then UNLOCK $DEVID $DOOR;												fi

exit $RETVAL

