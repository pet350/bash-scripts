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

## Ver 0.3 Change Log
# Defaults to Verbose
# All the DEBUG_ and INFO_ functions were moved into include files
# Added the --help funtion

## Ver 0.2 Change log
# Changed default source prefix from /tmp/door to ~/.door
# Solves permission issues 6/19/2023

export RUN_CMD="$(basename $0)"
export VERSION="0.4"
export AUTHOR="Peter Talbott"
export MODIFIED="2023-08-12"

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

function SHOW_NO_ARGS()
{
    SHOW_HEADER
    echo -e "for help: $RUN_CMD --help (or -h)\n"
    return $SUCCESS
};

declare -i BOL_OPTS=$FALSE
declare -a HELP_ARRAY=("--verbose" "(or -v) Verbose output (Default)\n" "--quiet" "(or -q) Display nothing\n" "--help" "(or -h) Display this help message\n" \
  "--version" "Display Version info\n" "--source-prefix=XXX" "(or -s=XXX) Override default Source Prefix\n" "--username=XXX" \
  "(or -u=XXX) Override default Username\n" "--password=XXX" "(or -p=XXX) Override default password\n" "--destination=XXX" "(or -d=XXX) Override default Destination\n" \
  "--filename=XXX" "(or -f=XXX) Override default filename\n" "--host=XXX" "(or -h=XXX) Override default host\n" "0-9" "Door number to Unlock");

# Check command line for arguments
for OPTIONS in $@; do
  case $OPTIONS in
    -d | --debug)		declare -i BOL_OPTS=$TRUE;	declare -i BOL_QUIET=$FALSE;	declare -i BOL_VERBOSE=$TRUE;		declare -x VERBOSE="-v";	declare -i BOL_DEBUG=$TRUE;;
    -v | --verbose)		declare -i BOL_OPTS=$TRUE;	declare -i BOL_QUIET=$FALSE;	declare -i BOL_VERBOSE=$TRUE;		declare -x VERBOSE="-v";	declare -i BOL_DEBUG=$FALSE;;
    -q | --quiet)		declare -i BOL_OPTS=$TRUE;	declare -i BOL_QUIET=$TRUE;	declare -i BOL_VERBOSE=$FALSE;		declare -x VERBOSE="";		declare -i BOL_DEBUG=$TRUE;;
    -h | --help)		declare -i BOL_HELP=$TRUE;;
    --version)			SHOW_HEADER;	exit $SUCCESS;;
    --source-prefix=* | -s=*)	declare -x SOURCE_PREFIX="${OPTIONS#*=}";;
    --username=*      | -u=*)	declare -x REMOTE_USER="${OPTIONS#*=}";;
    --password=*      | -p=*)	declare -x REMOTE_PASS="${OPTIONS#*=}";;
    --destination=*   | -d=*)	declare -i REMOTE_DEST="${OPTIONS#*=}";;
    --filename=*      | -f=*)	declare -i TARGET="${OPTIONS#*=}";;
    --host=*          | -h=*)	declare -x REMOTE_HOST="${OPTIONS#*=}";;
    [0-9])			declare -i DOOR_NUMBER=$OPTIONS;;
  esac
done

if [ $BOL_OPTS	  -ne $TRUE   ]; then declare BOL_VERBOSE=$TRUE; declare -x VERBOSE="-v";			 		fi
if [ $BOL_COLOR   -eq $TRUE   ]; then INIT_COLOR_SHORTHAND;				      	                      		fi
if [ $BOL_HELP	  -eq $TRUE   ]; then DO_HELP; exit $SUCCESS;									fi
if [ ${#DOOR_NUMBER}	-eq 0 ]; then SHOW_NO_ARGS; exit $SUCCESS;								fi
if [ ${#BOL_VERBOSE}	-eq 0 ]; then declare -i BOL_VERBOSE=$FALSE; declare -x VERBOSE="";					fi
if [ ${#SOURCE_PREFIX}	-eq 0 ]; then declare -x SOURCE_PREFIX="$HOME/.door";							fi
if [ ! -d $SOURCE_PREFIX      ]; then CC_TEXT; mkdir -p $VERBOSE "$SOURCE_PREFIX";	CN_TEXT;				fi
if [ ${#TARGET}		-eq 0 ]; then declare -x TARGET="door.dat";								fi
if [ ${#REMOTE_HOST}	-eq 0 ]; then declare -x REMOTE_HOST="xen.vlan10.gigaware.lan";						fi
if [ ${#REMOTE_USER}	-eq 0 ]; then declare -x REMOTE_USER="rauser";								fi
if [ ${#REMOTE_PASS}	-eq 0 ]; then declare -x REMOTE_PASS="Bl4ck3nd";							fi
if [ ${#REMOTE_DEST}	-eq 0 ]; then declare -x REMOTE_DEST="/door";								fi
if [ ${#LOCAL_FILE}	-eq 0 ]; then declare -x LOCAL_FILE="$SOURCE_PREFIX"/"$TARGET";						fi
if [ $BOL_VERBOSE   -eq $TRUE ]; then SHOW_HEADER; printf "\n";									fi
if [ -f "$LOCAL_FILE"         ]; then
if [ $BOL_VERBOSE   -eq $TRUE ]; then SHOW_DATE_TIME; CC_TEXT;					 			        fi
				 rm $VERBOSE "$LOCAL_FILE";  CN_TEXT;                               				fi
if [ ${#LOCAL_FILE}	-ne 0 ]; then echo $DOOR_NUMBER >"$LOCAL_FILE";								fi
if [ $BOL_VERBOSE   -eq $TRUE ]  && [ $BOL_DEBUG 	-eq $FALSE ]; then
				 INFO_EXEC_MESSAGE "$CURL_BIN -p --insecure -T $LOCAL_FILE ..."; 				fi
if [ $BOL_DEBUG	    -eq $TRUE ]; then DEBUG_INFO_MESSAGE \
	"$CURL_BIN -p --insecure -T $LOCAL_FILE -u $REMOTE_USER:$REMOTE_PASS ftp://$REMOTE_HOST$REMOTE_DEST/ 2>/dev/null";	fi
$CURL_BIN -p --insecure -T $LOCAL_FILE -u "$REMOTE_USER":"$REMOTE_PASS" ftp://$REMOTE_HOST$REMOTE_DEST/ 2>/dev/null
declare -i RETVAL=$?
if [ $BOL_VERBOSE   -eq $TRUE ]; then INFO_DONE_MESSAGE "$CURL_BIN";								fi
if [ -f "$LOCAL_FILE"	      ]; then
if [ $BOL_VERBOSE   -eq $TRUE ]; then SHOW_DATE_TIME; CC_TEXT;									fi
				 rm $VERBOSE $LOCAL_FILE; CN_TEXT;								fi

exit $EXIT_VALUE
