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

declare -ig DEFAULT_LENGTH=1073741824
declare -ig SET_COMPRESS=0

export DEFAULT_COMPRESS=$XZ_BIN

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
  printf "n $BACKUP_TARGET-%d.tar\n" `seq 2 ${VOL_COUNT}` | $TAR_BIN -ML $(($ARCHIVE_LENGTH/1024)) -cvf "$BACKUP_TARGET-1.tar" -C "$BACKUP_SOURCE" .
  for ARCHIVE in $($LS_BIN "$BACKUP_TARGET"*.tar); do $COMPRESS_BIN -v -$COMPRESS_LEVEL "$ARCHIVE"; done
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

for i in $@; do
  case $i in
    '-h' | '--help')
	export BOL_HELP=$TRUE
	;;
    '-d' | '--debug')
	export BOL_DEBUG=$TRUE
	export BOL_VERBOSE=$TRUE
        export OUTPUT="/dev/stdout"
	;;
    '-v' | '--verbose')
	export BOL_VERBOSE=$TRUE
	;;
    '-t' | '--test')
        export TAR_BIN="$TRUE_BIN"
	export BZIP2_BIN="$TRUE_BIN"
	export LS_BIN="$TRUE_BIN"
        export BOL_TEST=$TRUE
        ;;
    '--skip-tar')
	export TAR_BIN="$TRUE_BIN"
	;;
    --source=*)
        export BACKUP_SOURCE="${i#*=}"
        ;;
    --target=*)
	export BACKUP_TARGET="${i#*=}"
	;;
    --size=*)
	declare -ig ARCHIVE_LENGTH="${i#*=}"
	;;
    --level=*)
	export COMPRESS_LEVEL="${i#*=}"
	;;
    '--bzip2')
	((SET_COMPRESS++))
	export BOL_BZIP2=$TRUE
	;;
    '--gzip')
	((SET_COMPRESS++))
	export BOL_GZIP=$TRUE
	;;
    '--lz4')
	((SET_COMPRESS++))
	export BOL_LZ4=$TRUE
	;;
    '--xz')
	((SET_COMPRESS++))
	export BOL_XZ=$TRUE
	;;
    '--version')
	echo -e "$RUN_CMD\tVersion: $VERSION\nBy: Peter Talbott"
	exit $SUCCESS
	;;
    '--bw')
	export BOL_COLOR=$FALSE
	;;
    '--color')
	export BOL_COLOR=$TRUE
	;;
    '--force-color')
	export BOL_FORCE_COLOR=$TRUE
        export BOL_COLOR=$TRUE
        ;;
  esac
done

SET_COMPRESS_BIN
if [ $?			-eq $FAILURE	]; then BOL_HELP=$TRUE;										fi
if [ $BOL_COLOR		-eq $TRUE	]; then INIT_COLOR_SHORTHAND;									fi
if [ $BOL_HELP		-eq $TRUE	]; then DO_HELP;										fi
if [ $(id -u)		-ne 0	  	]; then CHECK_ROOT_USER;									fi
if [ ${#ARCHIVE_LENGTH}	-eq 0		]; then declare -ig ARCHIVE_LENGTH=$DEFAULT_LENGTH;						fi
if [ ${#BACKUP_SOURCE}	-eq 0		]; then echo -e "$RUN_CMD\tVersion: $VERSION\nUsage: $RUN_CMD [options] --help"; exit $FAILURE;	fi
if [ ${#BACKUP_TARGET}	-eq 0           ]; then export BACKUP_TARGET="${BACKUP_SOURCE##*/}"; 						fi
GET_COUNT
if [ $BOL_VERBOSE	-eq $TRUE	]; then DISPLAY_INFO;										fi
DO_BACKUP
exit $?
