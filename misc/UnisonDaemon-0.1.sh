#! /bin/bash
# Unison Script to keep FOLDER1 and FOLDER2 in Sync
# By: Peter Talbott
# 09/06/2018; 04/10/2019, 6/6/2020

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

# Current Version
export VERSION=0.1
export CMD_LINE="$@"
export PREFIX="/usr/local/sbin"
export EVENT_FILE="/tmp/.local.changes"
export LOGFILE="/var/log/unison/UnisonDaemon.log"
export COMMAND="$PREFIX/UnisonServers.sh"

declare -ig CURRENT_PROC=$(ps -ax | grep -v grep | grep unison | wc -l)
declare -ig RETVAL=$SUCCESS
declare -ig EXIT_VAL=$SUCCESS
declare -ig VAR_WAIT=30
declare -ig LOOP_MAX=90
declare -ig PROC_THRESHOLD=1
declare -ig EXCEDES_THRESHOLD=256

function RUN_COMMAND()
{
  declare -i BOL_LOOP=$TRUE
  declare -i CMD_RETVAL=$FAILURE
  declare -i LOOP_COUNT=0

  while [ $BOL_LOOP -eq $TRUE ]; do
    ((LOOP_COUNT++))
    $COMMAND --custom-folder="$CUSTOM_FOLDER" $CMD_LINE | tee -a $LOGFILE
    CMD_RETVAL=$?

    if [ $CMD_RETVAL -eq $SUCCESS ]; then
      BOL_LOOP=$FALSE
    elif [ $CMD_RETVAL -eq $EXCEDES_THRESHOLD ]; then
      $SLEEP_BIN $VAR_WAIT
      BOL_LOOP=$TRUE
    elif [ $LOOP_COUNT -eq $LOOP_MAX ]; then
      BOL_LOOP=$FALSE
    else
      BOL_LOOP=$TRUE
    fi
  done
  return $CMD_RETVAL
};

function EVENT_LOOP()
{
  declare -i LINE_NUMBER=0
  declare -i WORD_INDEX=-1
  declare -i FUNCTION_RETURN=$FAILURE

  while IFS= read LINE; do
    ((LINE_NUMBER++))
    WORD_INDEX=-1
    for WORD in $LINE; do
      ((WORD_INDEX++))
      if [ $WORD_INDEX -eq 0 ]; then
        export CUSTOM_FOLDER="$WORD"
        export FUNCTION_RETURN=$SUCCESS
        RUN_COMMAND
      fi
    done
  done < <(cat $EVENT_FILE)
  return $FUNCTION_RETURN
};

if [ ! -f $EVENT_FILE ]; then printf "" >$EVENT_FILE; fi

while [ $TRUE -ne $FALSE ]; do
  EVENT_LOOP
  if [ $? -eq $SUCCESS ]; then printf "" >$EVENT_FILE; fi
  $SLEEP_BIN $VAR_WAIT
done

exit $SUCCESS