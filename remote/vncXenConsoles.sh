#! /bin/bash
# Simple Sicript to open a VNC Window for each XEN Guest Console

# Declare Charecter Strings
export _RUN_CMD="$(basename $0)"
export _SERVER_ADDRESS="172.16.184.2"
export _PATH_PREFIX="/home/$(whoami)/.vnc"
export _VNC_PASSWORD_FILE="xen-guests"

# Declare Intergers
declare -ig _MIN_PORT=5900
declare -ig _MAX_PORT=5920
declare -ig _VAR_UNKNOWN=0

# Declare Booleans
declare -ig _BOL_SHOW_PORTS=0
declare -ig _BOL_HELP=0
declare -ig _BOL_RUN_VNC=1
declare -ig _BOL_QUIET=0

# Declare Arrays
declare -ag _Open_VNC_Ports=()
declare -ag _ARRAY_UNKNOWN=()

function StoreVNC-Ports()
{
    _NMAP_INDEX=-1
    for _NMAP_OUT in $(nmap -p $((_MIN_PORT))-$((_MAX_PORT)) --open $_SERVER_ADDRESS | tail --lines=+7 | head --lines=-2); do
      TEMP=${_NMAP_OUT:0:3}
      if [ "$_NMAP_OUT" != "open" ]; then
	  if [ "$TEMP" != "vnc" ]; then
		(( _NMAP_INDEX++ ))
		_TCP_PORT=${_NMAP_OUT%/tcp}
		_Open_VNC_Ports[ $((_NMAP_INDEX)) ]=$((_TCP_PORT))
	  fi
      fi
    done
    export _NMAP_INDEX
    return $_NMAP_INDEX
};

function doShowPorts()
{
    for (( x=0; $((x)) <= $((_NMAP_INDEX)); x++ )); do
	echo -e "$x\t${_Open_VNC_Ports[ $((x)) ]}"
    done
};

function doVNCViewer()
{
    _PASSWORD="$_PATH_PREFIX/$_VNC_PASSWORD_FILE"
    for (( x=0; $((x)) <= $((_NMAP_INDEX)); x++ )); do
        TEMP="-passwd $_PASSWORD $_SERVER_ADDRESS::${_Open_VNC_Ports[ $((x)) ]}"
	if [ $_BOL_QUIET -eq 1 ]; then
		$TEMP="$TEMP"' >/dev/null'
	fi
	vncviewer $TEMP&
    done
};

# Time to parse command line arguments
# I use Booleans as much as possible here
for i in "$@"
do
case $i in
'-sp' | '--show-ports')
        export _BOL_SHOW_PORTS=1
	;;
'-q' | '--quiet')
	export _BOL_QUIET=1
	;;
*)
        _ARRAY_UNKNOWN[ $(( _VAR_UNKNOWN )) ]="$i"
        (( _VAR_UNKNOWN++ ))
        ;;
esac
done

# Run Function to store open VNC TCP Ports
StoreVNC-Ports

if [ $_BOL_SHOW_PORTS -eq 1 ]; then
	doShowPorts
fi

if [ $_BOL_RUN_VNC -eq 1 ]; then
	doVNCViewer
fi

