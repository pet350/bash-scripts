#!/bin/bash
# Shell Script By: Peter Talbott

# Source function library.
LSB_FUNCTIONS="/lib/lsb/init-functions"

if [ -f /usr/local/scripts/include/*.sh ] && [ -f $LSB_FUNCTIONS ]; then
  for INCLUDE_FILE in $LSB_FUNCTIONS $(ls -1 /usr/local/scripts/include/*.sh); do
    . $INCLUDE_FILE
  done
else
  echo -e "Error! Missing source files!"
  exit 1
fi

# Define Command being Executed and its Version
export RUN_CMD="$(basename $0)"
export VERSION="0.2"

export DEVICE_ID="usb-ARKMICRO_USB2.0_PC_CAMERA-video-index0"
export V4L_PREFIX="/dev/v4l/by-id"

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

function ASSEMBLE_ARRAY()
{
  OPTION_ARRAY=("-U $USERNAME:$PASSWORD" "-W $WIDTH" "-H $HEIGHT");
  for DATA in ${ADDITIONAL_ARRAY[@]} "$V4L_PREFIX/$DEVICE_ID"; do
    OPTION_ARRAY_LEN=${#OPTION_ARRAY[@]}
    OPTION_ARRAY[$((OPTION_ARRAY_LEN))]="$DATA"
  done
  return $SUCCESS
};

function DO_START()
{
  RTSP_OPTIONS=${OPTION_ARRAY[@]}
  if [ $BOL_VERBOSE -eq $TRUE ]; then 
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
	export DAEMON_BIN="$TEST_BIN"
	export RTSP_BIN="$TEST_BIN"
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

CHECK_ROOT_USER
ASSEMBLE_ARRAY

echo -e "$RTSP_BIN ${OPTION_ARRAY[@]} \n"
$RTSP_BIN ${OPTION_ARRAY[@]}
