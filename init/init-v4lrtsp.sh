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
export VERSION="0.3"

export DEVICE_ID="card0"
export V4L_PREFIX="/usr/share/v4l"
export DEVICE_NAME="$V4L_PREFIX"/"$DEVICE_ID"
#"$(a=-1; for X in $(ls -lh $V4L_PREFIX/$DEVICE_ID); do ((a++)); done; echo $X)"

export USERNAME="v4l2user"
export PASSWORD="Cr33p1ngD34th"

declare -ig WIDTH=352
declare -ig HEIGHT=240

export TEMP="v4l2rtspserver";	export RTSP_BIN=$(GET_BIN)
unset TEMP

declare -ag OPTION_ARRAY=();
declare -ag ADDITIONAL_ARRAY=();

declare -ig OPTION_ARRAY_LEN=${#OPTION_ARRAY[@]}
declare -ig ADDITIONAL_ARRAY_LEN=${#ADDITIONAL_ARRAY[@]}

declare -ig BOL_DAEMON=$FALSE
declare -ig STOP_VAL=$SUCCESS
declare -ig START_VAL=$SUCCESS

function ASSEMBLE_ARRAY()
{
  OPTION_ARRAY=("-U $USERNAME:$PASSWORD" "-W $WIDTH" "-H $HEIGHT");
  for DATA in ${ADDITIONAL_ARRAY[@]} "$V4L_PREFIX/$DEVICE_ID"; do
    OPTION_ARRAY_LEN=${#OPTION_ARRAY[@]}
    OPTION_ARRAY[$((OPTION_ARRAY_LEN))]="$DATA"
  done
  return $SUCCESS
};

# Make sure all needed binaries exist and are defined
if [ ${#CHMOD_BIN}	-eq 0 ]; then echo -e "Error! Binary chmod not found!";		exit $FAILURE;	fi
#if [ ${#DAEMON_BIN}	-eq 0 ]; then echo -e "Error! Binary daemon not found!";	exit $FAILURE;	fi
if [ ${#PGREP_BIN}	-eq 0 ]; then echo -e "Error! Binary pgrep not found!";		exit $FAILURE;	fi
if [ ${#RTSP_BIN}	-eq 0 ]; then echo -e "Error! Binary v4l2rtspserver not found!"	exit $FAILURE;	fi

function DO_START()
{
  declare -i RUNCTION_RETVAL=$FAILURE
  export RUN_SCRIPT="$TMP_PREFIX/stream.sh"
  export SCRIPT_MASK='0700'
  export RTSP_OPTIONS=${OPTION_ARRAY[@]}
  export OUTPUT="/dev/null"
  echo -e '#!/bin/sh' >$RUN_SCRIPT
  if [ $BOL_DEBUG -eq $TRUE ]; then OUTPUT="/dev/stdout"; fi
  if [ $BOL_VERBOSE -eq $TRUE ]; then SHOW_DATE_TIME; echo -e $CLB"[Info] "$CLG"Executing: "$CY"$RTSP_BIN $RTSP_OPTIONS" '>'"$OUTPUT"$CN; fi
  echo -e "$RTSP_BIN $RTSP_OPTIONS >$OUTPUT" >>$RUN_SCRIPT
  $CHMOD_BIN "$SCRIPT_MASK" "$RUN_SCRIPT"
  if [ $BOL_DAEMON -eq $TRUE ]; then
    export COMMAND="$DAEMON_BIN"
    export OPTIONS="--unsafe --command=$RUN_SCRIPT"
  else
    export COMMAND="$RUN_SCRIPT"
    unset OPTIONS
  fi
  printf "%b" $CC; $COMMAND $OPTIONS >$OUTPUT
  FUNCTION_RETVAL=$?
  printf "%b" $CN
  export RETVAL=$FUNCTION_RETVAL
  export COMMAND=$RTSP_BIN
  if [ $BOL_VERBOSE -eq $TRUE ]; then SHOW_DATE_TIME; LOG_RESULTS; echo -e $CN; fi
  return $FUNCTION_RETVAL
};

function DO_STOP()
{
  declare -i FUNCTION_RETVAL=$SUCCESS
  declare -i RTSP_BIN_LEN=${#RTSP_BIN}
  declare -i RTSP_BIN_WORD_LEN=$((RTSP_BIN_LEN-14))
  export RTSP_TASK=${RTSP_BIN:$((RTSP_BIN_WORD_LEN)):$((RTSP_BIN_LEN))}
  $PGREP_BIN $RTSP_TASK >/dev/null 2>/dev/null
  if [ $? -eq $SUCCESS ]; then killall $RTSP_TASK; FUNCTION_RETVAL=$?; fi
  return $FUNCTION_RETVAL
};

for i in "$@"
do
case $i in
      'start')
        export BOL_START=$TRUE
	export BOL_STOP=$FALSE
        ;;
      'stop')
	export BOL_START=$FALSE
	export BOL_STOP=$TRUE
	;;
      'restart')
	export BOL_STOP=$TRUE
	export BOL_START=$TRUE
	;;
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
	export VERBOSE="--verbose"
        export BOL_VERBOSE=$TRUE
	export BOL_LOG_RESULTS=$TRUE
        ;;
'-q' | '--quiet')
	export VERBOSE=""
	export BOL_VERBOSE=$FALSE
	export BOL_LOG_RESULTS=$FALSE
	;;
'-t' | '--test')
	export BOL_TEST=$TRUE
	export DAEMON_BIN="$TRUE_BIN"
	export RTSP_BIN="$TRUE_BIN"
	;;
'--daemon')
        export BOL_DAEMON=$TRUE
        ;;
'--enable-root')
	export BOL_ENABLE_ROOT=$TRUE
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
	SHOW_DATE_TIME; echo -e "$RUN_CMD\tVersion: $VERSION\nAppended: $i to encoder options\n"
	;;
esac
done

if [ $BOL_COLOR -eq $TRUE ]; then INIT_COLOR_SHORTHAND; fi
if [ $BOL_START -eq $FALSE ] && [ $BOL_STOP -eq $FALSE ]; then BOL_HELP=$TRUE; fi
if [ $BOL_HELP -eq $TRUE ]; then DO_HELP; fi

REQUIRE_ROOT_USER
ASSEMBLE_ARRAY

ls $DEVICE_NAME 2>/dev/null >/dev/null
if [ $? -ne $SUCCESS ]; then echo -e "Error! $V4L_PREFIX/$DEVICE_ID ($DEVICE_NAME) does not exist!"; exit $FAILURE; fi

if [ $BOL_STOP -eq $TRUE ]; then DO_STOP; STOP_VAL=$?; fi
if [ $BOL_START -eq $TRUE ]; then DO_START; START_VAL=$?; fi

export RETVAL=$((STOP_VAL+START_VAL))
exit $RETVAL
