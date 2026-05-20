#! /bin/bash
### By: Peter Talbott 2019-08-15
### Modified 2020-01-20

# Source function library.
source /lib/lsb/init-functions

export RUN_CMD="$(basename $0)"
export VERSION="0.1"

declare -ig TRUE=1
declare -ig FALSE=0

declare -ig SUCCESS=0
declare -ig FAILURE=1

if [ $(id -u) -gt 0 ]; then
    echo -e "$RUN_CMD\tVersion: $VERSION\nMust be ran as root"
    exit $SUCCESS
fi

# Define Directoy Prefix String Variables
export BIN_PREFIX="/bin"
export SBIN_PREFIX="/sbin"
export USER_PREFIX="/usr"

sed -i "s|-Lsd|-LS4d|" /etc/default/snmpd
cp /lib/systemd/system/snmpd.service /etc/systemd/system/snmpd.service
sed -i "s|-Lsd|-LS4d|" /etc/systemd/system/snmpd.service
systemctl daemon-reload
restart --status snmpd
