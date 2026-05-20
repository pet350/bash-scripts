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
export VERSION="0.2.1"

# Define Global String Variables
export HOST_FQDN=$(hostname --fqdn)

export TEMP="GetSerialSignal";        export GET_SIGNAL_BIN=$(GET_BIN)
unset TEMP

# Make sure all needed binaries exist and are defined
if [ ${#GET_SIGNAL_BIN}	-eq 0 ]; then echo -e "Error! Binary GetSerialSignal not found!";		exit $FAILURE;	fi
if [ ${#SLEEP_BIN}	-eq 0 ]; then echo -e "Error! Binary sleep not found!";				exit $FAILURE;	fi
if [ ${#GREP_BIN}       -eq 0 ]; then echo -e "Error! Binary grep not found!";                          exit $FAILURE;  fi
if [ ${#WC_BIN}         -eq 0 ]; then echo -e "Error! Binary wc not found!";                            exit $FAILURE;  fi
if [ ${#PS_BIN}         -eq 0 ]; then echo -e "Error! Binary ps not found!";                            exit $FAILURE;  fi

# Define Global String Variables IF thier not already set by the environment
if [ ${#DOOR_COM_PORT}	-eq 0 ]; then export DOOR_COM_PORT="ttyS0";					fi
if [ ${#DOOR_LOG_FILE}	-eq 0 ]; then export DOOR_LOG_FILE="/var/log/door.log";				fi
if [ ${#DOOR_LOG_KERN}	-eq 0 ]; then export DOOR_LOG_KERN="/dev/kmsg";					fi

# Define Global Arrays
declare -ag DOOR_SIGNAL_ARRAY=( "DSR" "DCD" "RI" );
declare -ag ADDITIONAL_ARRAY=();

# Define Global Integer Variables IF thier not already set by the environment
if [ ${#MAX_COUNT}	-eq 0 ]; then declare -ig MAX_COUNT=-1;						fi
if [ ${#TOTAL_DOORS}	-eq 0 ]; then declare -ig TOTAL_DOORS=3;					fi
if [ ${#PROC_THRESHOLD}	-eq 0 ]; then declare -ig PROC_THRESHOLD=3;					fi

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

# Define Global Boolean Variables
declare -ig BOL_LOG_ALT=$FALSE
declare -ig BOL_OUTPUT=$FALSE

# Function will get the total number of instances running
function GET_PROC_COUNT()
{
  $PS_BIN -ax | $GREP_BIN -v grep | $GREP_BIN $RUN_CMD | $WC_BIN -l
  return $?
};

function CHECK_PROC_THRESHOLD()
{
  declare -i RUNNING_PROC_COUNT=$(GET_PROC_COUNT)
  if [ $RUNNING_PROC_COUNT -gt $PROC_THRESHOLD ] || [ $RUNNING_PROC_COUNT -eq $PROC_THRESHOLD ]; then
    echo -e "$RUN_CMD process count:\t$RUNNING_PROC_COUNT"
    echo -e "Process total threshold:\t$PROC_THRESHOLD"
    exit $FAILURE
  fi
  return $SUCCESS
};

# Function displays door status to the screen (With ANSI Color if Available and Enabled)
function DISPLAY_STATUS()
{
  declare -i FUNCTION_RETURN=$SUCCESS
  SHOW_DATE_TIME
  printf "%b" $CLB;	printf "Door "
  printf "%b" $CY;	printf "%s: " $DOOR_NUMBER
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
  declare -i TMP_COLOR=$COLOR_SUPPORT
  # We don't want any of the ANSI color stuff being logged
  unset COLOR_SUPPORT
  export NOW="$(SHOW_DATE_TIME)"
  if [ $DOOR_STATUS -eq $LOCKED ]; then
    printf "%s Door %s: Locked\n"   "$NOW" "$DOOR_NUMBER" >>$DOOR_LOG
  elif [ $DOOR_STATUS -eq $UNLOCKED ]; then
    printf "%s Door %s: Unlocked\n" "$NOW" "$DOOR_NUMBER" >>$DOOR_LOG
  fi
  export COLOR_SUPPORT=$TMP_COLOR
  unset TMP_COLOR;	unset NOW
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
      if [ $BOL_DISPLAY		-eq $TRUE ]; then DISPLAY_STATUS; 						fi
      if [ $BOL_LOG_FILE	-eq $TRUE ]; then export DOOR_LOG="$DOOR_LOG_FILE";	LOG_STATUS; 		fi
      if [ $BOL_LOG_KERN	-eq $TRUE ]; then export DOOR_LOG="$DOOR_LOG_KERN";	LOG_STATUS;		fi
      if [ $BOL_LOG_ALT		-eq $TRUE ]; then for DOOR_LOG in ${ADDITIONAL_ARRAY[@]}; do LOG_STATUS; done;	fi
    fi
    OLD_STATUS_ARRAY[$((DOOR_NUMBER-1))]=$DOOR_STATUS
    ((DOOR_NUMBER++))
  done
  return $FUNCTION_RETURN
};

declare -ag HELP_ARRAY=( "--help" "Display this help message.\n" "--test" "Test mode doesn't actually monitor.\n" \
  "--with-display" "Displays door access monitor to display.\n" "--with-log-file" "Writes door access to log file.\n" \
  "--with-log-kern" "Writes door access to kernel messages.\n" "--without-display" "Doesn't display door access to monitor.\n" \
  "--without-log-file" "Doesn't write door access to log file.\n" "--without-log-kern" \
  "Doesn't write door access to kernel messages.\n" "--version" "Display version information and exit.\n" \
  "--bw" "Force Black & White text output.\n" "--color" "Enable ANSI color output if available.\n" "--force-color" \
  "Force enable ANSI color text.\n" "--serial-port=XXX" "Sets the COM port. defaults to ttyS0.\n" "--max-count=NN" \
  "Only loop NN times. defaults to unlimited.\n" "--wait=XX.YY" "Wait XX.YY seconds in between polling port. Defaults to 0.25\n" \
  "--no-wait" "Constantly poll the COM port without any pause.\n" "--proc-threshold=NN" "Sets maximum allowd process.\n" \
  "ZZZZ" "Write output to other device." );

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
	export BOL_OUTPUT=$TRUE;	export BOL_DISPLAY=$TRUE
	;;
'--with-log-file')
	export BOL_OUTPUT=$TRUE;	export BOL_LOG_FILE=$TRUE
	;;
'--with-log-kern')
	export BOL_OUTPUT=$TRUER;	export BOL_LOG_KERN=$TRUE
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
--proc-threshold=*)
	export PROC_THRESHOLD="${i#*=}"
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
	export BOL_LOG_ALT=$TRUE
	ADDITIONAL_ARRAY_LEN=${#ADDITIONAL_ARRAY[@]}
	ADDITIONAL_ARRAY[$((ADDITIONAL_ARRAY_LEN))]="$i"
	SHOW_DATE_TIME; echo -e "$RUN_CMD\tVersion: $VERSION\nAppended: $i to log output\n"
	;;
esac
done

if [ $BOL_COLOR -eq $TRUE ]; then INIT_COLOR_SHORTHAND; fi
if [ $BOL_HELP -eq $TRUE ]; then DO_HELP; fi

REQUIRE_ROOT_USER
CHECK_PROC_THRESHOLD
if [ $BOL_DISPLAY  -eq $TRUE ]; then BOL_OUTPUT=$TRUE; echo -e "$(SHOW_DATE_TIME) $RUN_CMD Version: $VERSION Starting new door access monitoring Session.";			fi
if [ $BOL_LOG_FILE -eq $TRUE ]; then BOL_OUTPUT=$TRUE; echo -e "$(SHOW_DATE_TIME) $RUN_CMD Version: $VERSION Starting new door access monitoring Session." >>$DOOR_LOG_FILE;	fi
if [ $BOL_LOG_KERN -eq $TRUE ]; then BOL_OUTPUT=$TRUE; echo -e "$(SHOW_DATE_TIME) $RUN_CMD Version: $VERSION Starting new door access monitoring Session." >>$DOOR_LOG_KERN;	fi
if [ $BOL_OUTPUT   -ne $TRUE ]; then echo -e "No output is enabled!"; exit $FAILURE; fi

MONITOR_DOORS
exit $?
