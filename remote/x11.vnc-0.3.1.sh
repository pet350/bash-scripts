#! /bin/bash
# Script to start x11vncserver to share currnet desktop
# Peter Talbott

# Current Version
VERSION=0.3.1

# Define SUCCESS and FAILURE
declare -ig SUCCESS=0
declare -ig FAILURE=1

# Define TRUE and FALSE
declare -ig TRUE=1
declare -ig FALSE=0

# Define UP and DOWN
declare -ig UP=1
declare -ig DOWN=0

declare -ig BOL_VERBOSE=$FALSE
declare -ig BOL_TEST=$FALSE
declare -ig DO_NOT_EXIT=$FALSE
declare -ig BOL_WEBSOCKIFY=$FALSE
declare -ig BOL_ROOT_CHECK=$TRUE

# Define String Variables
export RUN_CMD="$(basename $0)"
export PREFIX="/home/$(whoami)/.config/.Autostart.d"
export BIN_PREFIX="/bin"
export USR_PREFIX="/usr"

export X11VNC_BIN="$USR_PREFIX$BIN_PREFIX/x11vnc"

# Define Intiger Variables
declare -ig VAR_COUNT=0
declare -ig VAR_MIN_PORT=5900
declare -ig VAR_MAX_PORT=5925

# Make Sure We Connect To Local Display Manager
if [ ${#DISPLAY} -eq 0 ]; then export DISPLAY=:0; fi
if [ ${#XAUTHORITY} -eq 0 ]; then export XAUTHORITY=~/.Xauthority; fi

# Define VNC Variable Options
export USERNAME="$(id -u -n)"
export TASK_NAME="x11vnc"
export WEBSOCK_CERT="/etc/ssl/xen/novnc.pem"

declare -ig UNKNOWN_COUNT=0
declare -ig WAIT_TIME=5
declare -ig DO_NOT_EXIT=$FALSE

declare -ag VNC_OPT_ARRAY=("-rfbauth" "/home/$USERNAME/.vnc/passwd" "-accept yes:*"  "-gone yes:*" "-ncache" \
	"10" "-bg" "-noipv6" "-reopen" "-overlay" "-forever" "-noxdamage" "-shared" \
	"-gui" "tray=minimal,iconfont=14x17");
declare -ig TASK_COUNT=$(ps -ax | grep $TASK_NAME | wc -l)-1
declare -ig VNC_TCP_PORT=0

function GetNextPort()
{
  declare -i BOL_LOOP=$TRUE
  declare -i COUNT=0
  while [ $BOL_LOOP -eq $TRUE ]; do
    ((COUNT++))
    nmap $(hostname -f) --open -p $((VAR_MIN_PORT))-$((VAR_MAX_PORT)) | grep $((COUNT+5900)) >/dev/null
    if [ $? -ne $SUCCESS ]; then BOL_LOOP=$FALSE; fi
  done
  export VNC_TCP_PORT=$((COUNT+5900))
  if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Next Port:\t\t$VNC_TCP_PORT"; fi
  return $VNC_TCP_PORT
};

for i in "$@"
do
case $i in
'--no-root-check')
        export BOL_ROOT_CHECK=$FALSE
        ;;
'--with-websockify')
	export BOL_WEBSOCKIFY=$TRUE
	;;
'-t' | '--test')
	export X11VNC_BIN="$BIN_PREFIX/false"
	export BOL_TEST=$TRUE
	;;
'-v' | '--verbose')
        export BOL_VERBOSE=$TRUE
        ;;
-w=* | --wait=*)
        X="${i#*=}"
        WAIT_TIME=$((X))
        ;;
'-wl' | '--wait-longer')
        WAIT_TIME=$((WAIT_TIME + 4))
        ;;
'--no-exit')
        DO_NOT_EXIT=$TRUE
        ;;
*)
        (( UNKNOWN_COUNT++ ))
        ;;
esac
done

if [ $BOL_ROOT_CHECK -eq $TRUE ]; then
  # Check That ROOT Is Not Trying To Run This Script
  if [ $(id -u) -eq 0 ]; then
    echo -e "$RUN_CMD Version $VERSION\nError: Cannot be ran as ROOT user!"
    exit $FAILURE
  fi
fi

GetNextPort
VNC_PORT="-rfbport $VNC_TCP_PORT -avahi"
declare -ig WEB_SOCK_PORT=$(($VNC_TCP_PORT+10000))

VNC_OPTIONS="$VNC_PORT"
for TEMP in ${VNC_OPT_ARRAY[@]}; do
  VNC_OPTIONS="$VNC_OPTIONS $TEMP"
done

if [ $TASK_COUNT -eq 0 ]; then
	printf "x11vnc:\t\t\tNOT Running!\n"
	if [ $BOL_VERBOSE -eq $TRUE ]; then printf "Current User ID:\t$UID\n"; fi
	if [ $BOL_VERBOSE -eq $TRUE ]; then printf "Current VNC TCP Port:\t$VNC_TCP_PORT\n\n"; fi
	if [ $BOL_VERBOSE -eq $TRUE ]; then printf "x11vnc Options:\t\t$VNC_OPTIONS\n"; fi
	if [ $WAIT_TIME -gt 0 ]; then
		if [ $BOL_VERBOSE -eq $TRUE ]; then printf "\nWait Time: $WAIT_TIME Seconds\n"; fi
		sleep $WAIT_TIME
	fi
	printf "Do NOT Exit is: "
	if [ $DO_NOT_EXIT -eq $FALSE ]; then
		# Launch x11vnc and exit script
		printf "Disabled!\n"
		$X11VNC_BIN $VNC_OPTIONS &
		RETVAL=$?
		if [ $BOL_WEBSOCKIFY -eq $TRUE ]; then /usr/bin/websockify --daemon --ssl-only --web=/usr/share/novnc/ --cert=$WEBSOCK_CERT $(hostname -f):$((WEB_SOCK_PORT)) $(hostname -f):$((VNC_TCP_PORT)); fi
	else
		# Launch x11vnc and keep checking that it is running
		printf "Enabled!\n"
		$X11VNC_BIN $VNC_OPTIONS -loop
		RETVAL=$? # Should NEVER Get here!
	fi
else
        printf "x11vnc:\t\t\tIS Running!\n"
        if [ $BOL_VERBOSE -eq $TRUE ]; then printf "Current User ID:\t$UID\n"; fi
        if [ $BOL_VERBOSE -eq $TRUE ]; then printf "Current VNC PID(s):\n"; fi
	pgrep "x11vnc"
	echo
	RETVAL=$FAILURE
fi
echo
exit $RETVAL
