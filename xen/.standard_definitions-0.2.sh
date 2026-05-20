#!/bin/bash
# Simple Definitions I Use All The Time
# By: Peter Talbott; February 28th 2019, November 1st 2019
# Revamped! Split Up Into Small Individual Files Located in /usr/local/

# Define Current Version
export Standard_Definitions_Version=0.2

SOURCE_PATH="/usr/local/scripts/source.d"
SHELL_EXTENTION="sh"

if [ -d $SOURCE_PATH ]; then
  for DATA in $(ls $SOURCE_PATH/*.$SHELL_EXTENTION); do
    if [ ${#BOL_VERBOSE} -ne 0 ]; then
       if [ $BOL_VERBOSE -eq 1 ]; then echo -e "Loading Source file: $DATA"; fi
    fi
    source $DATA
  done
  unset DATA
fi

unset SOURCE_PATH
unset SHELL_EXTENTION

# Done!
