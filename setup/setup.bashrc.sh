#!/bin/bash

declare -ig SUCCESS=0
declare -ig FAILURE=1

declare -ag SETUP_ARRAY=();

if [ ! -f ./CheckSYMLINKS.sh ]; then
  echo "Error! Could not find CheckSYMLINKS.sh"
  exit $FAILURE
fi

source ./CheckSYMLINKS.sh

function getSETUP_ARRAY()
{
  declare -i INDEX=-1
  for DATA in $(ls -1 /home); do
    if [ $DATA != "lost+found" ]; then
	((INDEX++))
	SETUP_ARRAY[$((INDEX))]="/home/$DATA"
    fi
  done
  ((INDEX++))
  SETUP_ARRAY[$((INDEX))]="/root"
  ((INDEX++))
  SETUP_ARRAY[$((INDEX))]="/etc/skel"
};

function doSETUP()
{
  getSETUP_ARRAY
  SETUP_PREFIX="/usr/local/xen"
  SETUP_FILE="$SETUP_PREFIX/.bashrc"
  getSETUP_ARRAY
  for DATA in ${SETUP_ARRAY[@]}; do
    cp -v "$SETUP_FILE" "$DATA"
    RETVAL=$?
  done
  return $RETVAL
}

if [ $(hostname) != 'xen' ]; then
  CheckAllSYMLINKS
fi


doSETUP



