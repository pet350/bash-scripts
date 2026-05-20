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
export AUTHOR="Peter Talbott"
export MODIFIED="2022-04-30 2022-07-21"
declare -i SCRIPT_RETURN=$SUCCESS

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

if [ ${#ZRAMCTL_BIN}	-eq 0 ]; then export TEMP="zramctl"; export "${TEMP^^}_BIN"="$(GET_BIN)"; unset TEMP;	fi
if [ ${#MKSWAP_BIN}	-eq 0 ]; then export TEMP="mkswap";  export "${TEMP^^}_BIN"="$(GET_BIN)"; unset TEMP;	fi
if [ ${#SWAPON_BIN}	-eq 0 ]; then export TEMP="swapon";  export "${TEMP^^}_BIN"="$(GET_BIN)"; unset TEMP;	fi
if [ ${#SWAPOFF_BIN}	-eq 0 ]; then export TEMP="swapoff"  export "${TEMP^^}_BIN"="$(GET_BIN)"; unset TEMP;	fi

function START()
{
  declare -i COUNT=-1
  declare -i FUNCTION_RETURN=$SUCCESS
  while [ $COUNT -ne $((DEVICES-1)) ]; do
    ((COUNT++))
    DEV_NAME="$NAME$COUNT"
    DEVICE="$DEV_PREFIX$COUNT"
    if [ $BOL_VERBOSE -eq $TRUE ]; then SHOW_DATE_TIME; CLB_TEXT; printf "Configuring: "; CY_TEXT; printf "%s\n" $DEVICE; CN_TEXT;								fi
    if [ $BOL_DEBUG   -eq $TRUE ]; then SHOW_DATE_TIME; CLB_TEXT; printf "Executing: "; CY_TEXT; echo "$ZRAMCTL_BIN --size=$((SIZE))M $DEVICE >$OUTPUT 2>$OUTPUT"; CN_TEXT;			fi
    if [ $BOL_VERBOSE -eq $TRUE ]; then SHOW_DATE_TIME; fi; CC_TEXT; $ZRAMCTL_BIN --size="$((SIZE))M" $DEVICE >$OUTPUT 2>$OUTPUT; export RETVAL=$?; export COMMAND=$ZRAMCTL_BIN; CN_TEXT
    if [ $BOL_VERBOSE -eq $TRUE ]; then SHOW_DATE_TIME; LOG_RESULTS; fi
    if [ $BOL_DEBUG   -eq $TRUE ]; then SHOW_DATE_TIME; CLB_TEXT; printf "Executing: "; CY_TEXT; echo "$MKSWAP_BIN --label=$DEV_NAME $DEVICE >$OUTPUT 2>$OUTPUT"; CN_TEXT;		fi
    if [ $BOL_VERBOSE -eq $TRUE ]; then SHOW_DATE_TIME; fi; CC_TEXT; $MKSWAP_BIN --label=$DEV_NAME $DEVICE >$OUTPUT 2>$OUTPUT; export RETVAL=$?; export COMMAND=$MKSWAP_BIN; CN_TEXT
    if [ $BOL_VERBOSE -eq $TRUE ]; then SHOW_DATE_TIME; LOG_RESULTS; fi
    if [ $BOL_DEBUG   -eq $TRUE ]; then SHOW_DATE_TIME; CLB_TEXT; printf "Executing: "; CY_TEXT; echo "$SWAPON_BIN $VERBOSE $DEVICE >$OUTPUT 2>$OUTPUT"; CN_TEXT;				fi
    if [ $BOL_VERBOSE -eq $TRUE ]; then SHOW_DATE_TIME; fi; CC_TEXT; $SWAPON_BIN $VERBOSE $DEVICE >$OUTPUT 2>$OUTPUT; export RETVAL=$?; FUNCTION_RETURN=$((FUNCTION_RETURN+RETVAL)); export COMMAND=$SWAPON_BIN;  CN_TEXT
    if [ $BOL_VERBOSE -eq $TRUE ]; then SHOW_DATE_TIME; LOG_RESULTS; fi
    if [ $BOL_QUIET   -ne $TRUE ]; then printf "\n" >$OUTPUT; fi
  done
  return $FUNCTION_RETURN
};

function STOP()
{
  declare -i COUNT=-1
  declare -i FUNCTION_RETURN=$SUCCESS
  while [ $COUNT -ne $DEVICES ];  do
    ((COUNT++))
    DEV_NAME="$NAME$COUNT"
    DEVICE="$DEV_PREFIX$COUNT"
    if [ $BOL_VERBOSE -eq $TRUE ]; then SHOW_DATE_TIME; CLB_TEXT; printf "Deconfiguring: "; CY_TEXT; printf "%s\n" $DEVICE; CN_TEXT;                                                             fi
    if [ $BOL_DEBUG   -eq $TRUE ]; then SHOW_DATE_TIME; CLB_TEXT; printf "Executing: "; CY_TEXT; echo "$SWAPOFF_BIN $VERBOSE $DEVICE >$OUTPUT 2>$OUTPUT";  CN_TEXT;			          fi
    if [ $BOL_VERBOSE -eq $TRUE ]; then SHOW_DATE_TIME; fi; CC_TEXT; $SWAPOFF_BIN $VERBOSE $DEVICE >$OUTPUT 2>$OUTPUT; export RETVAL=$?; export COMMAND=$SWAPOFF_BIN; CN_TEXT;
    if [ $BOL_VERBOSE -eq $TRUE ]; then SHOW_DATE_TIME; LOG_RESULTS; fi
    if [ $BOL_QUIET   -ne $TRUE ]; then printf "\n" >$OUTPUT; fi
  done
  return $FUNCTION_RETURN
};


for OPTIONS in $@; do
  case ${OPTIONS,,} in
    'start')		declare -i BOL_START=$TRUE;	declare -i BOL_STOP=$FALSE;;
    'stop')		declare -i BOL_START=$FALSE;	declare -i BOL_STOP=$TRUE;;
    'restart')		declare -i BOL_START=$TRUE;	declare -i BOL_STOP=$TRUE;;
    --help    | -h)	declare -i BOL_START=$FALSE;	declare -i BOL_STOP=$FALSE;	declare BOL_HELP=$TRUE;;
    --debug   | -d)	declare -i BOL_VERBOSE=$TURE;   declare -i BOL_QUIET=$FALSE;    export OUTPUT="/dev/stdout";    export VERBOSE="-v";	declare -i BOL_DEBUG=$TRUE;;
    --verbose | -v)	declare -i BOL_VERBOSE=$TURE;	declare -i BOL_QUIET=$FALSE;	export OUTPUT="/dev/stdout";	export VERBOSE="-v";	declare -i BOL_DEBUG=$BOL_DEBUG;;
    --quiet   | -q)	declare -i BOL_VERBOSE=$FALSE;	declare -i BOL_QUIET=$TRUE;	export OUTPUT="/dev/null";	export VERBOSE="";		declare -i BOL_DEBUG=$FALSE;;
    --color)		declare -i BOL_COLOR=$TRUE;;
    --bw)		declare -i BOL_COLOR=$FALSE;;
    --size=*)		declare -i SIZE=${OPTIONS#*=};;
    --devices=*)	declare -i DEVICES=${OPTIONS#*=};;
    --name=*)		export NAME="${OPTIONS#*=}";;
    --cfg-file=*)	export CFG_FILE="${OPTIONS#*=}";;
    --output=*)		export OUTPUT="${OPTIONS#*=}";;
    --version)		SHOW_HEADER;			exit $SUCCESS;;
  esac
done

if [ ${#BOL_START}	-eq 0 		]; then declare -i BOL_START=$FALSE;		fi
if [ ${#BOL_STOP}	-eq 0 		]; then declare -i BOL_STOP=$FALSE;		fi
if [ ${#BOL_VERBOSE}	-eq 0 		]; then declare -i BOL_VERBOSE=$FALSE;		fi
if [ ${#BOL_DEBUG}	-eq 0		]; then declare -i BOL_DEBUG=$FALSE;		fi
if [ ${#BOL_HELP}	-eq 0 		]; then declare -i BOL_HELP=$FALSE;		fi
if [ ${#BOL_QUIET}	-eq 0 		]; then declare -i BOL_QUIET=$FALSE;		fi
if [ ${#BOL_COLOR}	-eq 0 		]; then declare -i BOL_COLOR=$TRUE;		fi
if [ ${#SIZE}		-eq 0 		]; then declare -i SIZE=512;			fi
if [ ${#DEVICES}	-eq 0 		]; then declare -i DEVICES=4;			fi
if [ ${#NAME}		-eq 0 		]; then export NAME="ZRAM";			fi
if [ ${#DEV_PREFIX}	-eq 0		]; then export DEV_PREFIX="/dev/zram";		fi
if [ ${#OUTPUT}		-eq 0		]; then export OUTPUT="/dev/kmsg";		fi
if [ ${#CFG_FILE}	-eq 0		]; then export CFG_FILE="/etc/zswap.conf";	fi
if [ -f			"$CFG_FILE"	]; then . "$CFG_FILE";				fi
if [ $BOL_COLOR		-eq $TRUE	]; then INIT_COLOR_SHORTHAND;			fi
if [ $BOL_HELP		-eq $TRUE	]; then DO_HELP; exit $SUCCESS;			fi
if [ $BOL_STOP		-eq $TRUE	]; then STOP;	SCRIPT_RETURN=$?;		fi
if [ $BOL_START		-eq $TRUE	]; then START;	SCRIPT_RETURN=$?;		fi

exit $SCRIPT_RETURN
