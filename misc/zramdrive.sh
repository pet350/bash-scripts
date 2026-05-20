#!/bin/bash

declare -x CFG_FILE="/etc/zramdrive.conf"
if [ -f $CFG_FILE ]; then
    . $CFG_FILE
else
    echo -e "$CFG_FILE Does not exist!"
fi

if [ $(lsmod | grep xfs | wc -l) -eq 0 ]; then
    /sbin/modprobe xfs
fi

function START()
{
  if [ ! -d $MOUNT_POINT ]; then
    /bin/mkdir -p $MOUNT_POINT
  fi

  /sbin/zramctl --size=$SIZE $DEVICE
  /sbin/mkfs.xfs -L ${DRIVE_LABEL} ${DEVICE}
  /bin/mount ${DEVICE} ${MOUNT_POINT}
  return $?
};

function STOP()
{
  /bin/umount ${DEVICE}
  /sbin/zramctl --reset ${DEVICE}
  return $?
};

declare -i RETVAL

for OPTIONS in $@; do
    case ${OPTIONS,,} in
        'start')	START;		RETVAL=$?;;
        'stop')		STOP;		RETVAL=$?;;
        'restart')	STOP;		START;		RETVAL=$?;;
    esac
done

exit $RETVAL
