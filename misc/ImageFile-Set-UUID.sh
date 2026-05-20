#!/bin/bash

declare -ig SUCCESS=0
declare -ig FAILURE=1

UUID=$(uuidgen)

if [ ! -f $1 ]; then
  echo "File $1 Does Not Exist!"
  exit $FAILURE
fi


