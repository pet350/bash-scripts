#!/bin/bash
# ru.sh - Remote Unlock
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

## Ver 0.2 Change log
# Changed default source prefix from /tmp/door to ~/.door
# Solves permission issues 6/19/2023

export RUN_CMD="$(basename $0)"
export VERSION="0.2"
export AUTHOR="Peter Talbott"
export MODIFIED="2023-04-06"

# Define a few more binary variables
for DATA in ftp curl egrep chown sleep cat wc find true; do
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
  echo -e "$RUN_CMD\t\t\tRemote Unlock Version: $VERSION\nBy: $AUTHOR\tDated: $MODIFIED"
  return $SUCCESS
};

function SHOW_NO_ARGS()
{
    SHOW_HEADER
    echo -e "for help: $RUN_CMD --help (or -h)\n"
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
    CN_TEXT;  printf "\n"
  fi
  return $RETVAL
};

# Check command line for arguments
for OPTIONS in $@; do
  case $OPTIONS in
    -v | --verbose)	declare -i BOL_VERBOSE=$TRUE;		declare -x VERBOSE="-v";;
    -h | --help)	declare -i BOL_HELP=$TRUE;;
    --version)		SHOW_HEADER;	exit $SUCCESS;;
    --source-prefix=*)	declare -x SOURCE_PREFIX="${OPTIONS#*=}";;
    --username=*)	declare -x REMOTE_USER="${OPTIONS#*=}";;
    --password=*)	declare -x REMOTE_PASS="${OPTIONS#*=}";;
    --destination=*)	declare -i REMOTE_DEST="${OPTIONS#*=}";;
    --filename=*)	declare -i TARGET="${OPTIONS#*=}";;
    --host=*)		declare -x REMOTE_HOST="${OPTIONS#*=}";;
    [0-9])		declare -i DOOR_NUMBER=$OPTIONS;;
  esac
done


if [ $BOL_COLOR   -eq $TRUE   ]; then INIT_COLOR_SHORTHAND;      	                      		fi
if [ ${#DOOR_NUMBER}	-eq 0 ]; then SHOW_NO_ARGS; exit $SUCCESS;					fi
if [ ${#BOL_VERBOSE}	-eq 0 ]; then declare -i BOL_VERBOSE=$FALSE; declare -x VERBOSE="";		fi
if [ ${#SOURCE_PREFIX}	-eq 0 ]; then declare -x SOURCE_PREFIX="$HOME/.door";				fi
if [ ! -d $SOURCE_PREFIX      ]; then CC_TEXT; mkdir -p $VERBOSE "$SOURCE_PREFIX";	CN_TEXT;	fi
if [ ${#TARGET}		-eq 0 ]; then declare -x TARGET="door.dat";					fi
if [ ${#REMOTE_HOST}	-eq 0 ]; then declare -x REMOTE_HOST="xen.gigaware.lan";			fi
if [ ${#REMOTE_USER}	-eq 0 ]; then declare -x REMOTE_USER="rauser";					fi
if [ ${#REMOTE_PASS}	-eq 0 ]; then declare -x REMOTE_PASS="Bl4ck3nd";				fi
if [ ${#REMOTE_DEST}	-eq 0 ]; then declare -x REMOTE_DEST="/door";					fi
if [ ${#LOCAL_FILE}	-eq 0 ]; then declare -x LOCAL_FILE="$SOURCE_PREFIX"/"$TARGET";			fi
if [ $BOL_VERBOSE   -eq $TRUE ]; then SHOW_HEADER; printf "\n";						fi
if [ -f "$LOCAL_FILE"         ]; then
if [ $BOL_VERBOSE   -eq $TRUE ]; then SHOW_DATE_TIME; CC_TEXT;					        fi
				 rm $VERBOSE "$LOCAL_FILE";  CN_TEXT;                               	fi
if [ ${#LOCAL_FILE}	-ne 0 ]; then echo $DOOR_NUMBER >"$LOCAL_FILE";					fi
if [ $BOL_VERBOSE   -eq $TRUE ]; then DEBUG_EXEC_MESSAGE "$CURL_BIN -p --insecure -T $LOCAL_FILE ..."; 	fi
$CURL_BIN -p --insecure -T $LOCAL_FILE -u "$REMOTE_USER":"$REMOTE_PASS" ftp://$REMOTE_HOST$REMOTE_DEST/ 2>/dev/null
declare -i RETVAL=$?
if [ $BOL_VERBOSE   -eq $TRUE ]; then DEBUG_DONE_MESSAGE "$CURL_BIN";					fi
if [ -f "$LOCAL_FILE"	      ]; then
if [ $BOL_VERBOSE   -eq $TRUE ]; then SHOW_DATE_TIME; CC_TEXT;						fi
				 rm $VERBOSE $LOCAL_FILE; CN_TEXT;					fi

exit $EXIT_VALUE
