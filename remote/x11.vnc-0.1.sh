#! /bin/sh
# Script to start x11vncserver to share currnet desktop
# Peter Talbott

# Make Sure We Connect To Local Display Manager
export DISPLAY=:0
XAUTHORITY=~/.Xauthority

# Define VNC Variable Options
UID=$(id -u)
USERNAME="$(id -u -n)"
TASK_NAME="x11vnc"
VNC_TCP_PORT=$(( 5900 + ((UID - 999))));
VNC_AUTH="-rfbauth /home/$USERNAME/.vnc/passwd"
#VNC_AUTH="-rfbauth /etc/vnc/passwd"
VNC_CACHE="-ncache 10"
VNC_BACKGROUND="-bg"
VNC_POPUP="-accept 'popup' -gone 'popup'"
VNC_PORT="-rfbport $VNC_TCP_PORT -avahi"
VNC_NOIPV6="-noipv6"
VNC_REOPEN="-reopen"
VNC_OVERLAY="-overlay"
VNC_GUI="-gui tray=minimal,iconfont=14x17"
VNC_FOREVER="-forever"
VNC_NOXDAMAGE="-noxdamage"
VNC_SHARED="-shared"
UNKNOWN_COUNT=0
WAIT_TIME=0
DO_NOT_EXIT=0

for i in "$@"
do
case $i in
'-w' | '--wait')
	WAIT_TIME=$((WAIT_TIME + 4))
	;;
'--no-exit')
	DO_NOT_EXIT=1
	;;
*)
	(( UNKNOWN_COUNT++ ))
	;;
esac
done


# Put Together Variables
VNC_OPTIONS="$VNC_AUTH $VNC_BACKGROUND $VNC_PORT $VNC_NOIPV6 $VNC_REOPEN"
VNC_OPTIONS=$VNC_OPTIONS" $VNC_GUI $VNC_FOREVER $VNC_NOXDAMAGE $VNC_SHARED"

if [ $((UID)) -lt 999 ]; then
	printf "Error: User ID must be equal to or greater than 1000\n"
	printf "Current ID:\t$UID\n"
	printf "Will Exit Now!\n"
	exit 0
fi

if ! pgrep -x "x11vnc" > /dev/null; then
	printf "x11vnc:\t\t\tNOT Running!\n"
	printf "Current User ID:\t$UID\n"
	printf "Current VNC TCP Port:\t$VNC_TCP_PORT\n\n"
	printf "x11vnc Options:\t\t$VNC_OPTIONS\n"
	if [ $WAIT_TIME -gt 0 ]; then
		printf "\nWait Time: $WAIT_TIME Seconds\n"
		sleep $WAIT_TIME
	fi
	printf "Do NOT Exit is: "
	if [ $DO_NOT_EXIT -eq 0 ]; then
		# Launch x11vnc and exit script
		printf "Disabled!\n"
		x11vnc $VNC_OPTIONS &
		RETVAL=$?
	else
		# Launch x11vnc and keep checking that it is running
		printf "Enabled!\n"
		x11vnc $VNC_OPTIONS -loop
		RETVAL=$? # Should NEVER Get here!
	fi
   else
        printf "x11vnc:\t\t\tIS Running!\n"
        printf "Current User ID:\t$UID\n"
        printf "Current VNC PID(s):\n"
	pgrep "x11vnc"
	echo
	RETVAL=1
fi
echo
exit $RETVAL
