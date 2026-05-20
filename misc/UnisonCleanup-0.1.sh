#!/bin/bash
# Shell Script By: Peter Talbott

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

# Define Globak Variables
export SYS_LOAD=$(GET_SYS_LOAD)

# Define Global Arrays
declare -ag PID_ARRAY=();

# Define Variables ONLY If NOT Defined Already In Environment
if [ ${#THRESHOLD}	-eq 0 ]; then declare -ig THRESHOLD=800; fi

# Function will echo PIDs of UnisonServers.sh
function GET_UNI_SRV()
{
  LINE_INDEX=-1
  while IFS= read LINE; do
    ((LINE_INDEX++))
    WORD_INDEX=-1
    for WORD in $LINE; do
      ((WORD_INDEX++))
      if [ $WORD_INDEX -eq 0 ]; then echo $WORD; fi
    done
  done < <(ps -ax | grep /bin/sh | grep UnisonServers.sh)
};

# Function stores output of GET_UNI_SRV into PID_ARRAY
function STORE_PID_ARRAY()
{
  PID_INDEX=-1
  for PID_LIST in $(GET_UNI_SRV); do
    ((PID_INDEX++))
    PID_ARRAY[$((PID_INDEX))]=$PID_LIST
  done
};

# Function will kill every instance of 'unison'
function KILL_UNISON_LOOP()
{
  declare -i COUNT=0
  while [ $(ps -ax | grep unison | wc -l) -gt 2 ]; do
    for PID in $(pgrep unison); do
      kill $PID 2>/dev/null
      if [ $? -eq 0 ]; then ((COUNT++)); fi
    done
    sleep 1
  done
  return $COUNT
};

function KILL_UNISON_SERVER_LOOP()
{
  STORE_PID_ARRAY
  declare -i COUNT=0
  while [ ${#PID_ARRAY[@]} -gt 2 ]; do
    STORE_PID_ARRAY
    for PID in ${PID_ARRAY[@]}; do
      if [ -d /proc/"$PID" ]; then
        kill $PID 2>/dev/null
        if [ $? -eq 0 ]; then ((COUNT++)); fi
      fi
    done
    sleep 1
  done
  return $COUNT
}


if [ $((SYS_LOAD)) -gt $((THRESHOLD)) ]; then
  KILL_UNISON_LOOP
  echo -e "Killed $? instances of binary executable: unison"
  sleep 1
  KILL_UNISON_SERVER_LOOP
  echo -e "Killed $? instances of script file: UnisonServers.sh"
  sleep 1
  KILL_UNISON_LOOP
  echo -e "Killed $? instances of binary executable: unison"
  SYS_LOAD=$(GET_SYS_LOAD)
fi
