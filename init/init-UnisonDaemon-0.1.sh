#!/bin/bash
# Simple script to mount the backup device subvolumes
# Peter Talbott

# Define Initial Variables
export VERSION="0.1"
declare -ag CMDLINE=();
declare -i INDEX=-1

for TEMP in $@; do
  ((INDEX++))
  CMDLINE[$((INDEX))]="$TEMP"
done
declare -ig CMD_LINE_COUNT=$((INDEX+1))

unset INDEX
unset TEMP

export EVENT_FILE="/tmp/.local.changes"
export INOTIFY_BIN="/usr/bin/inotifywait"
export DAEMON_BIN="/usr/sbin/daemonize"
export UNISON_SCRIPT="/usr/local/sbin/UnisonDaemon.sh"
export SCRIPT_OPTIONS="--threshold=2"
export PID_FILE="/run/UnisonServers.pid"
export DAEMON_LOG="/var/log/unison/daemon.log"

declare -ig VAR_WAIT=1
declare -ag HELP_ARRAY=("start" "Initialize Unison Daemon\n" \
 "stop" "Stop Unison Daemon\n" "restart" "Stop and Reinitialize Unison Daemon\n" \
 "--version" "Display version information");

declare -ag INOTIFY_OPTION_ARRAY=("--daemon" "--monitor" "--recursive" "--timeout" "0" \
 "--outfile" "$EVENT_FILE" "--event" "modify" "--event" "attrib" "--event" "move" \
 "--event" "create" "--event" "delete");

declare -ag INOTIFY_FOLDER_ARRAY=("/usr/local/*");

for FOLDER in $(ls -Nd1 /home/*); do
  COUNT=${#INOTIFY_FOLDER_ARRAY[@]}
  INOTIFY_FOLDER_ARRAY[$((COUNT))]="$FOLDER"
done

# Function to load source script file
function SOURCE_INCLUDE_FILE()
{
  if [ -f $INCLUDE_FILE ]; then
    . $INCLUDE_FILE
  else
    echo -e "Error: $INCLUDE_FILE Not found!"
    UNSET_VARIABLES
    exit 1
  fi
  return $SUCCESS
};

export INCLUDE_FILE="/usr/local/scripts/include/comdef.sh"
SOURCE_INCLUDE_FILE

export INCLUDE_FILE="/lib/lsb/init-functions"
SOURCE_INCLUDE_FILE

unset INCLUDE_FILE

STANDARD_CMD_LINE_OPTIONS
if [ $BOL_COLOR -eq $TRUE ]; then INIT_COLOR; fi

REQUIRE_ROOT_USER
CHECK_CMD_LINE

if [ $BOL_HELP -eq $TRUE ]; then DO_HELP; fi

if [ $BOL_STOP -eq $TRUE ]; then
  log_daemon_msg "Stopping $RUN_CMD "
  killall inotifywait 2>/dev/null
  export INO_RETVAL=$?
  $SLEEP_BIN $VAR_WAIT
  kill $(cat $PID_FILE) 2>/dev/null
  export UNI_RETVAL=$?
  $SLEEP_BIN $VAR_WAIT
  if [ -f $PID_FILE ]; then rm $PID_FILE 2>/dev/null; fi
  export RETVAL=$((INO_RETVAL+UNI_RETVAL))
  LOG_RESULTS
  echo -e "Stopped Daemons at: $(date)\n" >>$DAEMON_LOG
fi

if [ $BOL_START -eq $TRUE ]; then
  log_daemon_msg "Starting $RUN_CMD "
  echo -e "Starting Daemons at: $(date)\n" >>$DAEMON_LOG
  $INOTIFY_BIN ${INOTIFY_OPTION_ARRAY[@]} ${INOTIFY_FOLDER_ARRAY[@]} 2>/dev/null
  export INO_RETVAL=$?
  $SLEEP_BIN $VAR_WAIT
  $DAEMON_BIN -a -o $DAEMON_LOG -p $PID_FILE $UNISON_SCRIPT $SCRIPT_OPTIONS 2>/dev/null
  export UNI_RETVAL=$?
  $SLEEP_BIN $VAR_WAIT
  export RETVAL=$((INO_RETVAL+UNI_RETVAL))
  LOG_RESULTS
fi

exit $RETVAL
