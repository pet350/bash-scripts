#!/bin/bash
# Simple Script to start OpenXenManager

VERSION=0.1
PREFIX="/opt/xen/oxm"
BIN="openxenmanager"

declare -ig SUCCESS=0
declare -ig FAILURE=1

if [ ! -d $PREFIX ]; then
  echo -e "Error Directory $PREFIX Does Not Exist!"
  exit $FAILURE
fi

cd $PREFIX
./$BIN

exit $SUCCESS

