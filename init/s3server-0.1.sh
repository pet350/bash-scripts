#! /bin/bash
### By: Peter Talbott

# Source function library.
LSB_FUNCTIONS="/lib/lsb/init-functions"
ls /usr/local/scripts/include/*.sh >/dev/null 2>/dev/null 3>/dev/null
if [ $? -eq 0 ] && [ -f $LSB_FUNCTIONS ]; then
  for INCLUDE_FILE in $LSB_FUNCTIONS $(ls -1 /usr/local/scripts/include/*.sh) $XEN_FUNCTIONS; do
    . $INCLUDE_FILE
  done
else
  echo -e "Error! Missing source files!"
  exit 1
fi

export RUN_CMD="$(basename $0)"
export VERSION="0.1"

if [ ${#WAIT_TIME} -eq 0 ]; then declare -ig WAIT_TIME=15;              fi
if [ ${#THRESHOLD} -eq 0 ]; then declare -ig THRESHOLD=300;             fi

export SYS_LOAD=$(GET_SYS_LOAD)
export SERVICE_NAME="s3server"
export EXT_OPT="${SERVICE_NAME^^}"

declare -ag OPTIONS_LIST=();
declare -ig OPTIONS_COUNT=${#OPTIONS_LIST[@]}

function WAIT_SYSLOAD()
{
  SYS_LOAD=$(GET_SYS_LOAD)
  while [ $((SYS_LOAD)) -gt $((THRESHOLD)) ]; do
    if [ $BOL_VERBOSE -eq $TRUE ]; then
      SHOW_DATE_TIME
      echo -e "Waiting $((WAIT_TIME)) seconds, for System Load $SYS_LOAD to drop below threshold $THRESHOLD!"
    fi
    $SLEEP_BIN $WAIT_TIME
    SYS_LOAD=$(GET_SYS_LOAD)
  done
  return $SUCCESS
};

function START_S3SERVER()
{
  declare -i FUNCTION_RETURN=$FAILURE
  export S3DATAPATH="/opt/temp/s3data"
  export S3METADATAPATH="/opt/temp/s3metadata"
  export ACCESS_KEY="ZMKey1"
  export SECRET_KEY="ZMSecreyKey1"
  export BUCKET="ZMBucket"
  export REMOTE_MANAGEMENT_DISABLE="false"

  $DOCKER_BIN start $SERVICE_NAME ${OPTIONS_LIST[@]}
  FUNCTION_RETURN=$?
  return $FUNCTION_RETURN
};

function STOP_S3SERVER()
{
  declare -i FUNCTION_RETURN=$FAILURE
  $DOCKER_BIN stop $SERVICE_NAME
  FUNCTION_RETURN=$?
  return $FUNCTION_RETURN
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
	;;
'-v' | '--verbose')
	export BOL_VERBOSE=$TRUE
	;;
'--no-wait')
	export BOL_WAIT=$FALSE
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
        WAIT_TIME=$((X))
        ;;
--threshold=*)
        X="${i#*=}"
        THRESHOLD=$((X))
        ;;
*)
	OPTIONS_COUNT=${#OPTIONS_LIST[@]}
        OPTIONS_LIST[$((OPTIONS_COUNT))]="$i"
	;;
esac
done

if [ $BOL_COLOR -eq $TRUE ]; then INIT_COLOR_SHORTHAND; fi
if [ $BOL_HELP -eq $TRUE ]; then DO_HELP; fi
REQUIRE_ROOT_USER

if [ $BOL_STOP -eq $TRUE ]; then
  SHOW_DATE_TIME; log_daemon_msg "Stopping $RUN_CMD"; printf "\n"
  STOP_S3SERVER
  RETVAL=$?
  SHOW_DATE_TIME; LOG_RESULTS
fi

if [ $BOL_START -eq $TRUE ]; then
  SHOW_DATE_TIME; log_daemon_msg "Starting $RUN_CMD"; printf "\n"
  if [ $BOL_WAIT -eq $TRUE ]; then WAIT_SYSLOAD; fi
  START_S3SERVER
  RETVAL=$?
  SHOW_DATE_TIME; LOG_RESULTS
fi

exit $RETVAL
