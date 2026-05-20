#!/bin/bash
# Source Script for XEN Functions
# By: Peter Talbott
## XEN Scripts Version 0.2

# Define True/False
declare -ig TRUE=1
declare -ig FALSE=0

# Define Success/Fail
declare -ig SUCCESS=0
declare -ig FAIL=1

declare -ig BOL_XEN_RUNNING=$FALSE

# Make Sure $DEPENDANT_PACKAGE is Installed
export DEPENDANT_PACKAGE="xen-utils-common"
export XENDOMAINS_PREFIX="/var/lib/xen"
export XENDOMAINS_EXTENTION="libxl-json"

xl info 2>/dev/null
RETVAL=$?
TEST=$(dpkg-query -l | grep $DEPENDANT_PACKAGE)
if [ $? -ne $SUCCESS ]; then
    export BOL_XEN_RUNNING=$FALSE
    echo "Error - $DEPENDANT_PACKAGE is NOT installed on this system!"
    return $FAIL
elif [ $RETVAL -ne $SUCCESS ]; then
    export BOL_XEN_RUNNING=$FALSE
    echo "Error - Xen Hypervisor is NOT running!"
    return $FAIL
else
    # Continue On! Everything with XEN Checked out!
    export BOL_XEN_RUNNING=$TRUE
fi

# Define all Global XEN Arrays; Array populated by xl command
declare -Ag XEN_ARRAY=();		# Multi  Dimential Array XEN_ARRAY[x,y]
declare -ag XEN_NAME_ARRAY=();		# Single Dimential Array XEN_NAME_ARRAY[x]
declare -ag XEN_ID_ARRAY=();		# Single Dimential Array XEN_ID_ARRAY[x]
declare -ag XEN_MEM_ARRAY=();		# Single Dimential Array XEN_MEM_ARRAY[x]
declare -ag XEN_VCPU_ARRAY=();		# Single Dimential Array XEN_VCPU_ARRAY[x]
declare -ag XEN_STATE_ARRAY=();		# Single Dimential Array XEN_STATE_ARRAY[x]
declare -ag XEN_TIME_ARRAY=();		# Single Dimential Array XEN_TIME_ARRAY[x]

# Define all Global XEND Arrays; Array populated by "libxl-json" files
declare -ag XEND_NAME_ARRAY=();		# Single Dimential Array XEND_NAME_ARRAT[x]
declare -ag XEND_UUID_ARRAY=();		# Single Dimential Array XEND_UUID_ARRAY[x]
declare -Ag XEND_DISK_ARRAY=();		# Multi  Dimential Array XEND_DISK_ARRAY[x,y]
declare -Ag XEND_VDEV_ARRAY=();		# Multi  Dimential Array XEND_VDEV_ARRAY[x,y]

# Define all Global XEN Intergers
declare -ig XEN_REPORTED_DOMAIN_COUNT=$(xl list 2>/dev/null|wc -l)-1
declare -ig XEND_LIBXL_JSON_COUNT=$(find "$XENDOMAINS_PREFIX" -name "*.$XENDOMAINS_EXTENTION"|wc -l)

# Define all Global Booleans
declare -ig BOL_StoreXen=$FALSE
declare -ig BOL_StoreXenArray=$FALSE
declare -ig BOL_StoreXendUUID=$FALSE

function StoreXen()			# StoreXen will Populate All Single Dimential Arrays Defined Above
{
  declare -i PopulateArray=$FALSE
  declare -i Index=0			# Array Index
  declare -i Counter=-1			# Count 0 - 5 for each Domain [0 Name; 1 ID 2 MEM; 3 VCPU; 4 STATE; 5 TIME]
  declare -i RawCounter=-1		# Raw Counter from $(xl list) loop

  for DATA in $(xl list); do		# Loop Through $(xl list) and store each string value into $DATA
    (( RawCounter++ ))			# Incriment RawCounter by 1 each loop
    if [ $RawCounter -gt 5 ]; then	# Skip the "HEADER" output from "xl list"
	if [ $Counter -eq 5 ]; then	# See IF $Counter is >5
	    Counter=0			# Reset $Counter to 0 When it is >5
	    (( Index++ ))		# And Incriment $Index
	else				# Else IF $Counter is NOT >5
	    (( Counter++ ))		# Then Incriment $Counter by 1
	fi				# Done Checking Where $Counter is at
	PopulateArray=$TRUE		# $RawCounter IS Past the "HEADER" turn PopulateArray On!
    fi

    if [ $PopulateArray -eq $TRUE ]; then
	if [ $Counter -eq 0 ]; then
	    XEN_NAME_ARRAY[$((Index))]="$DATA"
	elif [ $Counter -eq 1 ]; then
	    XEN_ID_ARRAY[$((Index))]="$DATA"
	elif [ $Counter -eq 2 ]; then
	    XEN_MEM_ARRAY[$((Index))]="$DATA"
	elif [ $Counter -eq 3 ]; then
	    XEN_VCPU_ARRAY[$((Index))]="$DATA"
	elif [ $Counter -eq 4 ]; then
	    XEN_STATE_ARRAY[$((Index))]="$DATA"
	elif [ $Counter -eq 5 ]; then
	    XEN_TIME_ARRAY[$((Index))]="$DATA"
	else
	    echo "Error Counter should Never Equal $Counter!!"
	    exit $FAIL
	fi
    fi
  done					# Done with Loop Through $(xl list)
  declare -ig XEN_FOUND_DOMAIN_INDEX=$((Index))
  declare -ig XEN_FOUND_DOMAIN_COUNT=$((Index))+1
  declare -ig BOL_StoreXen=$TRUE
  return $SUCCESS
};


function StoreXenArray()
{
  if [ $BOL_StoreXen -eq $FALSE ]; then
    StoreXen
  fi
  for (( DOMAIN_INDEX=0; $((DOMAIN_INDEX)) <= $((XEN_FOUND_DOMAIN_INDEX)); DOMAIN_INDEX++ )); do
	XEN_ARRAY[ $((DOMAIN_INDEX)),0 ]="${XEN_NAME_ARRAY[$((DOMAIN_INDEX))]}"
	XEN_ARRAY[ $((DOMAIN_INDEX)),1 ]="${XEN_ID_ARRAY[$((DOMAIN_INDEX))]}"
	XEN_ARRAY[ $((DOMAIN_INDEX)),2 ]="${XEN_MEM_ARRAY[$((DOMAIN_INDEX))]}"
	XEN_ARRAY[ $((DOMAIN_INDEX)),3 ]="${XEN_VCPU_ARRAY[$((DOMAIN_INDEX))]}"
	XEN_ARRAY[ $((DOMAIN_INDEX)),4 ]="${XEN_STATE_ARRAY[$((DOMAIN_INDEX))]}"
	XEN_ARRAY[ $((DOMAIN_INDEX)),5 ]="${XEN_TIME_ARRAY[$((DOMAIN_INDEX))]}"
  done
  BOL_StoreXenArray=$TRUE
  return $SUCCESS
};

function StoreXendUUID()
{
  NAME_STRING='"name":'
  UUID_STRING='"uuid":'
  DISK_STRING='"pdev_path":'
  VDEV_STRING='"vdev":'

  declare -a TEMP_ARRAY=()
  declare -i FILE_INDEX=-1
  declare -i DISK_ID=-1
  declare -i VDEV_ID=-1

  for FILENAME in $(ls -1 --sort=time $XENDOMAINS_PREFIX/*.$XENDOMAINS_EXTENTION); do
     ((FILE_INDEX++))
     INDEX=-1
     DISK_ID=-1
     VDEV_ID=-1
     for TEMP_DATA in $(tr -d '\0' <$FILENAME); do
	((INDEX++))
	TEMP_ARRAY[$((INDEX))]=$TEMP_DATA
     done
     BOL_NAME=$FALSE
     BOL_UUID=$FALSE
     BOL_DISK=$FALSE
     BOL_VDEV=$FALSE
     for TEMP_DATA in ${TEMP_ARRAY[@]}; do
	if [ $BOL_NAME -eq $TRUE ]; then
	    XEND_NAME_ARRAY[$((FILE_INDEX))]=`echo $TEMP_DATA | sed 's/.\(.*\)/\1/' | sed 's/\(.*\)./\1/' | sed 's/\(.*\)./\1/'`
	fi
	if [ $BOL_UUID -eq $TRUE ]; then
	    XEND_UUID_ARRAY[$((FILE_INDEX))]=`echo $TEMP_DATA | sed 's/.\(.*\)/\1/' | sed 's/\(.*\)./\1/' | sed 's/\(.*\)./\1/'`
	fi
	if [ $BOL_DISK -eq $TRUE ]; then
	    XEND_DISK_ARRAY[$((FILE_INDEX)),$((DISK_ID))]=`echo $TEMP_DATA | sed 's/.\(.*\)/\1/' | sed 's/\(.*\)./\1/' | sed 's/\(.*\)./\1/'`
	fi
	if [ $BOL_VDEV -eq $TRUE ]; then
	    XEND_VDEV_ARRAY[$((FILE_INDEX)),$((VDEV_ID))]=`echo $TEMP_DATA | sed 's/.\(.*\)/\1/' | sed 's/\(.*\)./\1/' | sed 's/\(.*\)./\1/'`
	fi

	if [ $TEMP_DATA == $NAME_STRING ]; then
	    BOL_NAME=$TRUE
	else
	    BOL_NAME=$FALSE
	fi
	if [ $TEMP_DATA == $UUID_STRING ]; then
	    BOL_UUID=$TRUE
	else
	    BOL_UUID=$FALSE
	fi
	if [ $TEMP_DATA == $DISK_STRING ]; then
	    BOL_DISK=$TRUE
	    ((DISK_ID++))
	else
	    BOL_DISK=$FALSE
	fi
	if [ $TEMP_DATA == $VDEV_STRING ]; then
	    BOL_VDEV=$TRUE
	    ((VDEV_ID++))
	else
	    BOL_VDEV=$FALSE
	fi
     done
  done
  BOL_StoreXendUUID=$TRUE
  return $SUCCESS
};
