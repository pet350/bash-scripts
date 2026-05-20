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
export VERSION="0.2.5"

# Define Global String Variables
export HOST_FQDN=$(hostname --fqdn)
export FILTER_SWITCH="-filter_complex";
export CONFIG_FILE="$CFG_PREFIX/mosaic.cfg"
export TCP_FLAGS="?listen=1?tcp_nodelay=1?send_buffer_size=16384?recv_buffer_size=16348"

# Define Global String Variables IF Thier NOT Already Defined as an Environment Variable
if [ ${#STREAMING_PATH}		-eq 0 ]; then export STREAMING_PATH="/stream";						fi
if [ ${#VIDEO_BITRATE}		-eq 0 ]; then export VIDEO_BITRATE="900k";						fi
if [ ${#STREAM_PROTOCOl}	-eq 0 ]; then export STREAM_PROTOCOl="tcp";						fi
if [ ${#INPUT_FLAGS}		-eq 0 ]; then export INPUT_FLAGS="-err_detect aggressive -fflags discardcorrupt";	fi
if [ ${#STREAM_USER}		-eq 0 ]; then export STREAM_USER="admin";						fi
if [ ${#STREAM_1_USER}          -eq 0 ]; then export STREAM_1_USER="admin";                                             fi
if [ ${#STREAM_2_USER}          -eq 0 ]; then export STREAM_2_USER="admin";                                             fi
if [ ${#STREAM_3_USER}          -eq 0 ]; then export STREAM_3_USER="admin";                                             fi
if [ ${#STREAM_4_USER}          -eq 0 ]; then export STREAM_4_USER="admin";                                             fi
if [ ${#STREAM_PASS}		-eq 0 ]; then export STREAM_PASS="password";						fi
if [ ${#STREAM_1_PASS}          -eq 0 ]; then export STREAM_1_PASS="maiden666";                                      	fi
if [ ${#STREAM_2_PASS}          -eq 0 ]; then export STREAM_2_PASS="maiden666";                                      	fi
if [ ${#STREAM_3_PASS}          -eq 0 ]; then export STREAM_3_PASS="maiden666";                                      	fi
if [ ${#STREAM_4_PASS}          -eq 0 ]; then export STREAM_4_PASS="maiden666";                                      	fi
if [ ${#STREAM_1_ADDRESS}	-eq 0 ]; then export STREAM_1_ADDRESS="172.16.184.121";					fi
if [ ${#STREAM_2_ADDRESS}	-eq 0 ]; then export STREAM_2_ADDRESS="172.16.184.122"; 				fi
if [ ${#STREAM_3_ADDRESS}	-eq 0 ]; then export STREAM_3_ADDRESS="172.16.184.123"; 				fi
if [ ${#STREAM_4_ADDRESS}	-eq 0 ]; then export STREAM_4_ADDRESS="172.16.184.124"; 				fi

# Define Global Integer Variables IF Thier NOT Already Defined as an Environment Variable
if [ ${#STREAMING_PORT}		-eq 0 ]; then declare -ig STREAMING_PORT=8888;						fi
if [ ${#STREAM_1_PORT}		-eq 0 ]; then declare -ig STREAM_1_PORT=554;						fi
if [ ${#STREAM_2_PORT}          -eq 0 ]; then declare -ig STREAM_2_PORT=554;            				fi
if [ ${#STREAM_3_PORT}          -eq 0 ]; then declare -ig STREAM_3_PORT=554;            				fi
if [ ${#STREAM_4_PORT}          -eq 0 ]; then declare -ig STREAM_4_PORT=554;            				fi
if [ ${#TQ_SIZE}		-eq 0 ]; then declare -ig TQ_SIZE=1024;                         			fi
if [ ${#VAR_WAIT}		-eq 0 ]; then declare -ig VAR_WAIT=2;							fi
if [ ${#MAX_RESPAWN_COUNT}	-eq 0 ]; then declare -ig MAX_RESPAWN_COUNT=-1;						fi

# Define Global Integer Variables
declare -ig RESPAWN_COUNT=0
declare -ig RETVAL=$SUCCESS

# Define Global Boolean Variables
declare -ig BOL_QUIET=$FALSE
declare -ig BOL_RESPAWN=$TRUE
declare -ig BOL_RUN=$TRUE

# Make sure all needed binaries exist and are defined
if [ ${#SLEEP_BIN}	-eq 0 ]; then echo -e "Error! Binary sleep not found!";		exit $FAILURE;	fi
if [ ${#PGREP_BIN}	-eq 0 ]; then echo -e "Error! Binary pgrep not found!";		exit $FAILURE;	fi
if [ ${#FFMPEG_BIN}	-eq 0 ]; then echo -e "Error! Binary ffmpeg not found!";	exit $FAILURE;  fi

# Define Empty Global Arrays
declare -ag ADDITIONAL_ARRAY=();
declare -ag INPUT_ARRAY=();
declare -ag OPTION_ARRAY=();

# Load Values from Config File (if it exists)
if [ -f $CONFIG_FILE ]; then
  . $CONFIG_FILE
fi

function ADD_TCP_FLAGGS()
{
  case $STREAM_PROTOCOl in
    'tcp')
      export STREAMING_PATH="$STREAMING_PATH$TCP_FLAGS"
      ;;
  esac
  return $SUCCESS
};

# Function that actually carries out mosaic based on ffmpeg
function DO_MOSAIC()
{
  declare -i FUNCTION_RETURN=$SUCCESS

  if [ $BOL_VERBOSE -eq $TRUE ]; then
    SHOW_DATE_TIME
    echo -e $CLB"[Info] "$CLG"Executing: "$CY"$FFMPEG_BIN ${INPUT_ARRAY[@]} $FILTER_SWITCH $FILTER_OPT ${OPTION_ARRAY[@]}"$CN
  fi

  SHOW_DATE_TIME; printf "%b" $CC
  $FFMPEG_BIN ${INPUT_ARRAY[@]} $FILTER_SWITCH "$FILTER_OPT" ${OPTION_ARRAY[@]}
  FUNCTION_RETURN=$?
  printf "%b" $CN
  return $FUNCTION_RETURN
};

# Function Assembles Arrays for ffmpeg
function ASSEMBLE_ARRAY()
{
  export STREAM_AUTH="$STREAM_USER:$STREAM_PASS"
  export STREAM_1_AUTH="$STREAM_1_USER:$STREAM_1_PASS"
  export STREAM_2_AUTH="$STREAM_2_USER:$STREAM_2_PASS"
  export STREAM_3_AUTH="$STREAM_3_USER:$STREAM_3_PASS"
  export STREAM_4_AUTH="$STREAM_4_USER:$STREAM_4_PASS"

  declare -ag INPUT_ARRAY=( \
	"$INPUT_FLAGS" "-rtsp_transport" "tcp" "-thread_queue_size" "$((TQ_SIZE))" "-i" "rtsp://$STREAM_1_AUTH@$STREAM_1_ADDRESS:$((STREAM_1_PORT))/ch0_1.264" \
	"$INPUT_FLAGS" "-rtsp_transport" "tcp" "-thread_queue_size" "$((TQ_SIZE))" "-i" "rtsp://$STREAM_2_AUTH@$STREAM_2_ADDRESS:$((STREAM_2_PORT))/ch0_1.264" \
	"$INPUT_FLAGS" "-rtsp_transport" "tcp" "-thread_queue_size" "$((TQ_SIZE))" "-i" "rtsp://$STREAM_3_AUTH@$STREAM_3_ADDRESS:$((STREAM_3_PORT))/ch0_1.264" \
	"$INPUT_FLAGS" "-rtsp_transport" "tcp" "-thread_queue_size" "$((TQ_SIZE))" "-i" "rtsp://$STREAM_4_AUTH@$STREAM_4_ADDRESS:$((STREAM_4_PORT))/ch0_1.264" );

  declare -ag OPTION_ARRAY=( "${ADDITIONAL_ARRAY[@]}" "-an" "-c:v" "libx264" "-f" "mpegts" "-preset ultrafast" "-listen" "1" \
		"-tune" "zerolatency" "-b:v" "$VIDEO_BITRATE" "$STREAM_PROTOCOl://$HOST_FQDN:$((STREAMING_PORT))$STREAMING_PATH" );

  export FILTER_OPT="nullsrc=size=640x480 [base]; [0:v] setpts=PTS-STARTPTS, scale=320x240 [upperleft];	[1:v] setpts=PTS-STARTPTS, scale=320x240 [upperright]; [2:v] setpts=PTS-STARTPTS, scale=320x240 [lowerleft]; [3:v] setpts=PTS-STARTPTS, scale=320x240 [lowerright]; [base][upperleft] overlay=shortest=1 [tmp1]; [tmp1][upperright] overlay=shortest=1:x=320 [tmp2]; [tmp2][lowerleft] overlay=shortest=1:y=240 [tmp3]; [tmp3][lowerright] overlay=shortest=1:x=320:y=240"

  return $SUCCESS
};

for i in "$@"
do
case $i in
'-h' | '--help')
	export BOL_HELP=$TRUE
        export VERBOSE=""
        export BOL_DEBUG=$FALSE
        export BOL_VERBOSE=$FALSE
        export BOL_LOG_RESULTS=$FALSE
	;;
'-v' | '--verbose')
	export VERBOSE="--verbose"
        export BOL_VERBOSE=$TRUE
	export BOL_LOG_RESULTS=$TRUE
        ;;
'-q' | '--quiet')
	export BOL_QUIET=$TRUE
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
'--no-respawn')
	export BOL_RESPAWN=$FALSE
	;;
'--tcp')
	export STREAM_PROTOCOl="tcp"
	;;
'--udp')
	export STREAM_PROTOCOl="udp"
	;;
'--http')
	export STREAM_PROTOCOL="http"
	;;
*)
	ADDITIONAL_ARRAY_LEN=${#ADDITIONAL_ARRAY[@]}
	ADDITIONAL_ARRAY[$((ADDITIONAL_ARRAY_LEN))]="$i"
	SHOW_DATE_TIME; echo -e "$RUN_CMD\tVersion: $VERSION\nAppended: $i to encoder options\n"
	;;
esac
done

export COMMAND="$FFMPEG_BIN"
if [ $BOL_COLOR -eq $TRUE ]; then INIT_COLOR_SHORTHAND; fi
if [ $BOL_HELP -eq $TRUE ]; then DO_HELP; fi

REQUIRE_ROOT_USER
ADD_TCP_FLAGGS
ASSEMBLE_ARRAY

while [ $BOL_RUN -eq $TRUE ]; do
  ((RESPAWN_COUNT++))
  DO_MOSAIC
  export RETVAL=$?
  if [ $BOL_LOG_RESULTS -eq $TRUE ]; then SHOW_DATE_TIME; LOG_RESULTS; fi
  if [ $BOL_RESPAWN -eq $FALSE ] || [ $RESPAWN_COUNT -eq $MAX_RESPAWN_COUNT ]; then BOL_RUN=$FALSE; fi
  if [ $BOL_WAIT -eq $TRUE ]; then $SLEEP_BIN $VAR_WAIT; fi
done

if [ $BOL_LOG_RESULTS -eq $TRUE ]; then SHOW_DATE_TIME; LOG_RESULTS; fi
exit $RETVAL

## All Done!!!

