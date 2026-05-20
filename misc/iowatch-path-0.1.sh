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

# Define String Variables IF not already Defined
if [ ${#DEFAULT_PATH}		-eq 0 ]; then export DEFAULT_PATH="/usr/local/scripts";			fi
if [ ${#DEFAULT_OPTIONS}	-eq 0 ]; then export DEFAULT_OPTIONS="modify,create,delete,move";	fi
if [ ${#DEFAULT_LOGFILE}	-eq 0 ]; then export DEFAULT_LOGFILE="/var/log/UnisonScripts.log";	fi
if [ ${#UNISON_SCRIPT}		-eq 0 ]; then export UNISON_SCRIPT="/usr/local/sbin/UnisonServers.sh";	fi
if [ ${#CFG_FILE}		-eq 0 ]; then export CFG_FILE="/etc/docs.cfg";				fi

# Function creates an endless loop
function MONITOR_LOOP()
{
  while true; do
    MONITOR_PATH
  done
  return $?
};

declare -ag HELP_ARRAY=( "--help" "or -h : Displays this message.\n" "--debug" "or -d : Display debug informations.\n" "--verbose"	\
	"or -v : Verbose output.\n" "--long-paths" "or -l : Unison path is the path where filesystem changed.\n" "--short-paths"	\
	"or -s : Unison path is the root of the filesystem beinbg monitored.\n" "--allow-user" "or -a : Allow non root to execute.\n"	\
	"--test" "or -t : Test mode, does not execute unison binary.\n" "--path=XXX" "Path being monitored.\n" "--logfile=XXX"		\
	"logfile name.\n" "XXX" "Pass onto Unison script any additional arguments.\n" "--bw" "or -b : Force black and white.\n"		\
	"--color" "or -c : Enable ANSI Color.\n" "--config=XXX" "or --alt=XXX : Specify alternate config file.");
declare -ag OPT_ARRAY=();
declare -ig OPT_ARRAY_LEN=${#OPT_ARRAY[@]}

function MONITOR_PATH()
{
  declare -i INDEX=-1
  declare -i FUNCTION_RETURN=$FAILURE
  if [ $BOL_SHORT_PATH -eq $FALSE ]; then export UNISON_PATH="$MONITOR_PATH"; fi
  if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Starting to Monitor: $MONITOR_PATH"; fi
  OUTPUT=$($INOTIFYWAIT_BIN -q -e modify,create,delete,move -r $MONITOR_PATH)
  if [ $? -eq $SUCCESS ]; then
    for DATA in $OUTPUT; do
      ((INDEX++))
      if [ $INDEX -eq 0 ] && [ $BOL_SHORT_PATH -eq $TRUE ]; then export UNISON_PATH="$DATA"; fi
    done
    if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Change Detected!"; fi
    if [ $BOL_DEBUG -eq $TRUE ]; then echo -e "Executing: $UNISON_SCRIPT --custom-folder=$UNISON_PATH $ALLOW_USER_STRING --threshold=1 --allow-delete --no-preferance $COLOR_STRING $TEST_STRING $VERBOSE_STRING $DEBUG_STRING ${OPT_ARRAY[@]}"; fi
    $UNISON_SCRIPT --custom-folder="$UNISON_PATH" $ALLOW_USER_STRING --threshold=1 --allow-delete --no-preferance $COLOR_STRING $TEST_STRING $VERBOSE_STRING $DEBUG_STRING ${OPT_ARRAY[@]} | tee -a "$LOGFILE"
    FUNCTION_RETURN=$?
  fi
  return $FUNCTION_RETURN
};

for ARGS in "$@"; do
  case ${ARGS,,} in
    -h | --help)		export BOL_HELP=$TRUE;;
    -d | --debug)	 	export BOL_DEBUG=$TRUE;							export DEBUG_STRING="--debug";;
    -v | --verbose)		export BOL_VERBOSE=$TRUE;						export VERBOSE_STRING="--verbose";;
    -l | --long-paths)		export BOL_SHORT_PATH=$FALSE;;
    -s | --short-paths)		export BOL_SHORT_PATH=$TRUE;;
    -a | --allow-user)		export BOL_ALLOW_USER=$TRUE;						export ALLOW_USER_STRING="--non-root";;
    -t | --test)		export BOL_TEST=$TRUE;							export TEST_STRING="--test";;
    -c | --color)		export BOL_COLOR=$TRUE;							export COLOR_STRING="--color";;
    -b | --bw)			export BOL_COLOR=$FALSE;						export COLOR_STRING="--bw";;
    --path=*)			export MONITOR_PATH="${ARGS#*=}";;
    --alt=* | --config=*)	export CFG_FILE="${ARGS#*=}";;
    --logfile=*)		export LOGFILE="${ARGS#*=}";;
    *)				OPT_ARRAY_LEN=${#OPT_ARRAY[@]};						OPT_ARRAY[$((OPT_ARRAY_LEN))]=$ARGS;;
  esac
done

if [ ${#BOL_ALLOW_USER}	-eq 0						]; then declare -ig BOL_ALLOW_USER=$FALSE;	export ALLOW_USER_STRING="";	fi
if [ ${#BOL_SHORT_PATH}	-eq 0						]; then declare -ig BOL_SHORT_PATH=$TRUE;					fi
if [ ${#COLOR_STRING}	-eq 0						]; then export COLOR_STRING="--bw";						fi
if [ ${#LOGFILE}	-eq 0						]; then export LOGFILE="$DEFAULT_LOGFILE";					fi
if [ ${#MONITOR_PATH}	-eq 0						]; then export MONITOR_PATH="$DEFAULT_PATH";					fi
if [ $BOL_COLOR		-eq $TRUE					]; then INIT_COLOR_SHORTHAND;							fi
if [ $BOL_HELP		-eq $TRUE					]; then DO_HELP;								fi
if [ -f "$CFG_FILE"							]; then echo -e "Loading: $CFG_FILE"; . "$CFG_FILE";				fi
if [ $BOL_ALLOW_USER	-eq $TRUE					]; then export ALLOW_USER_STRING="--non-root";					fi
if [ ${#BOL_NON_ROOT}	-ne 0 ]; then if [ $BOL_NON_ROOT -eq $TRUE 	]; then export ALLOW_USER_STRING="--non-root"; fi; 	                     	fi
if [ $(id -u) -ne 0 ] && [ $BOL_ALLOW_USER -eq $FALSE			]; then CHECK_ROOT_USER;							fi

MONITOR_LOOP
exit $?
