#! /bin/bash
# Simple Script to run WINE in true 32-Bit Architecture and prefix Directory

VERSION=0.1

declare -ig SUCCESS=0
declare -ig FAILURE=1

export RUN_CMD="$(basename $0)"
export WINEARCH="win32"
export WINEPREFIX="/opt/wine32"
export WINEDEBUG="-all"
export BINPREFIX="/usr/bin"
#export BINPREFIX="/snap/wine-platform-5-stable/4/opt/wine-stable/bin"
export WINEBIN="$BINPREFIX/wine"

if [ $(id -u) -eq 0 ]; then
  echo -e "Error: $RUN_CMD Version $VERSION Cannot be ran as ROOT user!"
  exit $FAILURE
fi

$WINEBIN $*
RETVAL=$?

exit $RETVAL
