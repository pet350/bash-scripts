#! /bin/bash
# Synch Script to keep FOLDER1 and FOLDER2 in Sync
# By: Peter Talbott
# 6/8/2020

# Current Version
export VERSION=0.1
export CMD_LINE="$@"
export EVENT_FILE="/tmp/.local.changes"
export LOGFILE="/var/log/sync-daemon.log"
export LOCAL_HOST="$(hostname -f)"

# Define Integer Variables
declare -ig VAR_WAIT=30
declare -ig LOOP_MAX=90

# Define Boolean Variables
declare -ig BOL_UNKNOWN=$FALSE
declare -ig BOL_COPY=$FALSE
declare -ig BOL_DELETE=$FALSE
declare -ig BOL_MOVED_FROM=$FALSE
declare -ig BOL_MOVED_TO=$FALSE
declare -ig BOL_MKDIR=$FALSE
declare -ig BOL_RMDIR=$FALSE

# Source function library.
source /lib/lsb/init-functions

ls /usr/local/scripts/include/*.sh >/dev/null 2>/dev/null 3>/dev/null
if [ $? -eq 0 ]; then
  for INCLUDE_FILE in $(ls -1 /usr/local/scripts/include/*.sh); do
    . $INCLUDE_FILE
  done
fi

# Set all Booleans to False
function FALSE_BOOLEANS()
{
  export BOL_UNKNOWN=$FALSE
  export BOL_COPY=$FALSE
  export BOL_DELETE=$FALSE
  export BOL_MOVED_FROM=$FALSE
  export BOL_MOVED_TO=$FALSE
  export BOL_MKDIR=$FALSE
  export BOL_RMDIR=$FALSE
  return $SUCCESS
};

# Print Success/Failure to Logfile
function PRINT_RESULTS()
{
  if [ $RETVAL -eq $SUCCESS ]; then
    echo -e "Success!" >>$LOGFILE
  else
    echo -e "Failure!" >>$LOGFILE
  fi
  return $RETVAL
};

# Print Date and Time to Logfile
function PRINT_DATE_TIME()
{
  printf "[ %10s @ %5s ] " $(date +%F) $(date +%R) >>$LOGFILE
  return $SUCCESS
};

# Set Remote Hostname based on Local Hostname
if [ $LOCAL_HOST == "lxc.gigaware.lan" ]; then
  export REMOTE_HOST="ipa.gigaware.lan"
else
  export REMOTE_HOST="lxc.gigaware.lan"
fi

# Function that carries out the change
function RUN_COMMAND()
{
  declare -i BOL_LOOP=$TRUE
  declare -i CMD_RETVAL=$FAILURE
  declare -i LOOP_COUNT=0

  while [ $BOL_LOOP -eq $TRUE ]; do
    ((LOOP_COUNT++))
    if [ $BOL_COPY -eq $TRUE ]; then
      TARGET_FILE="$TARGET_FOLDER"
      PRINT_DATE_TIME
      printf "Copy: %s ---> %s " $SOURCE_FILE $TARGET_FILE>>$LOGFILE
      cp --preserve=all --force -vuR "$SOURCE_FILE" "$TARGET_FILE" >/dev/null 2>/dev/null
      CMD_RETVAL=$?
      if [ $CMD_RETVAL -eq $SUCCESS ]; then BOL_COPY=$FALSE; fi
    fi

    if [ $BOL_DELETE -eq $TRUE ]; then
      TARGET_FILE="$TARGET_FOLDER$TEMP_NAME"
      PRINT_DATE_TIME
      printf "Delete: %s " $TARGET_FILE >>$LOGFILE
      rm -vf "$TARGET_FILE" >/dev/null 2>/dev/null
      CMD_RETVAL=$?
    fi

    if [ $BOL_MOVED_FROM -eq $TRUE ]; then
      PRINT_DATE_TIME
      printf "Move File From: %s " $MOVE_SOURCE_FILE >>$LOGFILE
      CMD_RETVAL=$SUCCESS
      BOL_MOVED_FROM=$FALSE
    fi

    if [ $BOL_MOVED_TO -eq $TRUE ]; then
      PRINT_DATE_TIME
      if [ ${#MOVE_SOURCE_FILE} -ne 0 ]; then
        if [ ${#MOVE_TARGET} -ne 0 ]; then
          printf "Move File To: %s " $MOVE_TARGET >>$LOGFILE
          mv -v "$MOVE_SOURCE_FILE" "$MOVE_TARGET" >/dev/null 2>/dev/null
          CMD_RETVAL=$?
        else
          printf "Unable to Move file, Target is not defined! " >>$LOGFILE
          CMD_RETVAL=$SUCCESS
        fi
      else
        printf "Unable to Move file, Source is not defined! " >>$LOGFILE
        CMD_RETVAL=$SUCCESS
      fi
    fi

    if [ $BOL_MKDIR -eq $TRUE ]; then
      PRINT_DATE_TIME
      printf "Make Directory: %s " $MKDIR_TARGET >>$LOGFILE
      mkdir -p "$MKDIR_TARGET" >/dev/null 2>/dev/null
      CMD_RETVAL=$?
    fi

    if [ $BOL_RMDIR -eq $TRUE ]; then
      PRINT_DATE_TIME
      printf "Remove Directory: %s " $MKDIR_TARGET >>$LOGFILE
      rmdir "$MKDIR_TARGET" >/dev/null 2>/dev/null
      CMD_RETVAL=$?
    fi

    if [ $BOL_UNKNOWN -eq $TRUE ]; then
      PRINT_DATE_TIME
      printf "Unknown Directive: %s Path: %s File %s " $UNKNOWN_STRING $UNKNOWN_PATH $UNKNOWN_FILE >>$LOGFILE
      CMD_RETVAL=$SUCCESS
    fi

    export RETVAL=$((CMD_RETVAL))
    PRINT_RESULTS

    if [ $CMD_RETVAL -eq $SUCCESS ]; then
      BOL_LOOP=$FALSE
    elif [ $LOOP_COUNT -eq $LOOP_MAX ]; then
      BOL_LOOP=$FALSE
    else
      $SLEEP_BIN $VAR_WAIT
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
  declare -i LINE_TOTAL=$(cat $EVENT_FILE | wc -l)

  while IFS= read LINE; do
    ((LINE_NUMBER++))
    WORD_INDEX=-1
    unset TEMP_NAME
    export BOL_COPY=$FALSE
    export BOL_DELETE=$FALSE
    for WORD in $LINE; do
      ((WORD_INDEX++))
      if [ $WORD_INDEX -eq 0 ]; then
        export CURRENT_FOLDER="$WORD"
      elif [ $WORD_INDEX -eq 1 ]; then
        case $WORD in
	  'DELETE')
	    FALSE_BOOLEANS
	    export BOL_DELETE=$TRUE
	    ;;
	  'MOVED_FROM')
	    FALSE_BOOLEANS
	    export BOL_MOVED_FROM=$TRUE
	    ;;
	  'MOVED_TO')
	    FALSE_BOOLEANS
            export BOL_MOVED_TO=$TRUE
	    ;;
	  'CREATE,ISDIR')
	    FALSE_BOOLEANS
	    export BOL_MKDIR=$TRUE
	    ;;
	  'DELETE,ISDIR')
	    FALSE_BOOLEANS
            export BOL_RMDIR=$TRUE
            ;;
	  'MODIFY' | 'COPY')
	    FALSE_BOOLEANS
            export BOL_COPY=$TRUE
	    ;;
          *)
            FALSE_BOOLEANS
	    export BOL_UNKNOWN=$TRUE
	    export UNKNOWN_STRING="$WORD"
            ;;
	esac
      else
	if [ ${#TEMP_NAME} -eq 0 ]; then
	  export TEMP_NAME="$WORD"
	else
	  export TEMP_NAME="$TEMP_NAME $WORD"
	fi
      fi
    done
    export UNKNOWN_PATH="$CURRENT_FOLDER"
    export UNKNOWN_FILE="$TEMP_NAME"
    export SOURCE_FILE="$CURRENT_FOLDER$TEMP_NAME"
    export TARGET_FOLDER="/nfs/$REMOTE_HOST$CURRENT_FOLDER"
    export MOVE_SOURCE_FILE="$TARGET_FOLDER$TEMP_NAME"
    export MOVE_TARGET="$TARGET_FOLDER"
    export MKDIR_TARGET="$MOVE_SOURCE_FILE"
    RUN_COMMAND
    FUNCTION_RETURN=$?
  done < <(cat $EVENT_FILE)
  if [ $FUNCTION_RETURN -eq $SUCCESS ]; then
    if [ $LINE_TOTAL -eq $LINE_NUMBER ]; then
      $SLEEP_BIN 2
      PRINT_DATE_TIME
      printf "Finished Task Successfully, Clearing Event File.\n" >>$LOGFILE
      printf "" >$EVENT_FILE
    fi
  fi
  return $FUNCTION_RETURN
};

if [ ! -f $EVENT_FILE ]; then printf "" >$EVENT_FILE; fi

while [ $TRUE -ne $FALSE ]; do
  if [ $(cat $EVENT_FILE | wc --bytes) -gt 0 ]; then
    EVENT_LOOP
    if [ $? -eq $SUCCESS ]; then FALSE_BOOLEANS; fi
  fi
  $SLEEP_BIN $VAR_WAIT
done

exit $SUCCESS