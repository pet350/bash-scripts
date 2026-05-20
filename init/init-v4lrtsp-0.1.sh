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
export VERSION="0.1"

export DEVICE_ID="usb-ARKMICRO_USB2.0_PC_CAMERA-video-index0"
export V4L_PREFIX="/dev/v4l/by-id"

export USERNAME="v4l2user"
export PASSWORD="Cr33p1ngD34th"

declare -ig WIDTH=352
declare -ig HEIGHT=240

export TEMP="v4l2rtspserver";	export RTSP_BIN=$(GET_BIN)
unset TEMP

declare OPTION_ARRAY=("-U $USERNAME:$PASSWORD" "-W $WIDTH" "-H $HEIGHT" "$V4L_PREFIX/$DEVICE_ID");

echo -e "$RTSP_BIN ${OPTION_ARRAY[@]} \n"
$RTSP_BIN ${OPTION_ARRAY[@]}
