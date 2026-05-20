#!/bin/bash
# Shell Script By: Peter Talbott

# Added in 0.2.1
# Preset tar lengths
# -all option
# Want to get help function populated

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

declare -x RUN_CMD="$(basename $0)"
declare -x VERSION="0.2.1"

declare -ig DEFAULT_LENGTH=1073741824
declare -ig SET_COMPRESS=0

declare -x DEFAULT_COMPRESS=$XZ_BIN

if [ ${#BOL_XZ}		-ne 0 ]; then ((SET_COMPRESS++)); else	declare -ig BOL_XZ=$FALSE;	fi
if [ ${#BOL_BZIP2}	-ne 0 ]; then ((SET_COMPRESS++)); else	declare -ig BOL_BZIP2=$FALSE;	fi
if [ ${#BOL_GZIP}	-ne 0 ]; then ((SET_COMPRESS++)); else	declare -ig BOL_GZIP=$FALSE;	fi
if [ ${#BOL_LZ4}	-ne 0 ]; then ((SET_COMPRESS++)); else	declare -ig BOL_LZ4=$FALSE;	fi
if [ ${#COMPRESS_LEVEL}	-eq 0 ]; then 				declare -ig COMPRESS_LEVEL=7;	fi

function SET_COMPRESS_BIN()
{
  declare -i FUNCTION_RETURN=$SUCCESS
  if   [ $SET_COMPRESS -eq 0 ]; then COMPRESS_BIN=$DEFAULT_COMPRESS
  elif [ $SET_COMPRESS -eq 1 ] && [ $BOL_XZ    -eq $TRUE ]; then COMPRESS_BIN=$XZ_BIN
  elif [ $SET_COMPRESS -eq 1 ] && [ $BOL_BZIP2 -eq $TRUE ]; then COMPRESS_BIN=$BZIP2_BIN
  elif [ $SET_COMPRESS -eq 1 ] && [ $BOL_GZIP  -eq $TRUE ]; then COMPRESS_BIN=$GZIP_BIN
  elif [ $SET_COMPRESS -eq 1 ] && [ $BOL_LZ4   -eq $TRUE ]; then COMPRESS_BIN=$LZ4_BIN
  else FUNCTION_RETURN=$FAILURE; fi
  return $FUNCTION_RETURN
};

# Function returns number of archive files needed for $BACKUP_SOURCE divided by $ARCHIVE_LENGTH
function GET_COUNT()
{
  if [ $BOL_VERBOSE -eq $TRUE ]; then printf "Determining number of parts needed... "; fi
  declare -ig SOURCE_LENGTH=$($DU_BIN -sb $BACKUP_SOURCE | $CUT_BIN -f1)
  declare -ig VOL_COUNT=$(($SOURCE_LENGTH/$ARCHIVE_LENGTH+1))
  if [ $BOL_VERBOSE -eq $TRUE ]; then printf "Done! \n"; fi
  return $SUCCESS
};

function DO_BACKUP()
{
  if [ $BOL_INCLUDE_PATH -eq $TRUE ]; then
    declare -x SOURCE_PATH="${BACKUP_SOURCE%/*}"
    if [ ${#SOURCE_PATH} -eq 0 ]; then declare -x SOURCE_PATH="/"; fi
    declare -x SOURCE_LIST="${BACKUP_SOURCE##*/}"
  else
    declare -x SOURCE_PATH="$BACKUP_SOURCE"
    declare -x SOURCE_LIST="."
  fi
  printf "n $BACKUP_TARGET-%d.tar\n" `seq 2 ${VOL_COUNT}` | $TAR_BIN -ML $(($ARCHIVE_LENGTH/1024)) $OTHER_OPTS $VERBOSE_OPT $CREATE_OPT -f "$BACKUP_TARGET-1.tar" -C "$SOURCE_PATH" "$SOURCE_LIST"
  if [ $BOL_COMPRESS -eq $TRUE ]; then for ARCHIVE in $($LS_BIN "$BACKUP_TARGET"*.tar); do $COMPRESS_BIN -v -$COMPRESS_LEVEL "$ARCHIVE"; done;		fi
  return $?
};

function DISPLAY_INFO()
{
  SHOW_DATE_TIME; printf "%b" $CLB; printf "Tar Executable:\t"; printf "%b" $CY; printf "%s" "$TAR_BIN"; printf "%b\n"
  SHOW_DATE_TIME; printf "%b" $CLB; printf "Zip Executable:\t"; printf "%b" $CY; printf "%s" "$COMPRESS_BIN"; printf "%b\n"
  SHOW_DATE_TIME; printf "%b" $CLB; printf "Source:\t\t"; printf "%b" $CY; printf "%s" "$BACKUP_SOURCE"; printf "%b\n"
  SHOW_DATE_TIME; printf "%b" $CLB; printf "Target:\t\t"; printf "%b" $CY; printf "%s" "$BACKUP_TARGET"; printf "%b\n"
  SHOW_DATE_TIME; printf "%b" $CLB; printf "Multipart Count:\t"; printf "%b" $CY; printf "%s" "$VOL_COUNT"; printf "%b\n"
  SHOW_DATE_TIME; printf "%b" $CLB; printf "Multipart Size:\t"; printf "%b" $CY; printf "%s" "$ARCHIVE_LENGTH"; printf "%b\n"
  return $SUCCESS
};

unset OTHER_OPTS
unset VERBOSE_OPT

declare -x CREATE_OPT="-c"

for i in $@; do
  case $i in
    --version)		echo -e "$RUN_CMD\tVersion: $VERSION\nBy: Peter Talbott";                       exit $SUCCESS;;
    '-bz2')		declare -i BOL_BZIP2=$TRUE;		((SET_COMPRESS++));;
    '--gzip')		declare -i BOL_GZIP=$TRUE;		((SET_COMPRESS++));;
    '--lz4')		declare -i BOL_LZ4=$TRUE;		((SET_COMPRESS++));;
    '--xz')		declare -i BOL_XZ=$TRUE;		((SET_COMPRESS++));;
    '-1m')		declare -i ARCHIVE_LENGTH=1048576;;
    '-4m')		declare -i ARCHIVE_LENGTH=4194304;;
    '-8m')		declare -i ARCHIVE_LENGTH=8388608;;
    '-16m')		declare -i ARCHIVE_LENGTH=16777216;;
    '-32m')		declare -i ARCHIVE_LENGTH=33554432;;
    '-64m')		declare -i ARCHIVE_LENGTH=67108864;;
    '-128m')		declare -i ARCHIVE_LENGTH=134217728;;
    '-256m')		declare -i ARCHIVE_LENGTH=268435456;;
    '-512m')		declare -i ARCHIVE_LENGTH=536870912;;
    '-1g')		declare -i ARCHIVE_LENGTH=1073741824;;
    -h | --help)	declare -i BOL_HELP=$TRUE;;
    -d | --debug)	declare -i BOL_DEBUG=$TRUE;		declare -i BOL_VERBOSE=$TRUE;		declare -x OUTPUT="/dev/stdout";	declare -x ERR_OUT="/dev/stderr";;
    -v | --verbose)	declare -i BOL_DEBUG=$BOL_DEBUG;	declare -i BOL_VERBOSE=$TRUE;		declare -x OUTPUT="/dev/stdout";	declare -x VERBOSE_OPT="-v";;
    -t | --test)	declare -x TAR_BIN="$TRUE_BIN";		declare -x BZIP2_BIN="$TRUE_BIN";	declare -x LS_BIN="$TRUE_BIN";		declare -i BOL_TEST=$TRUE;;
    '--no-tar')		declare -x TAR_BIN="$TRUE_BIN";;
    '--no-compress')	declare -i BOL_COMPRESS=$FALSE;;
    --source=*)		declare -x BACKUP_SOURCE="${i#*=}";;
    --target=*)		declare -x BACKUP_TARGET="${i#*=}";;
    --size=*)		declare -i ARCHIVE_LENGTH="${i#*=}";;
    --level=*)		declare -x COMPRESS_LEVEL="${i#*=}";;
    --bw)		declare -i BOL_COLOR=$FALSE;;
    --color)		declare -i BOL_COLOR=$TRUE;;
    --force-color)	declare -i BOL_FORCE_COLOR=$TRUE;	declare -i BOL_COLOR=$TRUE;;
    -a | --all)		declare -i BOL_FORCE_COLOR=$TRUE;       declare -i BOL_COLOR=$TRUE;		declare -i BOL_VERBOSE=$TRUE;		declare -i BOL_COMPRESS=$FALSE;		declare -i ARCHIVE_LENGTH=268435456;	declare -x OUTPUT="/dev/stdout";        declare -x ERR_OUT="/dev/stderr";;
    --append)		declare -x CREATE_OPT="--append";;
    --include-path)	declare -i BOL_INCLUDE_PATH=$TRUE;;
    *)			declare -x OTHER_OPTS="$OTHER_OPTS ${i#*=}";;
  esac
done

if [ ${#BOL_INCLUDE_PATH}	-eq 0	]; then declare -i BOL_INCLUDE_PATH=$FALSE;							fi
if [ ${#BOL_COMPRESS}	-eq 0		]; then declare -i BOL_COMPRESS=$TRUE;								fi
if [ $BOL_COMPRESS	-eq $TRUE	]; then SET_COMPRESS_BIN;									fi
if [ $?			-eq $FAILURE	]; then BOL_HELP=$TRUE;										fi
if [ $BOL_COLOR		-eq $TRUE	]; then INIT_COLOR_SHORTHAND;									fi
if [ $BOL_HELP		-eq $TRUE	]; then DO_HELP;										fi
if [ $(id -u)		-ne 0	  	]; then CHECK_ROOT_USER;									fi
if [ ${#ARCHIVE_LENGTH}	-eq 0		]; then declare -ig ARCHIVE_LENGTH=$DEFAULT_LENGTH;						fi
if [ ${#BACKUP_SOURCE}	-eq 0		]; then echo -e "$RUN_CMD\tVersion: $VERSION\nUsage: $RUN_CMD [options] --help"; exit $FAILURE;	fi
if [ ${#BACKUP_TARGET}	-eq 0           ]; then declare -x BACKUP_TARGET="${BACKUP_SOURCE##*/}"; 						fi
GET_COUNT
if [ $BOL_VERBOSE	-eq $TRUE	]; then DISPLAY_INFO;										fi
DO_BACKUP
exit $?
