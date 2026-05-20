#!/bin/bash
# DoorEvent.sh
# Monitors COM port signals being received by Door Access System
# Shell Script By: Peter Talbott
# 9/1/2020

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

# Define Global String Variables
export HOST_FQDN=$(hostname --fqdn)

export TEMP="GetSerialSignal";        export GET_SIGNAL_BIN=$(GET_BIN)
unset TEMP

# Make sure all needed binaries exist and are defined
if [ ${#GET_SIGNAL_BIN}	-eq 0 ]; then echo -e "Error! Binary GetSerialSignal not found!";		exit $FAILURE;	fi
if [ ${#SLEEP_BIN}	-eq 0 ]; then echo -e "Error! Binary sleep not found!";				exit $FAILURE;	fi

# Define Global String Variables IF thier not already set by the environment
if [ ${#DOOR_COM_PORT}	-eq 0 ]; then export DOOR_COM_PORT="ttyS0";					fi
if [ ${#DOOR_LOG_FILE}	-eq 0 ]; then export DOOR_LOG_FILE="/var/log/door.log";				fi
if [ ${#DOOR_LOG_KERN}	-eq 0 ]; then export DOOR_LOG_KERN="/dev/kmsg";					fi

# Define Global Arrays
declare -ag DOOR_SIGNAL_ARRAY=( "DSR" "DCD" );

# Define Global Integer Variables IF thier not already set by the environment
if [ ${#MAX_COUNT}	-eq 0 ]; then declare -ig MAX_COUNT=-1;						fi
if [ ${#TOTAL_DOORS}	-eq 0 ]; then declare -ig TOTAL_DOORS=2;					fi

# Define Global "Floating Point" variables IF thier not already set by the environment
if [ ${#VAR_WAIT}	-eq 0 ]; then export VAR_WAIT="0.25";						fi

# Define Globak Boolean Variables IF their not already set by the environment
if [ ${#BOL_LOG_FILE}	-eq 0 ]; then declare -ig BOL_LOG_FILE=$FALSE;					fi
if [ ${#BOL_LOG_KERN}	-eq 0 ]; then declare -ig BOL_LOG_KERN=$FALSE;					fi
if [ ${#BOL_DISPLAY}	-eq 0 ]; then declare -ig BOL_DISPLAY=$TRUE;					fi

# Define LOCKED/UNLOCKED Status
declare -ig LOCKED=1
declare -ig UNLOCKED=0

# Define Global Integer Variables
declare -ig DOOR_NUMBER=1
declare -ig DOOR_STATUS=$LOCKED

# Function displays door status to the screen (With ANSI Color if Available and Enabled)
function DISPLAY_STATUS()
{
  declare -i FUNCTION_RETURN=$SUCCESS
  SHOW_DATE_TIME
  printf "%b" $CLB;	printf "Door "
  printf "%b" $CY;	printf "%s " $DOOR_NUMBER
  if [ $DOOR_STATUS -eq $LOCKED ]; then
    printf "%b" $CR;	printf "Locked"
  elif [ $DOOR_STATUS -eq $UNLOCKED ]; then
    printf "%b" $CG;	printf "Unlocked"
  fi
  printf "%b\n" $CN
  return $FUNCTION_RETURN
};

# Function writes the door status to $DOOR_LOG
function LOG_STATUS()
{
  declare -i FUNCTION_RETURN=$SUCCESS
  if [ $DOOR_STATUS -eq $LOCKED ]; then
    printf "%s Door %s Locked\n"   $(SHOW_DATE_TIME) $DOOR_NUMBER >>$DOOR_LOG
  elif [ $DOOR_STATUS -eq $UNLOCKED ]; then
    printf "%s Door %s Unlocked\n" $(SHOW_DATE_TIME) $DOOR_NUMBER >>$DOOR_LOG
  fi
  return $FUNCTION_RETURN
};

# Function returns the door signal status
function GET_STATUS()
{
  declare -i FUNCTION_RETURN=$SUCCESS
  declare -i INDEX=$((DOOR_NUMBER-1))
  FUNCTION_RETURN=$($GET_SIGNAL_BIN "/dev/$DOOR_COM_PORT" "${DOOR_SIGNAL_ARRAY[$((INDEX))]}")
  return $FUNCTION_RETURN
};

# Main Function to montor door status via serial port
function MONITOR_DOORS()
{
  declare -i FUNCTION_RETURN=$SUCCESS
  declare -i COUNT=0
  declare -i OLD_STATUS=$LOCKED
  declare -a OLD_STATUS_ARRAY=( "$LOCKED" "$LOCKED" );

  while [ $COUNT -ne $MAX_COUNT ]; do
    if [ $DOOR_NUMBER -gt $TOTAL_DOORS ]; then
      DOOR_NUMBER=1
      ((COUNT++))
      if [ $BOL_WAIT -eq $TRUE ]; then $SLEEP_BIN $VAR_WAIT; fi
    fi
    GET_STATUS
    export DOOR_STATUS=$?
    OLD_STATUS=${OLD_STATUS_ARRAY[$((DOOR_NUMBER-1))]}
    if [ $DOOR_STATUS -ne $OLD_STATUS ]; then
      if [ $BOL_DISPLAY		-eq $TRUE ]; then DISPLAY_STATUS; 					fi
      if [ $BOL_LOG_FILE	-eq $TRUE ]; then export DOOR_LOG="$DOOR_LOG_FILE";	LOG_STATUS; 	fi
      if [ $BOL_LOG_KERN	-eq $TRUE ]; then export DOOR_LOG="$DOOR_LOG_KERN";	LOG_STATUS;	fi
    fi
    OLD_STATUS_ARRAY[$((DOOR_NUMBER-1))]=$DOOR_STATUS
    ((DOOR_NUMBER++))
  done
  return $FUNCTION_RETURN
};

for i in "$@"
do
case $i in
'-h' | '--help')
	export BOL_HELP=$TRUE;		export VERBOSE="";		export BOL_DEBUG=$FALSE;	export BOL_VERBOSE=$FALSE;	export BOL_LOG_RESULTS=$FALSE
	;;
'-t' | '--test')
	export BOL_TEST=$TRUE;		export GET_SIGNAL_BIN="$TRUE_BIN"
	;;
'--with-display')
	export BOL_DISPLAY=$TRUE
	echo -e "$(SHOW_DATE_TIME) $RUN_CMD Version: $VERSION Starting new door access monitoring Session."
	;;
'--with-log-file')
	export BOL_LOG_FILE=$TRUE
	echo -e "$(SHOW_DATE_TIME) $RUN_CMD Version: $VERSION Starting new door access monitoring Session." >>$DOOR_LOG_FILE
	;;
'--with-log-kern')
	export BOL_LOG_KERN=$TRUE
        echo -e "$(SHOW_DATE_TIME) $RUN_CMD Version: $VERSION Starting new door access monitoring Session." >>$DOOR_LOG_KERN
        ;;
'--without-display')
        export BOL_DISPLAY=$FALSE
        ;;
'--without-log-file')
	export BOL_LOG_FILE=$FALSE
	;;
'--without-log-kern')
	export BOL_LOG_KERN=$FALSE
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
	export BOL_FORCE_COLOR=$TRUE;	export BOL_COLOR=$TRUE
        ;;
--serial-port=*)
	export DOOR_COM_PORT="${i#*=}"
	;;
--max-count=*)
	X="${i#*=}"
        export MAX_COUNT=$((X))
        ;;
-w=* | --wait=*)
        X="${i#*=}"
        export VAR_WAIT=$((X))
	export BOL_WAIT=$TRUE
        ;;
'--no-wait')
	export BOL_WAIT=$FALSE
	;;
*)
	ADDITIONAL_ARRAY_LEN=${#ADDITIONAL_ARRAY[@]}
	ADDITIONAL_ARRAY[$((ADDITIONAL_ARRAY_LEN))]="$i"
	SHOW_DATE_TIME; echo -e "$RUN_CMD\tVersion: $VERSION\nAppended: $i to encoder options\n"
	;;
esac
done

if [ $BOL_COLOR -eq $TRUE ]; then INIT_COLOR_SHORTHAND; fi
#if [ $BOL_START -eq $FALSE ] && [ $BOL_STOP -eq $FALSE ]; then BOL_HELP=$TRUE; fi
if [ $BOL_HELP -eq $TRUE ]; then DO_HELP; fi

REQUIRE_ROOT_USER
MONITOR_DOORS
exit $?
