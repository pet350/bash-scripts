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

# Define String Variables
export EVENT_FILE="/tmp/.local.changes"
export INOTIFY_BIN="/usr/bin/inotifywait"
export DAEMON_BIN="/usr/sbin/daemonize"
export SYNC_SCRIPT="/usr/local/sbin/SyncServers.sh"
export SCRIPT_OPTIONS=""
export PID_FILE="/run/SyncServers.pid"
export DAEMON_LOG="/var/log/sync-daemon.log"

# Define Integer Variables
declare -ig VAR_WAIT=1

# Define Global Arrays
declare -ag INOTIFY_FOLDER_ARRAY=();
declare -ag HELP_ARRAY=("start" "Initialize Unison Daemon\n" \
 "stop" "Stop Unison Daemon\n" "restart" "Stop and Reinitialize Unison Daemon\n" \
 "--version" "Display version information");

declare -ag INOTIFY_OPTION_ARRAY=("--daemon" "--monitor" "--recursive" "--timeout" "0" \
 "--outfile" "$EVENT_FILE" "--event" "modify" "--event" "attrib" "--event" "move" \
 "--event" "create" "--event" "delete");

# Populate INOTIFY_FOLDER_ARRAY with Existing Folders to Monitor
for FOLDER in $(ls -Nd1 /usr/local/{bin,etc,games,include,lib,lib64,libexec,sbin,scripts,share} \
		/home/*/{.config,.kde,.local,Desktop,Documents,Downloads,Music,Pictures}); do
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

# Load source files using script above
export INCLUDE_FILE="/usr/local/scripts/include/comdef.sh"
SOURCE_INCLUDE_FILE

export INCLUDE_FILE="/lib/lsb/init-functions"
SOURCE_INCLUDE_FILE

unset INCLUDE_FILE

declare -ig BOL_MONITOR=$FALSE
declare -ig BOL_SYNC=$FALSE
declare -ig BOL_OPT=$FALSE
declare -ig INO_RETVAL=$SUCCESS
declare -ig UNI_RETVAL=$SUCCESS

for DATA in ${CMDLINE[@]}; do
case $DATA in
'--monitor')
  export BOL_MONITOR=$TRUE
  export BOL_OPT=$TRUE
  ;;
'--sync')
  export BOL_SYNC=$TRUE
  export BOL_OPT=$TRUE
  ;;
'--both')
  export BOL_MONITOR=$TRUE
  export BOL_SYNC=$TRUE
  export BOL_OPT=$TRUE
  ;;
esac
done

if [ $BOL_OPT -eq $FALSE ]; then
  export BOL_MONITOR=$TRUE
  export BOL_SYNC=$TRUE
fi


# Predefined Function in comdef.sh to parse command line options if they exist
STANDARD_CMD_LINE_OPTIONS

# Start Colorized Text if Enabled
if [ $BOL_COLOR -eq $TRUE ]; then INIT_COLOR; fi

# Predefined Function Exit if NOT Root User
REQUIRE_ROOT_USER

# Make sure there is some kinde of command line option
CHECK_CMD_LINE

# Display Help Info if --help is a Command Line Option
if [ $BOL_HELP -eq $TRUE ]; then DO_HELP; fi

# Kill both Daemons
if [ $BOL_STOP -eq $TRUE ]; then
  log_daemon_msg "Stopping $RUN_CMD "
  if [ $BOL_MONITOR -eq $TRUE ]; then
    killall inotifywait 2>/dev/null
    export INO_RETVAL=$?
    $SLEEP_BIN $VAR_WAIT
  fi
  if [ $BOL_SYNC -eq $TRUE ]; then
    kill $(cat $PID_FILE) 2>/dev/null
    export UNI_RETVAL=$?
    $SLEEP_BIN $VAR_WAIT
    if [ -f $PID_FILE ]; then rm $PID_FILE 2>/dev/null; fi
  fi
  export RETVAL=$((INO_RETVAL+UNI_RETVAL))
  LOG_RESULTS
  echo -e "Stopped Daemons at: $(date)\n" >>$DAEMON_LOG
fi

# Launch INOTIFY Daemon and run UnisonDaemon.sh as a Daemon
if [ $BOL_START -eq $TRUE ]; then
  log_daemon_msg "Starting $RUN_CMD "
  echo -e "Starting Daemons at: $(date)\n" >>$DAEMON_LOG
  if [ $BOL_MONITOR -eq $TRUE ]; then
    $INOTIFY_BIN ${INOTIFY_OPTION_ARRAY[@]} ${INOTIFY_FOLDER_ARRAY[@]} 2>/dev/null
    export INO_RETVAL=$?
    $SLEEP_BIN $VAR_WAIT
  fi
  if [ $BOL_SYNC -eq $TRUE ]; then
    $DAEMON_BIN -a -o $DAEMON_LOG -p $PID_FILE $SYNC_SCRIPT $SCRIPT_OPTIONS 2>/dev/null
    export UNI_RETVAL=$?
    $SLEEP_BIN $VAR_WAIT
  fi
  export RETVAL=$((INO_RETVAL+UNI_RETVAL))
  LOG_RESULTS
fi

# Done with script
exit $RETVAL
