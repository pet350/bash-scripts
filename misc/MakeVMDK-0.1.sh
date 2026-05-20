#!/bin/bash
# Script to create VMDK Files
# By: Peter Talbott

export RUN_CMD="$(basename $0)"
_VER=0.1

if [ $(id -u) -gt 0 ]; then
    echo -e "Must be ran as Root!!"
    exit 1
fi

export MEDIA_PREFIX="/usr/share/virtualbox/media"

# Define Global TRUE/FALSE Variables
declare -ig TRUE=1
declare -ig FALSE=0

# Define Global SUCCESS/FAILURE Variables
declare -ig SUCCESS=0
declare -ig FAILURE=1

declare -ag VG_ARRAY=("xen.storage" "xen.data" "xen.host" "xen.backup");

for VOL_GRP in ${VG_ARRAY[@]}; do
  for LOGIC_VOL in $(ls -1 /dev/$VOL_GRP); do
    echo -e "rawdisk: /dev/$VOL_GRP/$LOGIC_VOL"
    echo -e "filename $MEDIA_PREFIX/$VOL_GRP-$LOGIC_VOL.vmdk"
    VBoxManage internalcommands createrawvmdk \
      -filename $MEDIA_PREFIX/$VOL_GRP-$LOGIC_VOL.vmdk \
      -rawdisk /dev/$VOL_GRP/$LOGIC_VOL
  done
done
exit $?

