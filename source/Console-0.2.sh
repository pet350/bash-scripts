#!/bin/bash
# Version 0.2
# Peter Talbott

if [ ${#TRUE}		-eq 0 ]; then declare -i TRUE=1;				fi
if [ ${#FALSE}		-eq 0 ]; then declare -i FALSE=0;				fi
if [ ${#BOL_FORCE}      -eq 0 ]; then declare -i BOL_FORCE=$FALSE;			fi
if [ ${#BOL_VERBOSE}    -eq 0 ]; then declare -i BOL_VERBOSE=$FALSE;                    fi
if [ ${#DEV_TTY}	-eq 0 ]; then export DEV_TTY="/dev/tty";			fi

export RUN_CMD="$(basename $0 2>/dev/null)"
export VERSION="0.2"
export AUTHOR="Peter Talbott"
export MODIFIED="2022-09-12"
export WORKING_PREFIX="$(pwd)"

# Self Explanitory Function
function SHOW_HEADER()
{
  echo -e "$RUN_CMD\t\tVersion: $VERSION\nBy: $AUTHOR\tDated: $MODIFIED"
  return $SUCCESS
};

for ARGS in $@; do
  case ${ARGS,,} in
    --cols=*)		export COLS="${ARGS#*=}";;
    --rows=*)		export ROWS="${ARGS#*=}";;
    --force)		export BOL_FORCE=$TRUE;;
    --verbose | -v)	export BOL_VERBOSE=$TRUE;;
    --version)		SHOW_HEADER; exit 0;;
  esac
done

function SET_CONSOLE()
{
  case ${TERM,,} in
    dumb)
       # If running in a 'dumb' terminal, do nothing
       ;;
    *)
       OLD=$(stty -g)
       if [ ${#COLS} -eq 0 ] && [ ${#ROWS} -eq 0 ]; then
         if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Attempting to determin rows and columns..."; fi
         stty raw -echo min 0 time 5
         printf '\0337\033[r\033[999;999H\033[6n\0338' > $DEV_TTY
         IFS='[;R' read -r _ ROWS COLS _ < $DEV_TTY
       fi
       stty "$OLD"
       if [ ${#COLS} -ne 0 ] && [ ${#ROWS} -ne 0 ]; then
         stty cols "$COLS" rows "$ROWS"
         if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "Columns X Rows: $COLS X $ROWS";	fi
       else
         if [ $BOL_VERBOSE -eq $TRUE ]; then
           echo -e "An error occured!"
           if [ ${#COLS} -eq 0 ]; then echo -e "COLS NOT set!"; else echo -e "Columns:\t$COLS";	fi
	   if [ ${#ROWS} -eq 0 ]; then echo -e "ROWS NOT Set!"; else echo -e "Rows:\t$ROWS";	fi
         fi
       fi
       for DATA in OLD ROWS COLS DEV_TTY; do
          unset $DATA
       done
       ;;
  esac
};

if [ $BOL_FORCE  -eq $TRUE ]; then
  if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "[ Info ] $RUN_CMD Forced to execute!";		fi 
  SET_CONSOLE
else
  if [ ${#INTERACTIVE} -eq 0 ]; then
    if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "[ Info ] INETERACTIVE Environment Variable NOT set Executing $RUN_CM";	fi
    SET_CONSOLE
  else
    case $INTERACTIVE in
      'Yes')
	if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "[ Info ] INETERACTIVE Environment Variable set to Yes Executing $RUN_CM"; fi
	SET_CONSOLE
	;;
      *)
	if [ $BOL_VERBOSE -eq $TRUE ]; then echo -e "[ Info ] INETERACTIVE Environment Variable NOT set to Yes,  NOT Executing $RUN_CM"; fi
	;;
    esac
  fi
fi

