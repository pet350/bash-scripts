#!/bin/bash

export RUN_CMD="$(basename $0)"
_VER=0.1

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
        BOL_START=$FALSE
        BOL_STOP=$FALSE
	#do_HELP
        RETVAL=1
fi

if [ $VAR_UNKNOWN -gt 0 ]; then
	BOL_RUN=$FALSE
	RETVAL=$VAR_UNKNOWN
fi

if [ $BOL_RUN -eq $TRUE ]; then
	CheckDomainXL
	GetDeviceName
	PauseRunningDomains
	StartImage
	UnPauseRunningDomains
	RETVAL=$SUCCESS
fi
