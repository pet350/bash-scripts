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

# Define Command being Executed and its Version
export RUN_CMD="$(basename $0)"
export VERSION="0.1"

if [ ${#TTY_BIN} 	-eq 0 ]; then export TEMP="tty";	export TTY_BIN=$(GET_BIN);	fi
if [ ${#STTY_BIN}       -eq 0 ]; then export TEMP="stty";       export STTY_BIN=$(GET_BIN);	fi
if [ ${#BOL_VERBOSE}	-eq 0 ]; then declare -ig BOL_VERBOSE=$FALSE;				fi

function GET_RES()
{
  declare -i FUNCT_RETURN=$SUCCESS
  export OLD_RES=$($STTY_BIN -g)

  $STTY_BIN raw -echo min 0 time 5

  printf '\0337\033[r\033[999;999H\033[6n\0338' > /dev/tty
  IFS='[;R' read -r _ ROWS COLS _ < /dev/tty

  $STTY_BIN "$OLD_RES"
  FUNCT_RETURN=$?

  if [ $BOL_VERBOSE -eq $TRUE ]; then echo "Columns:$COLS"; echo "Rows:$ROWS"; fi
  $STTY_BIN cols "$COLS" rows "$ROWS"
  return $FUNCTR_RETURN
}

for OPTIONS in $@; do
  case $OPTIONS in
    '-v' | '--verbose')
      export BOL_VERBOSE=$TRUE
      ;;
    '--version')
      echo -e "$RUN_CMD\tVersion: $VERSION\nBy:\t\tPeter Talbott"
      exit $SUCCESS
      ;;
  esac
done

GET_RES
exit $?