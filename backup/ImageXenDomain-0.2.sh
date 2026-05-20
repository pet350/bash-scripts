#!/bin/bash

export RUN_CMD="$(basename $0)"
_VER=0.2

if [ $(id -u) -gt 0 ]; then
    echo -e "Must be ran as Root!!"
    exit 1
fi

if [ $# -eq 0 ]
  then
    echo -e "$RUN_CMD Version $_VER\nMissing Required Parameters: $RUN_CMD --help for more information"
    exit 1
fi

# Source function library for storing XEN info
source /usr/local/src/xen-scripts.sh

export IMG_PREFIX="/opt/DiskImages"
export IMG_SUFFIX=".bz2"

# Define BOOLEAN Variables
declare -ig TRUE=1
declare -ig FALSE=0

declare -ig SUCCESS=0
declare -ig FAILURE=1

declare -ig BOL_RUN=$FALSE
declare -ig BOL_VERBOSE=$FALSE
declare -ig BOL_HELP=$FALSE
declare -ig BOL_STATUS=$FALSE
declare -ig BOL_TEST=$FALSE
declare -ig BOL_BACKGROUND=$FALSE
declare -ig BOL_PAUSE_DOMAINS=$TRUE
declare -ig BOL_UNPAUSE_DOMAINS=$TRUE

# Define Global Intefers
declare -ig VAR_UNKNOWN=0
declare -ig VAR_WAIT=1
declare -ig DOMAIN_INDEX=-1
declare -ig RETVAL=$FAILURE

declare -ag DOMAIN_ARRAY=();
declare -ag BOL_DOMAIN_ARRAY_XL_LIST=();
declare -ag DOMAIN_DEVICE_ARRAY=();

export OPT_STATUS="none"

function doDiskImage()
{
   if [ $BOL_STATUS -eq $TRUE ]; then
	export OPT_STATUS='progress'
   else
	export OPT_STATUS='none'
   fi
   if [ $BOL_TEST -eq $FALSE ]; then
	if [ $BOL_BACKGROUND -eq $FALSE ]; then
		dd "status=$OPT_STATUS" "if=$INFILE" | bzip2 >$OUTFILE
	else
		dd "status=$OPT_STATUS" "if=$INFILE" | bzip2 >$OUTFILE &
	fi
	RETVAL=$?
   else
	echo -e "\n\t\t**Test Mode**\n"
	RETVAL=$FAILURE
   fi
   return $RETVAL
};

function GetDeviceName()
{
   StoreXendUUID
   declare -i USER_DATA_INDEX=-1
   declare -i XL_DATA_INDEX=-1
   for USER_DATA in ${DOMAIN_ARRAY[@]}; do
        ((USER_DATA_INDEX++))
        XL_DATA_INDEX=0
        for XL_DATA in ${XEND_NAME_ARRAY[@]}; do
            ((XL_DATA_INDEX++))
            if [ $USER_DATA == $XL_DATA ]; then
                DOMAIN_DEVICE_ARRAY[$((USER_DATA_INDEX))]=${XEND_DISK_ARRAY[$((XL_DATA_INDEX)),0]}
            fi
        done
   done
   return $SUCCESS
};


function CheckDomainXL()
{
   StoreXen
   declare -i USER_DATA_INDEX=-1
   declare -i XL_DATA_INDEX=-1
   for USER_DATA in ${DOMAIN_ARRAY[@]}; do
	((USER_DATA_INDEX++))
	XL_DATA_INDEX=0
	BOL_DOMAIN_ARRAY_XL_LIST[$((USER_DATA_INDEX))]=$FALSE
   	for XL_DATA in ${XEN_NAME_ARRAY[@]}; do
	    ((XL_DATA_INDEX++))
	    if [ $USER_DATA == $XL_DATA ]; then
		BOL_DOMAIN_ARRAY_XL_LIST[$((USER_DATA_INDEX))]=$TRUE
	    fi
	done
   done
   return $SUCCESS
};

function PauseRunningDomains()
{
   declare -i USER_DATA_INDEX=-1
   for USER_DATA in ${DOMAIN_ARRAY[@]}; do
        ((USER_DATA_INDEX++))
	if [ ${BOL_DOMAIN_ARRAY_XL_LIST[$((USER_DATA_INDEX))]} -eq $TRUE ]; then
		if [ $BOL_VERBOSE -eq $TRUE ]; then
			echo -e "Pausing:\t$USER_DATA"
		fi
		/usr/sbin/xl pause $USER_DATA
	fi
   done
   if [ $BOL_VERBOSE -eq $TRUE ]; then
        echo -e ""
   fi
   return $SUCCESS
};

function UnPauseRunningDomains()
{
   declare -i USER_DATA_INDEX=-1
   if [ $BOL_VERBOSE -eq $TRUE ]; then
        echo -e ""
   fi
   for USER_DATA in ${DOMAIN_ARRAY[@]}; do
        ((USER_DATA_INDEX++))
        if [ ${BOL_DOMAIN_ARRAY_XL_LIST[$((USER_DATA_INDEX))]} -eq $TRUE ]; then
		if [ $BOL_VERBOSE -eq $TRUE ]; then
			echo -e "UnPausing:\t$USER_DATA"
		fi
                /usr/sbin/xl unpause $USER_DATA
        fi
   done
   return $SUCCESS
};

function StartImage()
{
   declare -i INDEX=-1
   for INFILE in ${DOMAIN_DEVICE_ARRAY[@]}; do
	NAME=${INFILE##*/}
	((INDEX++))
	OUTFILE="$IMG_PREFIX/$NAME$IMG_SUFFIX"
	if [ $BOL_VERBOSE -eq $TRUE ]; then
		echo -e "Domain:\t\t${DOMAIN_ARRAY[$((INDEX))]}"
		echo -e "InFile:\t\t$INFILE"
		echo -e "OutFile:\t$OUTFILE\n"
	fi
   doDiskImage
   done
};

function do_HELP()
{
	DOM_STRING='"Domain"'
	printf "%-15s %-8s %-3s %-16s\n" "$RUN_CMD" "Version: " "$_VER" "HELP! Section!"
	printf "%-10s\t\t%-20s\n\n" "Required:" "-d=$DOM_STRING | --domain=$DOM_STRING (Repeat As Needed)"
        printf "%-10s\t\t%-20s\n" "-h | --help" "Display This Message"
	printf "%-10s\t\t%-20s\n" "-t | --test" "Put in Test Mode (Does NOT Actually Create a Image FIle)"
	printf "%-10s\t%-20s\n" "-b | --background" 'Run in Background [Experimental]'
        printf "%-10s\t\t%-20s\n\n" "-v | --verbose" "Show Verbose Messages"
	printf "%-10s\t\t%-20s\n" "--status-on" "Turn ON Image Progress Status"
	printf "%-10s\t\t%-20s\n\n" "--status-off" "Turn OFF Image Progress Status (Default)"
        printf "%-10s\t\t%-20s\n" "--pause-on" "Pause a Running Domain Before Creating Image (Default)"
        printf "%-10s\t\t%-20s\n\n" "--pause-off" "Does NOT Pause a Running Domain Before Creating Image"
        printf "%-10s\t\t%-20s\n" "--unpause-on" "UnPause a Previous Running Domain After Creating Image (Default)"
        printf "%-10s\t\t%-20s\n" "--unpause-off" "Does NOT UnPause a Previous Running Domain After Creating Image"
	return $SUCCESS
};

for i in "$@"
do
case $i in
'-b' | '--background')
	export BOL_BACKGROUND=$TRUE
	;;
'-t' | '--test')
	export BOL_TEST=$TRUE
	;;
'--status-on')
	export BOL_STATUS=$TRUE
	;;
'--status-off')
	export BOL_STATUS=$FALSE
	;;
'--pause-on')
	export BOL_PAUSE_DOMAINS=$TRUE
	;;
'--pause-off')
	export BOL_PAUSE_DOMAINS=$FALSE
	;;
'--unpause-on')
	export BOL_UNPAUSE_DOMAINS=$TRUE
	;;
'--unpause-off')
	export BOL_UNPAUSE_DOMAINS=$FALSE
	;;
'-v' | '--verbose')
	export VERBOSE="--verbose"
        export BOL_VERBOSE=$TRUE
        ;;
'-h' | '--help')
	export BOL_HELP=$TRUE
	;;
-d=* | --domain=*)
	BOL_RUN=$TRUE
	((DOMAIN_INDEX++))
	DOMAIN_ARRAY[$((DOMAIN_INDEX))]="${i#*=}"
	;;
*)
        (( VAR_UNKNOWN++ ))
	echo -e "Unknown Parameter $i"
        ;;
esac
done

if [ $BOL_HELP -eq $TRUE ]; then
        BOL_RUN=$FALSE
	do_HELP
        RETVAL=$FAILURE
fi

if [ $VAR_UNKNOWN -gt 0 ]; then
	BOL_RUN=$FALSE
	RETVAL=$VAR_UNKNOWN
fi

if [ $BOL_RUN -eq $TRUE ]; then
	CheckDomainXL
	GetDeviceName
	if [ $BOL_PAUSE_DOMAINS -eq $TRUE ]; then
		PauseRunningDomains
	fi
	StartImage
	if [ $BOL_UNPAUSE_DOMAINS -eq $TRUE ]; then
		UnPauseRunningDomains
	fi
	RETVAL=$SUCCESS
fi
