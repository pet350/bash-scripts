#! /bin/bash
### BEGIN INIT INFO
# Provides:          xen-pci-back-device configuration
# Required-Start:    $network $remote_fs $syslog
# Required-Stop:     $network $remote_fs $syslog
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Configure XEN pciback Kernel Module
# Description:       Configure XEN pciback Kernel Module
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
    echo "Usage: $RUN_CMD { start | stop | restart } --help"
    exit 1
fi

export _KERN_MOD="xen_pciback"
export _VERBOSE=""
export prog="Initialize $_KERN_MOD"
export _PCI_DEVICE_HEADER='0000:'
export _STRING_PASSTHROUGH="passthrough=1"

declare -ag _ARRAY_UNKNOWN=()
declare -ag _ARRAY_PCI_DEVICE=('01:01.0' '01:01.1' '01:01.2' '03:04.0' '03:04.1');

declare -ig _BOL_VERBOSE=0
declare -ig _BOL_START=0
declare -ig _BOL_STOP=0
declare -ig _BOL_HELP=0
declare -ig _BOL_TEST=0
declare -ig _BOL_LIST_DEVICES=0

# Define _VAR* as Integers
declare -ig _VAR_UNKNOWN=0
declare -ig _VAR_MOD_COUNT=$(lsmod | grep $_KERN_MOD | wc -l)
declare -ig _VAR_PCI_DEVICE_COUNT=${#_ARRAY_PCI_DEVICE[@]}
declare -ig _VAR_PCI_DEVICE_INDEX=$(( _VAR_PCI_DEVICE_COUNT -1))
declare -ig _VAR_KERN_MOD_COUNT=$( lsmod | grep $_KERN_MOD | wc -l )

function make_STRING_PASSTHROUGH()
{
   for (( _INDEX=0; $((_INDEX)) <= $((_VAR_PCI_DEVICE_INDEX)); _INDEX++ )); do
	_TEMP="$_TEMP""("
	_TEMP="$_TEMP""${_ARRAY_PCI_DEVICE[ $(( _INDEX )) ]}"
	_TEMP="$_TEMP"")"
   done
   _STRING_PASSTHROUGH="$_STRING_PASSTHROUGH hide=""$_TEMP"
   if [ $_BOL_VERBOSE -eq 1 ]; then
	echo -e "Passthough String: $_STRING_PASSTHROUGH\n"
   fi
   export _STRING_PASSTHROUGH
   return 0
}

function check_KERN_MOD()
{
	if [ $_BOL_VERBOSE -eq 1 ]; then
		printf "%-10s %-2s %-13s %-12s %-10s\n" "Currently" "$_VAR_KERN_MOD_COUNT" "Instannce(s) of" "$_KERN_MOD" "Loaded"
	fi
	if [ $_VAR_KERN_MOD_COUNT -eq 0 ]; then
		modprobe $_KERN_MOD $_STRING_PASSTHROUGH $_VERBOSE
		RETVAL=$?
	else
		RETVAL=$_VAR_KERN_MOD_COUNT
	fi
	return $RETVAL
}

function do_HELP()
{
	printf "%-25s \n" "$RUN_CMD: HELP! Section!"
	printf "%-10s\t\t%-20s\n" "Required:" "{ start | stop | restart }"
        printf "%-10s\t\t%-20s\n" "-h of --help" "Display This Message"
	printf "%-10s\t\t%-20s\n" "-t or --test" "Put in Test Mode"
	printf "%-10s\t\t%-20s\n" "-l or --list" "List PCI Device IDs"
	printf "%-10s\t\t%-20s\n" "-d or --display" "Same as -l or --list"
	printf "%-10s\t\t%-20s\n" "-v or --verbose" "Be Verbose"
	printf "%-10s\t\t%-20s\n" "-a or --append" "Add another PCI Device"
	printf "%-30s\n" "Require PCI devices in format is: <bus>:<slot>.<function>"
	return 1
};

function do_List_PCI_Devices()
{
  printf "List of all $_VAR_PCI_DEVICE_COUNT PCI Devices: "
  for (( _INDEX=0; $((_INDEX)) <= $((_VAR_PCI_DEVICE_INDEX)); _INDEX++ )); do
	printf "$_PCI_DEVICE_HEADER${_ARRAY_PCI_DEVICE[ $(( _INDEX )) ]} "
  done
  printf "\n\n"
};

function do_STOP()
{
  log_progress_msg "$prog"
  modprobe -r $_KERN_MOD $_VERBOSE

  RETVAL=$?
  [ $RETVAL = 0 ] && echo success
  [ $RETVAL != 0 ] && echo failure
  echo ""
  return $RETVAL
};

function do_START()
{
  log_progress_msg "$prog"
  for (( _INDEX=0; $((_INDEX)) <= $((_VAR_PCI_DEVICE_INDEX)); _INDEX++ )); do
	pcidev="$_PCI_DEVICE_HEADER${_ARRAY_PCI_DEVICE[ $(( _INDEX )) ]}"
	if [ -h /sys/bus/pci/devices/"$pcidev"/driver ]; then
	    if [ $_BOL_VERBOSE -eq 1 ]; then
		printf "%-10s %-9s %-5s %-6s\n" "Unbinding:" "$pcidev" "From:" "$(basename $(readlink /sys/bus/pci/devices/"$pcidev"/driver))"
	    fi
	    if [ $_BOL_TEST -eq 0 ]; then
		echo -n "$pcidev" > /sys/bus/pci/devices/"$pcidev"/driver/unbind
	    fi
	fi
	if [ $_BOL_VERBOSE -eq 1 ]; then
		printf "%-10s %-9s %-5s %-6s\n\n" "Binding:" "$pcidev" "To:" "$_KERN_MOD"
	fi
	if [ $_BOL_TEST -eq 0 ]; then
		echo -n "$pcidev" > /sys/bus/pci/drivers/pciback/new_slot
		echo -n "$pcidev" > /sys/bus/pci/drivers/pciback/bind
	fi
	RETVAL=$?
  done
  [ $RETVAL = 0 ] && echo success
  [ $RETVAL != 0 ] && echo failure
  echo ""
  return $RETVAL
};

# Time to parse command line arguments
# I use Booleans as much as possible here
for i in "$@"
do
case $i in
'-h' | '--help')
        export _BOL_HELP=1
        ;;
'start')
	export _BOL_START=1
	;;
'stop')
	export _BOL_STOP=1
	export _BOL_VERBOSE=1
	;;
'restart')
	export _BOL_STOP=1
	export _BOL_START=1
	;;
'-v' | '--verbose')
	export _BOL_VERBOSE=1
	export _VERBOSE="--verbose"
	;;
'-l' | '--list' | '-d' | '--display')
	export _BOL_LIST_DEVICES=1
	;;
'-t' | '--test')
	export _BOL_TEST=1
	;;
-a=* | --append=*)
	_TEMP="${i#*=}"
	((_VAR_PCI_DEVICE_COUNT++))
	_VAR_PCI_DEVICE_INDEX=$(( _VAR_PCI_DEVICE_COUNT -1))
	_ARRAY_PCI_DEVICE[ $(( _VAR_PCI_DEVICE_INDEX )) ]="$_TEMP"
	;;
*)
	_ARRAY_UNKNOWN[ $(( _VAR_UNKNOWN )) ]="$i"
	(( _VAR_UNKNOWN++ ))
        ;;
esac
done

# Make sure that IF help is set, all others are unset
if [ $_BOL_HELP -eq 1 ]; then
        _BOL_START=0
        _BOL_STOP=0
	_BOL_VERBOSE=0
	_BOL_LIST_DEVICES=0
	_VERBOSE=""
	do_HELP
	RETVAL=1
fi

# If there is an Unknown Parameter Do Not Try To RUN!
if [ $_VAR_UNKNOWN -ne 0 ]; then
        _BOL_START=0
        _BOL_STOP=0
        _BOL_VERBOSE=0
        _BOL_LIST_DEVICES=0
        _VERBOSE=""

	RETVAL=1
fi

make_STRING_PASSTHROUGH

if [ $_BOL_LIST_DEVICES -eq 1 ]; then
	do_List_PCI_Devices
	RETVAL=$?
fi

if [ $_BOL_STOP -eq 1 ]; then
	do_STOP
	RETVAL=$?
	sleep 2
fi

if [ $_BOL_START -eq 1 ]; then
	check_KERN_MOD
	do_START
	RETVAL=$?
fi

exit $RETVAL
