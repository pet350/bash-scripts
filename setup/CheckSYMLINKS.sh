#!/bin/bash

declare -ig TRUE=1
declare -ig FALSE=0

declare -ig SUCCESS=0
declare -ig FAILURE=1
declare -ig CONDITION_NOT_MET=255

function CheckSymlinkSCRIPTS()
{
  if [ ! -d /usr/local/scripts ]; then
    if [ ! -d /nfs/xen.gigaware.lan/usr/local/scripts ]; then
        echo "/usr/local/scripts does not exist!"
        echo "Please Setup 'autofs' and 'init-resolv.sh' first!"
        echo "And create a symlink from from /nfs/xen.gigaware.lan/usr/local/scripts"
        RETVAL=$FAILURE
    else
        echo "Creating Symlink to '/usr/local/scripts'"
        cd /usr/local
        ln -s /nfs/xen.gigaware.lan/usr/local/scripts
        RETVAL=$SUCCESS
    fi
  else
        RETVAL=$CONDITION_NOT_MET
  fi
  return $RETVASL
};

function CheckSymlinkXEN()
{
  if [ ! -d /usr/local/xen ]; then
    cd /usr/local
    ln -s scripts/xen
    RETVAL=$SUCCESS
  else
    RETVAL=$CONDITION_NOT_MET
  fi
  return $RETVAL
};

function CheckSymlinkSRC()
{
  if [ ! -f /usr/local/src/CheckSYMLINKS.sh ]; then
    if [ -f /usr/local/src/* ]; then
	echo "There are currently files in '/usr/local/src', but not the ones expected!"
	RETVAL=$FAILURE
    elif [ -d /usr/local/src ]; then
	cd /usr/local
	rmdir /usr/local/src
	ln -s scripts/source src
	RETVAL=$SUCCESS
    else
	cd /usr/local
        ln -s scripts/source src
        RETVAL=$SUCCESS
    fi
  else
    RETVAL=$CONDITION_NOT_MET
  fi
  return $RETVAL
};

function CheckAllSYMLINKS()
{
  CheckSymlinkSCRIPTS
  CheckSymlinkXEN
  CheckSymlinkSRC
  return $?
};

