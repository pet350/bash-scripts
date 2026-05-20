#!/bin/bash
if [ ${#TRUE}		-eq 0 ]; then declare -i TRUE=1;						fi
if [ ${#FALSE}		-eq 0 ]; then declare -i FALSE=0;						fi
if [ ${#UNSET_TARGET}	-eq 0 ]; then declare -i UNSET_TARGET=$FALSE;					fi
if [ ${#TARGET_HOST}	-eq 0 ]; then export TARGET_HOST="lxc.gigaware.lan"; export UNSET_TARGET=$TRUE;	fi


if [ "$(/bin/hostname --fqdn)" == "$TARGET_HOST" ] && [ $(id -u) -eq 0 ]; then
  /bin/ln -sf $VERBOSE /lib64/libvirt-admin.so.0.6006.0	/lib64/libvirt-admin.so.0
  /bin/ln -sf $VERBOSE /lib64/libvirt-lxc.so.0.6006.0	/lib64/libvirt-lxc.so.0
  /bin/ln -sf $VERBOSE /lib64/libvirt-qemu.so.0.6006.0	/lib64/libvirt-qemu.so.0
  /bin/ln -sf $VERBOSE /lib64/libvirt.so.0.6006.0	/lib64/libvirt.so.0
fi

if [ $UNSET_TARGET	-eq $TRUE ]; then unset TARGET_HOST;						fi
unset UNSET_TARGET

