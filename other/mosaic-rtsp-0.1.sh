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

# Make sure all needed binaries exist and are defined
if [ ${#CHMOD_BIN}	-eq 0 ]; then echo -e "Error! Binary chmod not found!";		exit $FAILURE;	fi
if [ ${#PGREP_BIN}	-eq 0 ]; then echo -e "Error! Binary pgrep not found!";		exit $FAILURE;	fi
if [ ${#RTSP_BIN}	-eq 0 ]; then echo -e "Error! Binary v4l2rtspserver not found!"	exit $FAILURE;	fi
if [ ${#FFMPEG_BIN}	-eq 0 ]; then echo -e "Error! Binary ffmpeg not found!"		exit $FAILURE;  fi


declare -ag INPUT_ARRAY=( \
	"-rtsp_transport" "tcp" "-i" "rtsp://admin:maiden666@172.16.184.121:554/ch0_1.264" \
	"-rtsp_transport" "tcp" "-i" "rtsp://admin:maiden666@172.16.184.122:554/ch0_1.264" \
	"-rtsp_transport" "tcp" "-i" "rtsp://admin:maiden666@172.16.184.123:554/ch0_1.264" \
	"-rtsp_transport" "tcp" "-i" "rtsp://admin:maiden666@172.16.184.124:554/ch0_1.264" );

declare -ag OPTION_ARRAY=( "-an" "-c:v" "libx264" "-f" "mpegts" "-listen" "1" \
		"udp://fc31-laptop.gigaware.lan:8888/stream" );

export FILTER_OPT=" \
		nullsrc=size=640x480 [base];					\
		[0:v] setpts=PTS-STARTPTS, scale=320x240 [upperleft];		\
		[1:v] setpts=PTS-STARTPTS, scale=320x240 [upperright];		\
		[2:v] setpts=PTS-STARTPTS, scale=320x240 [lowerleft];		\
		[3:v] setpts=PTS-STARTPTS, scale=320x240 [lowerright];		\
		[base][upperleft] overlay=shortest=1 [tmp1];			\
		[tmp1][upperright] overlay=shortest=1:x=320 [tmp2];		\
		[tmp2][lowerleft] overlay=shortest=1:y=240 [tmp3];		\
		[tmp3][lowerright] overlay=shortest=1:x=320:y=240"

$FFMPEG_BIN ${INPUT_ARRAY[@]} -filter_complex "$FILTER_OPT" ${OPTION_ARRAY[@]}

# ffmpeg -i rtsp://appagent:streaming@cam02.gigaware.lan/axis-cgi/mjpg/video.cgi \
#	-i rtsp://appagent:streaming@cam04.gigaware.lan/axis-cgi/mjpg/video.cgi \
#	-i rtsp://v4l2user:Cr33p1ngD34th@bedroom-pc.gigaware.lan:8554/unicast \
#	-filter_complex "nullsrc=size=640x480 [base]; \
#	[0:v] setpts=PTS-STARTPTS, scale=320x240 [upperleft]; \
#	[1:v] setpts=PTS-STARTPTS, scale=320x240 [upperright]; \
#	[2:v] setpts=PTS-STARTPTS, scale=320x240 [lowerleft]; \
#	[base][upperleft] overlay=shortest=1 [tmp1]; \
#	[tmp1][upperright] overlay=shortest=1:x=320 [tmp2]; \
#	[tmp2][lowerleft] overlay=shortest=1:y=240" \
#	-an -c:v libx264 -f mpegts -listen 1 tcp://fc31-laptop.gigaware.lan:8888
# broken
#-f rtsp -rtsp_transport udp -listen rtsp://localhost:8888/live

# works
#  -f mpegts -listen 1 unix:/tmp/ffmpeg.socket

# works
#test.mp4
