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

export HOST_FQDN=$(hostname --fqdn)
export STREAMING_PATH="/stream"
export VIDEO_BITRATE="900k"
export FILTER_SWITCH="-filter_complex"
export STREAM_PROTOCOl="tcp"

declare -ig STREAMING_PORT=8888
declare -ig RETVAL=$SUCCESS

# Make sure all needed binaries exist and are defined
if [ ${#CHMOD_BIN}	-eq 0 ]; then echo -e "Error! Binary chmod not found!";		exit $FAILURE;	fi
if [ ${#PGREP_BIN}	-eq 0 ]; then echo -e "Error! Binary pgrep not found!";		exit $FAILURE;	fi
if [ ${#RTSP_BIN}	-eq 0 ]; then echo -e "Error! Binary v4l2rtspserver not found!"	exit $FAILURE;	fi
if [ ${#FFMPEG_BIN}	-eq 0 ]; then echo -e "Error! Binary ffmpeg not found!"		exit $FAILURE;  fi


function ASSEMBLE_ARRAY()
{
  declare -ag INPUT_ARRAY=( \
	"-rtsp_transport" "tcp" "-i" "rtsp://admin:maiden666@172.16.184.121:554/ch0_1.264" \
	"-rtsp_transport" "tcp" "-i" "rtsp://admin:maiden666@172.16.184.122:554/ch0_1.264" \
	"-rtsp_transport" "tcp" "-i" "rtsp://admin:maiden666@172.16.184.123:554/ch0_1.264" \
	"-rtsp_transport" "tcp" "-i" "rtsp://admin:maiden666@172.16.184.124:554/ch0_1.264" );

  declare -ag OPTION_ARRAY=( "-an" "-c:v" "libx264" "-f" "mpegts" "-preset ultrafast" "-listen" "1" \
		"-tune" "zerolatency" "-b:v" "$VIDEO_BITRATE" "$STREAM_PROTOCOL://$HOST_FQDN:$((STREAMING_PORT))$STREAMING_PATH" );

  export FILTER_OPT="nullsrc=size=640x480 [base];					\
		[0:v] setpts=PTS-STARTPTS, scale=320x240 [upperleft];		\
		[1:v] setpts=PTS-STARTPTS, scale=320x240 [upperright];		\
		[2:v] setpts=PTS-STARTPTS, scale=320x240 [lowerleft];		\
		[3:v] setpts=PTS-STARTPTS, scale=320x240 [lowerright];		\
		[base][upperleft] overlay=shortest=1 [tmp1];			\
		[tmp1][upperright] overlay=shortest=1:x=320 [tmp2];		\
		[tmp2][lowerleft] overlay=shortest=1:y=240 [tmp3];		\
		[tmp3][lowerright] overlay=shortest=1:x=320:y=240"
  return $SUCCESS
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
	export FFMPEG_BIN="$TRUE_BIN"
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
#if [ $BOL_START -eq $FALSE ] && [ $BOL_STOP -eq $FALSE ]; then BOL_HELP=$TRUE; fi
if [ $BOL_HELP -eq $TRUE ]; then DO_HELP; fi

REQUIRE_ROOT_USER
ASSEMBLE_ARRAY

if [ $BOL_VERBOSE -eq $TRUE ]; then
  SHOW_DATE_TIME
  echo -e $CLB"[Info] "$CLG"Executing: "$CY"$FFMPEG_BIN ${INPUT_ARRAY[@]} $FILTER_SWITCH $FILTER_OPT ${OPTION_ARRAY[@]}"$CN
fi

SHOW_DATE_TIME; printf "%b" $CC
$FFMPEG_BIN ${INPUT_ARRAY[@]} $FILTER_SWITCH "$FILTER_OPT" ${OPTION_ARRAY[@]}
RETVAL=$?
printf "%b" $CN

exit $RETVAL