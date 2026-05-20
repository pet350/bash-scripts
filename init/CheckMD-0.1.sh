#! /bin/bash
### By: Peter Talbott 2019-06-01
### Add Missing Array Device if Need Be.

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
export VERSION="0.1"

declare -ig TRUE=1
declare -ig FALSE=0

declare -ig SUCCESS=0
declare -ig FAILURE=1

if [ $(id -u) -gt 0 ]; then
    echo -e "$RUN_CMD\tVersion: $VERSION\nMust be ran as root"
    exit $FAILURE
fi

declare -i SDE=$FALSE
declare -i SDD=$FALSE
declare -i BOL_LOOP=$TRUE

declare -i COUNT=0
declare -i LIMIT=10

export DISK_PATH="/dev/disk/by-id"
export MD_UUID="md-uuid-8ac808a3:37efe93b:9a0dd5a7:ae06a92b"

while [ $BOL_LOOP -eq $TRUE ]; do
  ((COUNT++))
  TEST=$(ls /dev/md*)
  if [ ${#TEST} -eq 0 ]; then
    sleep 10
    mdadm --assemble --scan
  else
    BOL_LOOP=$FALSE
  fi
  if [ $COUNT -eq $LIMIT ]; then BOL_LOOP=$FALSE; fi
done

sleep 90

while IFS= read LINE; do
  index=-1
  BOOL_MD=$FALSE
  for DATA in $LINE; do
    ((index++))
    if [ $index -eq 0 ]; then
      if [ "$DATA" == "md0" ]; then
        BOOL_MD=$TRUE
      else
        BOOL_MD=$FALSE
      fi
    fi
    if [ $BOOL_MD -eq $TRUE ]; then
      if [ "${DATA:0:4}" == "sdd1" ]; then SDD=$TRUE; fi
      if [ "${DATA:0:4}" == "sde1" ]; then SDE=$TRUE; fi
    fi
  done;
  if [ $BOOL_MD -eq $TRUE ]; then echo -e "/dev/sdd1:\t$SDD\n/dev/sde1:\t$SDE\n"; fi
done < <(cat /proc/mdstat)

if [ $SDD -eq $FALSE ]; then mdadm --re-add /dev/md0 /dev/sdd1; fi
if [ $SDE -eq $FALSE ]; then mdadm --re-add /dev/md0 /dev/sde1; fi

exit $?
