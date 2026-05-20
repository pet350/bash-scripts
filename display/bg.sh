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
declare -x RUN_CMD="$(basename $0)"
declare -x VERSION="0.1"

for OPTIONS in $@; do
    case $OPTIONS in
        --force)			      declare -i BOL_FORCE=$TRUE;;
    esac
done

if [ ${#FEH_BIN}		-eq 0 ]; then declare -x TEMP="feh"; declare -x "${TEMP^^}_BIN"=$(GET_BIN);	fi
if [ ${#PIC_PATH}		-eq 0 ]; then declare -x PIC_PATH="/usr/local/share/backgrounds/Maiden";	fi
if [ ${#OPTIONS}		-eq 0 ]; then declare -x OPTIONS="-z --bg-scale";				fi
if [ ${#OUTPUT}			-eq 0 ]; then declare -x OUTPUT="/dev/stdout";					fi
if [ ${#COMMAND}		-eq 0 ]; then declare -x COMMAND="$FEH_BIN $OPTIONS $PIC_PATH";			fi
if [ ${#DESKTOP_SESSION}	-eq 0 ]; then declare -x DESKTOP_SESSION="openbox";				fi
if [ ${#BOL_FORCE}              -eq 0 ]; then declare -i BOL_FORCE=$FALSE;                              	fi
if [ $BOL_FORCE             -eq $TRUE ]; then declare -x DESKTOP_SESSION="Forced";                      	fi
unset TEMP
declare -i RETVAL=$FAILURE

if [ ${#DESKTOP_SESSION} -gt 0 ]; then
#  case ${DESKTOP_SESSION,,} in
#    'LXQt Desktop' | 'lxqt' | 'lxde' | 'openbox' | 'openbox-session' | '/usr/share/xsessions/openbox' | 'Forced')
      $FEH_BIN $OPTIONS $PIC_PATH
      declare -x RETVAL=$?
#      ;;
#  esac
  LOG_RESULTS >$OUTPUT
fi

exit $RETVAL
