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

if [ ${#COMPRESSION}	-eq 0 ]; then export COMPRESSION="--xz";		fi

function DISPLAY_HEADER()
{
  echo -e "Source Prefix: $SOURCE_PREFIX"
  echo -e "Target Prefix: $TARGET_PREFIX"
  return $SUCCESS
};

function GET_SUB_DIR()
{
  declare FUNCTION_RETURN=$FAILURE
  while IFS= read FULL_SUB_DIR; do
    export SUB_DIR="${FULL_SUB_DIR#*$SOURCE_PREFIX/}"
    if [ "$SUB_DIR" != "$SOURCE_PREFIX" ]; then echo $SUB_DIR; FUNCTION_RETURN=$SUCCESS; fi
  done < <(find $SOURCE_PREFIX -maxdepth 1 -type d)
  return $FUNCTION_RETURN
};


function XZ_BACKUP_SUBDIRS()
{
  declare -i FUNCTION_RETURN=$SUCCESS
  while IFS= read SUB; do
    export TARGET_FILE="$SUB.tar.xz"
    export FULL_TARGET="$TARGET_PREFIX/$TARGET_FILE"
    if   [ $BOL_VERBOSE -eq $TRUE ] && [ $BOL_DEBUG -eq $TRUE ]; then
      export COMMAND="$TAR_BIN $COMPRESSION $VERBOSE -cf $FULL_TARGET -C $SOURCE_PREFIX $SUB/"
    elif [ $BOL_VERBOSE -eq $TRUE ] && [ $BOL_DEBUG -ne $TRUE ]; then
      export COMMAND="$TAR_BIN"
    else
      export COMMAND=""
    fi
    $TAR_BIN $COMPRESSION $VERBOSE -cf "$FULL_TARGET" -C "$SOURCE_PREFIX" "$SUB/"
    export RETVAL=$?
    if [ $BOL_QUIET -ne $TRUE ]; then LOG_RESULTS; fi
    FUNCTION_RETURN=$((FUNCTION_RETURN+RETVAL))
  done < <(GET_SUB_DIR)
  return $FUNCTION_RETURN
};

function XZ_BACKUP_FILES()
{
  declare -i FUNCTION_RETURN=$SUCCESS
  while IFS= read FULL_FILENAME; do
    export SHORT_FILENAME="${FULL_FILENAME#*$SOURCE_PREFIX/}"
    export TARGET_FILENAME="$TARGET_PREFIX/$SHORT_FILENAME.tar.xz"
    if   [ $BOL_VERBOSE -eq $TRUE ] && [ $BOL_DEBUG -eq $TRUE ]; then
      export COMMAND="$TAR_BIN $COMPRESSION $VERBOSE -cf $TARGET_FILENAME -C $SOURCE_PREFIX $SHORT_FILENAME"
    elif [ $BOL_VERBOSE -eq $TRUE ] && [ $BOL_DEBUG -ne $TRUE ]; then
      export COMMAND="$TAR_BIN"
    else
      export COMMAND=""
    fi
    $TAR_BIN $COMPRESSION $VERBOSE -cf "$TARGET_FILENAME" -C "$SOURCE_PREFIX" "$SHORT_FILENAME"
    export RETVAL=$?
    if [ $BOL_QUIET -ne $TRUE ]; then LOG_RESULTS; fi
    FUNCTION_RETURN=$((FUNCTION_RETURN+RETVAL))
  done < <(find $SOURCE_PREFIX -maxdepth 1 -type f)
  return $FUNCTION_RETURN
};

for OPTIONS in $@; do
  case $OPTIONS in
    --test)
      export BOL_TEST=$TRUE;		export TAR_BIN=$TRUE_BIN
      ;;
    --target-prefix=*)
      export TARGET_PREFIX="${OPTIONS#*=}"
      ;;
    --source-prefix=*)
      export SOURCE_PREFIX="${OPTIONS#*=}"
      ;;
    -h | --help)
      export BOL_HELP=$TRUE
      ;;
    -d | --debug)
      export BOL_DEBUG=$TRUE;		export BOL_VERBOSE=$TRUE;	export BOL_QUIET=$FALSE;	export VERBOSE="--verbose"
      ;;
    -v | --verbose)
      export BOL_DEBUG=$BOL_DEBUG;	export BOL_VERBOSE=$TRUE;	export BOL_QUIET=$FALSE;	export VERBOSE="--verbose"
      ;;
    -q | --quiet)
      export BOL_DEBUG=$FALSE;		export BOL_VERBOSE=$FALSE;	export BOL_QUIET=$TRUE;		export VERBOSE=""
      ;;
    --version)
      echo -e "$RUN_CMD\tVersion: $VERSION\nBy:\t\tPeter Talbott"
      exit $SUCCESS
      ;;
    --bw)
      export BOL_FORCE_COLOR=$FALSE;		export BOL_COLOR=$FALSE
      ;;
    --color)
      export BOL_FORCE_COLOR=$BOL_FORCE_COLOR;	export BOL_COLOR=$TRUE
      ;;
    --force-color)
      export BOL_FORCE_COLOR=$TRUE;		export BOL_COLOR=$TRUE
      ;;
    *)
      OPT_ARRAY[$((OPT_ARRAY_INDEX))]="$OPTIONS"
      OPT_ARRAY_INDEX=${#OPT_ARRAY[@]}
      ;;
  esac
done

if [ $BOL_COLOR		-eq $TRUE		]; then INIT_COLOR_SHORTHAND;							fi
if [ $BOL_HELP		-eq $TRUE		]; then DO_HELP;			exit $SUCCESS;				fi
if [ ${#TARGET_PREFIX}	-eq 0			]; then export TARGET_PREFIX="/tmp$SOURCE_PREFIX";				fi
if [ !			-d  "$TARGET_PREFIX"	]; then mkdir -p "$TARGET_PREFIX";						fi
if [ $BOL_QUIET		-ne $TRUE		]; then DISPLAY_HEADER;								fi

XZ_BACKUP_SUBDIRS
XZ_BACKUP_FILES
 