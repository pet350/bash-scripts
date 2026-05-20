#!/bin/bash
# Simple Definitions I Use All The Time
# By: Peter Talbott; February 28th 2019

# Define Current Version
export Standard_Definitions_Version=0.1

# Define TRUE/FALSE
declare -ig TRUE=1
declare -ig FALSE=0

# Define Standard Return Values
declare -ig SUCCESS=0
declare -ig FAILURE=1
declare -ig CONDITION_NOT_MET=255

# Define Aliases
alias lh='ls -lh'
alias ping='ping -c 4'
alias md='mkdir -p'
alias rd='rmdir'

# Define Misc String Values
export KERNEL=$(/bin/uname -r)

if [ -d /usr/local/scripts/source.d ]; then
  for DATA in $(ls -1 /usr/local/scripts/source.d); do
    source /usr/local/scripts/source.d/$DATA
  done
fi

if [ $initTimeExists -eq $TRUE ]; then
  initialize_time_date
fi

if [ $GetPathExists -eq $TRUE ]; then
  declare -a ADD_PATHS_ARRAY=('/bin' '/sbin' '/usr/bin' '/usr/sbin' '/usr/local/bin' '/usr/local/sbin' '/usr/local/scripts');
  for TEMP in ${ADD_PATHS_ARRAY[@]}; do
    ## Add Elements of ADD_PATHS_ARRAY[@] to $PATH if their not Already there
    export TEMP="$TEMP"
    setPATH
  done
fi

export BOOLEAN=
export TEMP_DATA=
export TEMP=
export GetPathExists=

# Done!
