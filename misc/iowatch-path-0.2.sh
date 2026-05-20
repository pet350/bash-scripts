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
export VERSION="0.2"

declare -ag XTRA=();
declare -ag OPTS=();
declare -ig XTRA_LEN=${#XTRA[@]}

if [ ${#DEFAULT_PATH}		-eq 0 ]; then export DEFAULT_PATH="/usr/local/scripts";							fi
if [ ${#DEFAULT_OPTIONS}	-eq 0 ]; then export DEFAULT_OPTIONS="modify,create,delete,move";					fi
if [ ${#DEFAULT_LOGFILE}	-eq 0 ]; then export DEFAULT_LOGFILE="/var/log/UnisonScripts.log";					fi
if [ ${#UNISON_SCRIPT}		-eq 0 ]; then export UNISON_SCRIPT="/usr/local/sbin/UnisonServers.sh";					fi
if [ ${#BOL_ALT}		-eq 0 ]; then declare -ig BOL_ALT=$FALSE;								fi
if [ ${#BOL_NON_ROOT}		-eq 0 ]; then declare -ig BOL_NON_ROOT=$FALSE;								fi
if [ ${#EXTRA_OPTS}		-ne 0 ]; then for DATA in $EXTRA_OPTS; do XTRA[$((XTRA_LEN))]="$DATA"; XTRA_LEN=${#XTRA[@]}; done;	fi

function MONITOR_LOOP()
{
  while true; do
    MONITOR_PATH
  done
  return $?
};

function MONITOR_PATH()
{
  declare -i INDEX=-1
  declare -i FUNCTION_RETURN=$FAILURE
  if [ $BOL_SHORT_PATH -eq $FALSE ]; then export UNISON_PATH="$MONITOR_PATH"; 											fi
  if [ $BOL_VERBOSE -eq $TRUE ]; then printf "%b" $CLB; printf "Starting to Monitor: "; printf "%b" $CY; printf "%s" $MONITOR_PATH; printf "%b\n" $CN; 		fi
  OUTPUT=$($INOTIFYWAIT_BIN -q -e modify,create,delete,move -r $MONITOR_PATH)
  if [ $? -eq $SUCCESS ]; then
    for DATA in $OUTPUT; do
      ((INDEX++))
      if [ $INDEX -eq 0 ] && [ $BOL_SHORT_PATH -eq $TRUE ]; then export UNISON_PATH="$DATA"; 									fi
    done
    if [ $BOL_VERBOSE	-eq $TRUE  ]; then printf "%b" $CLR; printf "Change Detected!";	printf "%b\n" $CN;							fi
    if [ $BOL_ALT	-eq $FALSE ]; then OPTS=( "--custom-folder=$UNISON_PATH" "--threshold=1" "--allow-delete" "--no-preferance" "--bw" "${XTRA[@]}" );	fi
    if [ $BOL_DEBUG     -eq $TRUE  ]; then printf "%b" $CLB; printf "Executing: "; printf "%b" $CY; printf "$UNISON_SCRIPT ${OPTS[@]}";	printf "%b\n" $CN;	fi
    printf "%b" $CC; $UNISON_SCRIPT ${OPTS[@]} | tee -a "$LOGFILE"; FUNCTION_RETURN=$?; printf "%b" $CN
  fi
  return $FUNCTION_RETURN
};

for i in "$@"; do
  case $i in
    '-h' | '--help')
	export BOL_HELP=$TRUE
	;;
    '-d' | '--debug')
	export BOL_DEBUG=$TRUE
	;;
    '-v' | '--verbose')
	export BOL_VERBOSE=$TRUE
	;;
    '-l' | '--long-paths')
	export BOL_SHORT_PATH=$FALSE
	;;
    '-s' | '--short-paths')
	export BOL_SHORT_PATH=$TRUE
	;;
    '--non-root')
	export BOL_NON_ROOT=$TRUE
	;;
    --alt=*)
	export ALT_CFG="${i#*=}"
	if [ -f $ALT_CFG ]; then
	  export BOL_ALT=$TRUE
	  export UNISON_SCRIPT="$UNISON_BIN"
	  . $ALT_CFG
        else
	  echo -e "File: $ALT_CFG does not exist!"
	  exit $FAILURE
	fi
	;;
    --path=*)
        export MONITOR_PATH="${i#*=}"
        ;;
    --logfile=*)
	export LOGFILE="${i#*=}"
	;;
    '--version')
	echo -e "$RUN_CMD\tVersion: $VERSION\nBy: Peter Talbott"
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
    *)
	XTRA_LEN=${#XTRA[@]}
	XTRA[$((XTRA_LEN))]="${i#*=}"
	;;
  esac
done

if [ ${#BOL_SHORT_PATH}			 -eq 0		]; then declare -ig BOL_SHORT_PATH=$TRUE;	fi
if [ ${#LOGFILE}			 -eq 0		]; then export LOGFILE="$DEFAULT_LOGFILE";	fi
if [ ${#MONITOR_PATH}			 -eq 0		]; then export MONITOR_PATH="$DEFAULT_PATH";	fi
if [ $BOL_COLOR				 -eq $TRUE	]; then INIT_COLOR_SHORTHAND;			fi
if [ $BOL_HELP				 -eq $TRUE	]; then DO_HELP;				fi
if [ $(id -u) -ne 0 ] && [ $BOL_NON_ROOT -eq $FALSE	]; then CHECK_ROOT_USER;			fi

MONITOR_LOOP
exit $?
