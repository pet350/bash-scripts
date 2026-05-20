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

# Define a few more binary variables
for DATA in curl x0vncserver websockify egrep chown sleep find; do
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

export RUN_CMD="$(basename $0)"
export VERSION="0.1"
export AUTHOR="Peter Talbott"
export MODIFIED="2022-04-30"
declare -i SCRIPT_RETURN=$SUCCESS

for OPTIONS in $@; do
    case $OPTIONS in
        --bw)				      declare -i BOL_COLOR=$FALSE;			declare BOL_FORCE_COLOR=$FALSE;;
    esac
done

if [ ${#DISPLAY}		-eq 0 ]; then declare -x DISPLAY=":0";				fi
if [ ${#BOL_COLOR}		-eq 0 ]; then declare -i BOL_COLOR=$TRUE;			fi
if [ ${#BOL_FORCE_COLOR}	-eq 0 ]; then declare -i BOL_FORCE_COLOR=$TRUE;			fi
if [ ${#DAEMON}			-eq 0 ]; then declare -x DAEMON="--daemon";			fi
if [ ${#VERBOSE}		-eq 0 ]; then declare -x VERBOSE="--verbose";			fi
if [ ${#LOG_OPT}		-eq 0 ]; then declare -x LOG_OPT="--log-file";			fi
if [ ${#LOG_FILE}		-eq 0 ]; then declare -x LOG_FILE="$HOME/websock.log";		fi
if [ ${#WEB_OPT}		-eq 0 ]; then declare -x WEB_OPT="--web";			fi
if [ ${#WEB_DIR}		-eq 0 ]; then declare -x WEB_DIR="/usr/share/novnc";		fi
if [ ${#TARGET_IP}		-eq 0 ]; then declare -x TARGET_IP="172.16.184.3";		fi
if [ ${#TARGET_PORT}		-eq 0 ]; then declare -x TARGET_PORT="8888";			fi
if [ ${#SOURCE_IP}		-eq 0 ]; then declare -x SOURCE_IP="127.0.0.1";			fi
if [ ${#SOURCE_PORT}		-eq 0 ]; then declare -x SOURCE_PORT="25900";			fi
if [ ${#SLEEP_TIME}		-eq 0 ]; then declare -x SLEEP_TIME="1";			fi
if [ ${#PW_OPT}			-eq 0 ]; then declare -x PW_OPT="PasswordFile";			fi
if [ ${#PW_FILE}		-eq 0 ]; then declare -x PW_FILE="$HOME/.vnc/passwd";		fi
if [ ${#LOCAL_OPT}		-eq 0 ]; then declare -x LOCAL_OPT="";				fi
if [ ${#PORT_OPT}		-eq 0 ]; then declare -x PORT_OPT="-rfbport";			fi
if [ ${#SOCKET_OPT}		-eq 0 ]; then declare -x SOCKET_OPT="-rfbunixpath";		fi
if [ ${#SOCKET_PATH}		-eq 0 ]; then declare -x SOCKET_PATH="$HOME/rfb.socket";	fi
if [ $BOL_COLOR		    -eq $TRUE ]; then INIT_COLOR_SHORTHAND;				fi


INFO_EXEC_MESSAGE "$WEBSOCKIFY_BIN $DAEMON $VERBOSE $LOG_OPT=$LOG_FILE $WEB_OPT=$WEB_DIR $TARGET_IP:$TARGET_PORT $SOURCE_IP:$SOURCE_PORT"
$WEBSOCKIFY_BIN $DAEMON $VERBOSE $LOG_OPT=$LOG_FILE $WEB_OPT=$WEB_DIR $TARGET_IP:$TARGET_PORT $SOURCE_IP:$SOURCE_PORT
declare -i RETVAL=$?
COMMAND=$WEBSOCKIFY_BIN
INFO_DONE_MESSAGE "$COMMAND"

$SLEEP_BIN $SLEEP_TIME

INFO_EXEC_MESSAGE "$X0VNCSERVER_BIN $PW_OPT=$PW_FILE $LOCAL_OPT $PORT_OPT=$SOURCE_PORT $SOCKET_OPT=$SOCKET_PATH"
$X0VNCSERVER_BIN $PW_OPT=$PW_FILE $LOCAL_OPT $PORT_OPT=$SOURCE_PORT $SOCKET_OPT=$SOCKET_PATH
declare -i RETCAL=$?
COMMAND=$X0VNCSERVER_BIN
INFO_DONE_MESSAGE "$COMMAND"

exit $RETVAL
