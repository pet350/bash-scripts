#!/bin/sh

# Set Arguments
_QUIRKS_OPT="quirks=640"
_TRACE_OPT="trace=0x408"
_ARG_OPTS="$_QUIRKS_OPT $_TRACE_OPT $1 $2 $3 $4 $5 $6 $7 $8"

# Get UVCVIDEO URB Error Count
_UVC_ERROR_COUNT=$(dmesg | grep "uvcvideo: Failed to submit URB" | wc -l)
echo Current UVCVIDEO URB Error Count: $_UVC_ERROR_COUNT
echo

# Remove current Kernel Module
if lsmod|grep uvcvideo >/dev/null
   then
	echo UVCVIDEO module is currently loaded, unloading first
	rmmod uvcvideo
	sleep 1
	echo Done Unloading Module
   else
	echo UVCVIDEO module is not currently loaded
fi
echo

# Install Module with Argument Options
echo installing UVCVIDEO module with the following: $_ARG_OPTS
modprobe uvcvideo $_ARG_OPTS

# Wait some more! LOL!
sleep 8
export UVC_ERROR_COUNT=$_UVC_ERROR_COUNT
export _UVC_ERROR_COUNT
echo Done!
# Done
