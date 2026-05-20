#!/bin/bash
# ru.sh - Remote Unlock
# Shell Script By: Peter Talbott

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

## Ver 0.2 Change log
# Changed default source prefix from /tmp/door to ~/.door
# Solves permission issues 6/19/2023

export RUN_CMD="$(basename $0)"
export VERSION="0.2"
export AUTHOR="Peter Talbott"
export MODIFIED="2023-04-06"

# Define a few more binary variables
for DATA in xl virsh egrep grep wc chown sleep cat wc find true; do
  export TEMP="$DATA"
  TEMP_BIN=$(GET_BIN)
  if [ $? -eq $SUCCESS ]; then
    export "${DATA^^}_BIN"="$TEMP_BIN"
  else
    echo -e "Missing required binary: $DATA"
    exit $FAILURE
  fi
  unset TEMP_BIN
  unset TEMP
done

declare -i COMDEF_VER_MSV=${COMDEF_VERSION%%.*}
declare -i COMDEF_VER_LSV=${COMDEF_VERSION##*.}
declare -x COMDEF_VER_MID=${COMDEF_VERSION%.*}
declare -i COMDEF_VER_MID=${COMDEF_VER_MID##*.}

declare -i MIN_MSV=0
declare -i MIN_MID=2
declare -i MIN_LSV=8

declare -i BOL_MIN=$FALSE

if [ $COMDEF_VER_MSV -gt $MIN_MSV ] || [ $COMDEF_VER_MSV -eq $MIN_MSV ]; then
    if [ $COMDEF_VER_MID -gt $MIN_MID ]  || [ $COMDEF_VER_MID -eq $MIN_MID ]; then
        if [ $COMDEF_VER_LSV -gt $MIN_LSV ] || [ $COMDEF_VER_LSV -eq $MIN_LSV ]; then
            declare -i BOL_MIN=$TRUE
        fi
    fi
fi
if [ $BOL_MIN -eq $FALSE ]; then
    echo -e "Common Definition script inlclude does not meet the minimum version requirement"
    echo -e "Minimum Required: $MIN_MSV.$MIN_MID.$MIN_LSV"
    echo -e "Current Version:  $COMDEF_VER_MSV.$COMDEF_VER_MID.$COMDEF_VER_LSV"
    exit $FAILURE
fi

declare -a VM_ARRAY=();
declare -A VCPU_ARRAY=();
declare -i VM_COUNT=${#VM_ARRAY[@]}

function GET_VM_ARRAY()
{
    declare -i VM_INDEX=-3;
    declare -i RETVAL=$FAILURE
    while IFS= read LINE; do
        ((VM_INDEX++))
        declare -i WORD_INDEX=-1
        for WORD in $LINE; do
            ((WORD_INDEX++))
            if [ $VM_INDEX -gt -1 ] && [ $WORD_INDEX -eq 1 ]; then
                VM_ARRAY[$((VM_INDEX))]=$WORD
                declare -i RETVAL=$SUCCESS
                if [ $BOL_VERBOSE -eq $TRUE ]; then INFO_FOUND_MESSAGE "Index: $VM_INDEX: Virtual Machine: $WORD";	fi
            fi
        done
    done < <($VIRSH_BIN list)
    declare -i VM_COUNT=${#VM_ARRAY[@]}
    return $RETVAL
};

function GET_TOTAL_VCPUS()
{
    declare VM_NAME=$1
    echo -e $($XL_BIN vcpu-list | $GREP_BIN $VM_NAME | $WC_BIN -l)
    return $?
};

function GET_VCPU_ARRAY()
{
    declare -i VM_INDEX=-1
    declare -i VCPU_INDEX=-1
    declare -i RETVAL=$FAILURE
    for VM in ${VM_ARRAY[@]}; do
        ((VM_INDEX++))
        declare -i VCPU_INDEX=0
        VCPU_ARRAY[$((VM_INDEX)),$((VCPU_INDEX))]=$(GET_TOTAL_VCPUS $VM)
        while IFS= read LINE; do
            ((VCPU_INDEX++))
            declare -i WORD_INDEX=-1
            for WORD in $LINE; do
                ((WORD_INDEX++))
                if [ $WORD_INDEX -eq 3 ]; then VCPU_ARRAY[$((VM_INDEX)),$((VCPU_INDEX))]=$WORD; fi
		declare -i RETVAL=$SUCCESS
            done
        done < <($XL_BIN vcpu-list | $GREP_BIN $VM)
    done
    return $RETVAL
};


function DIAPLAY_VCPUS()
{
    declare -i VM_INDEX=-1
    CP_TEXT
    printf "%-3s  " "VM#"
    printf "%-25s " "VM Name"
    while [ $VM_INDEX -lt 15 ]; do
        ((VM_INDEX++))
        printf "\t%-5s" "VCPU$VM_INDEX"
    done
    printf "\n"
    declare -i VM_INDEX=-1
    for VM in ${VM_ARRAY[@]}; do
        ((VM_INDEX++))
        declare -i VCPU_INDEX=0
	CC_TEXT;  printf "%-3s  " $((VM_INDEX+1))
        CLR_TEXT; printf "%-25s " $VM
        TOTAL_VCPUS="${VCPU_ARRAY[$((VM_INDEX)),$((VCPU_INDEX))]}"
        while [ $VCPU_INDEX -lt $TOTAL_VCPUS ]; do
            ((VCPU_INDEX++))
	    CY_TEXT; printf "\t%-5s" "${VCPU_ARRAY[$((VM_INDEX)),$((VCPU_INDEX))]}"
	done
        printf "\n"
    done
    return $SUCCESS
};


if [ $BOL_COLOR   -eq $TRUE     ]; then INIT_COLOR_SHORTHAND;                                           fi
GET_VM_ARRAY

while [ $TRUE -eq $TRUE ]; do
    GET_VCPU_ARRAY
    clear
    DIAPLAY_VCPUS
    $SLEEP_BIN 0.5
done
