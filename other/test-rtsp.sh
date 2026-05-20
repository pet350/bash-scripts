#!/bin/bash


declare -ag INPUT_ARRAY=( \
	"rtsp://admin:maiden666@172.16.184.121:554/ch0_1.264" \
	"rtsp://admin:maiden666@172.16.184.122:554/ch0_1.264" \
	"rtsp://admin:maiden666@172.16.184.123:554/ch0_1.264" \
	"rtsp://admin:maiden666@172.16.184.124:554/ch0_1.264" );

declare -ag FILTER_ARRAY=( "nullsrc=size=640x480" "[base];" \
		"[0:v]" "setpts=PTS-STARTPTS,scale=320x240" "[upperleft];" \
		"[1:v]" "setpts=PTS-STARTPTS,scale=320x240" "[upperright];" \
		"[2:v]" "setpts=PTS-STARTPTS,scale=320x240" "[lowerleft];" \
		"[3:v]" "setpts=PTS-STARTPTS,scale=320x240" "[lowerright];" \
		"[base][upperleft]" "overlay=shortest=1" "[tmp1];" \
		"[tmp1][upperright]" "overlay=shortest=1:x=320" "[tmp2];" \
		"[tmp2][lowerleft]" "overlay=shortest=1:y=240" "[tmp3];" \
		"[tmp3][lowerright]" "overlay=shortest=1:x=320:y=240" );

 ffmpeg -i rtsp://appagent:streaming@cam02.gigaware.lan/axis-cgi/mjpg/video.cgi \
	-i rtsp://appagent:streaming@cam04.gigaware.lan/axis-cgi/mjpg/video.cgi \
	-i rtsp://v4l2user:Cr33p1ngD34th@bedroom-pc.gigaware.lan:8554/unicast \
	-filter_complex "nullsrc=size=640x480 [base]; \
	[0:v] setpts=PTS-STARTPTS, scale=320x240 [upperleft]; \
	[1:v] setpts=PTS-STARTPTS, scale=320x240 [upperright]; \
	[2:v] setpts=PTS-STARTPTS, scale=320x240 [lowerleft]; \
	[base][upperleft] overlay=shortest=1 [tmp1]; \
	[tmp1][upperright] overlay=shortest=1:x=320 [tmp2]; \
	[tmp2][lowerleft] overlay=shortest=1:y=240" \
	-an -c:v libx264 -f mpegts -listen 1 tcp://fc31-laptop.gigaware.lan:8888
# broken
#-f rtsp -rtsp_transport udp -listen rtsp://localhost:8888/live

# works
#  -f mpegts -listen 1 unix:/tmp/ffmpeg.socket

# works
#test.mp4
