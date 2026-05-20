#! /bin/bash
### By: Peter Talbott 2019-08-15

export RUN_CMD="$(basename $0)"
export VERSION="0.1"

declare -ig TRUE=1
declare -ig FALSE=0

declare -ig SUCCESS=0
declare -ig FAILURE=1

if [ $(id -u) -gt 0 ]; then
    echo -e "$RUN_CMD\tVersion: $VERSION\nMust be ran as root"
    exit 1
fi

if [ $# -eq 0 ]; then
    echo -e "$RUN_CMD\tVersion: $VERSION\nUsage: $RUN_CMD { service1 service2 service3  } --help"
    exit 1
fi

# Define Directoy Prefix String Variables
export BIN_PREFIX="/bin"
export SBIN_PREFIX="/sbin"
export USER_PREFIX="/usr"

export SYSCTL_BIN="$BIN_PREFIX/systemctl"

$SYSCTL_BIN stop $@
exit $?

