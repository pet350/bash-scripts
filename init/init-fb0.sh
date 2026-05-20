#! /bin/bash
### BEGIN INIT INFO
# Provides:          sets the FrameBuffer when the module is loaded
# Required-Start:    $syslog
# Required-Stop:
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Set framebuffer resolution
# Description:       Set framebuffer resolution
### END INIT INFO
# chkconfig: 2345 08 08

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

export RUN_CMD="$(basename $0)"

if [ $# -eq 0 ]
  then
    echo "Usage: $RUN_CMD { start  } --help"
    exit 1
fi

_bin_prefix="/sbin"
_prog="fbset"
_res="1280x1024-60"
_depth="-depth"
_depth_val="24"
_module="atyfb"
_prog_opt="$_res $_depth $_depth_val --all"

declare -ig _BOL_START=0
declare -ig _BOL_STOP=0
declare -ig _BOL_LOAD_MODULE=0
declare -ig _BOL_VERBOSE=0
declare -ig _VAR_LOADED=0
declare -ig _VAR_UNKNOWN=0

function DISPLAY_DETAILS()
{
  printf "%-11s = %-9s\n" "_bin_prefix" "$_bin_prefix"
  printf "%-11s = %-9s\n" "_prog" "$_prog"
  printf "%-11s = %-9s\n" "_res" "$_res"
  printf "%-11s = %-9s\n" "_depth" "$_depth"
  printf "%-11s = %-9s\n" "_depth_val" "$_depth_val"
  printf "%-11s = %-9s\n" "_module" "$_module"
  printf "%-11s = %-9s\n" "_prog_opt" "$_prog_opt"
  return 0
};

function LOAD_MODULES()
{
  modprobe $_module
  while [  $_VAR_LOADED -lt 1 ]; do
    _VAR_LOADED="$(lsmod | grep $_module | wc -l)"
    if [ $_BOL_VERBOSE -eq 1 ]; then printf "%-9s = %-9s\n" "_VAR_LOADED" "$_VAR_LOADED"; fi
    if [ $_VAR_LOADED -eq 0 ]; then sleep 1; fi
  done
  return $_VAR_LOADED
}

function do_START()
{
  if [ $_BOL_LOAD_MODULE -eq 1 ]; then LOAD_MODULES; fi
  $_bin_prefix/$_prog $_prog_opt
  return $?
};

for i in "$@"
do
case $i in
'start')
	export _BOL_START=1
	;;
'-v' | '--verbose')
	export _BOL_VERBOSE=1
	;;
'--load-module')
	export _BOL_LOAD_MODULE=1
	;;
'--hi-res' | '--high-res')
	export _res="1280x1024-60"
	;;
'--normal-res' | '--med-res' | '--medium-res')
	export _res="1024x768-60"
	;;
'--low-res')
	export _res="800X600-60"
	;;
'--hi-depth' | '--high-depth')
	export _depth_val="32"
	;;
'--normal-depth' | '--med-depth' | '--medium-depth')
	export _depth_val="24"
	;;
'--low-depth')
	export _depth_val="16"
	;;
*)
	(( _VAR_UNKNOWN++ ))
        ;;
esac
done

_prog_opt="$_res $_depth $_depth_val --all"
if [ $_BOL_VERBOSE -eq 1 ]; then DISPLAY_DETAILS; fi

if [ $_BOL_START -eq 1 ]; then
	log_daemon_msg "Starting $RUNCMD"
	do_START
	RETVAL=$?
else
	RETVAL=1
fi

if [ $_BOL_VERBOSE -eq 1 ]; then
	echo "Return Value = $RETVAL"
fi

exit $RETVAL
