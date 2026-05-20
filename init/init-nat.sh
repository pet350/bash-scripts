#! /bin/bash
### BEGIN INIT INFO
# Provides:          Sets up Network Address Translation (NAT) Routing
# Required-Start:    $network $remote_fs $syslog
# Required-Stop:
# Default-Start:     2 3 4 5
# Default-Stop:      0 1 6
# Short-Description: Initialize NAT Routing
# Description:       Initialize Network Address Translation (NAT) Routing
### END INIT INFO
# chkconfig: 2345 08 08
### By: Peter Talbott 2019-02-07

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

if [ $(id -u) -gt 0 ]; then
    echo "Must be ran as root"
    exit 1
fi

if [ $# -eq 0 ]; then
    echo "Usage: $RUN_CMD { start | stop | restart } --help"
    exit 1
fi

export version="0.2"
export INSIDE="br0"
export OUTSIDE="br1"
export VERBOSE=""

declare -ig _BOL_START=0
declare -ig _BOL_STOP=0
declare -ig _BOL_VERBOSE=0
declare -ig _BOL_HELP=0
declare -ig _BOL_FLUSH_ALL=0
declare -ig _VAR_UNKNOWN=0
declare -ig _START_INDEX=2

declare -ag RULES_ARRAY=("--flush" "--delete-chain" "--table nat --flush" "--table nat --delete-chain"
                         "--table nat --append POSTROUTING --out-interface $OUTSIDE -j MASQUERADE"
                         "--append FORWARD --in-interface $INSIDE -j ACCEPT");
declare -ig _VAR_RULES_ARRAY_COUNT=${#RULES_ARRAY[@]}
declare -ig _VAR_RULES_ARRAY_INDEX=$(( _VAR_RULES_ARRAY_COUNT -1))

function do_START()
{
    if [ $_BOL_FLUSH_ALL -gt 0 ]; then
	_START_INDEX=0
    fi
    for (( _INDEX=$((_START_INDEX)); $((_INDEX)) <= $((_VAR_RULES_ARRAY_INDEX)); _INDEX++ )); do
	iptables ${RULES_ARRAY[ $(( _INDEX )) ]} $VERBOSE
    done
    echo 1 >/proc/sys/net/ipv4/ip_forward
};

function do_STOP()
{
    if [ $_BOL_FLUSH_ALL -gt 0 ]; then
        _START_INDEX=0
    fi
    for (( _INDEX=$((_START_INDEX)); $((_INDEX)) <= 3; _INDEX++ )); do
        iptables ${RULES_ARRAY[ $(( _INDEX )) ]} $VERBOSE
    done
    echo 0 >/proc/sys/net/ipv4/ip_forward
};

function do_HELP()
{
	printf "HELP! %-7s\tversion: %-4s\n" "$RUN_CMD" "$version"
	printf "%-15s\t\t%-25s\n" "-h or --help" "Disply This Help Message\n"
        printf "%-15s\t\t%-25s\n" "start" "Start NAT Routing"
        printf "%-15s\t\t%-25s\n" "stop" "Stop NAT Routing"
        printf "%-15s\t\t%-25s\n" "restart" "Restart NAT Routing"
        printf "%-15s\t\t%-25s\n" "--flush-all" "Flush All iptables"
        printf "%-15s\t\t%-25s\n" "-v or --verbose" "Be Verbose"
};

for i in "$@"
do
case $i in
'-h' | '--help')
	export _BOL_HELP=1
	;;
'start')
        export _BOL_START=1
        ;;
'stop')
	export _BOL_STOP=1
	;;
'restart')
	export _BOL_STOP=1
	export _BOL_START=1
	;;
'--flush-all')
	export _BOL_FLUSH_ALL=1
	;;
'-v' | '--verbose')
	export VERBOSE="--verbose"
        export _BOL_VERBOSE=1
        ;;
'-h' | '--help')
	export _BOL_HELP=1
	;;
*)
        (( _VAR_UNKNOWN++ ))
	echo -e "Unknown Parameter $i"
        ;;
esac
done

if [ $_BOL_HELP -gt 0 ]; then
        _BOL_START=0
        _BOL_STOP=0
	do_HELP
        RETVAL=1
fi

if [ $_VAR_UNKNOWN -gt 0 ]; then
	_BOL_START=0
	_BOL_STOP=0
	RETVAL=$_VAR_UNKNOWN
fi

if [ $_BOL_STOP -eq 1 ]; then
        log_daemon_msg "Stopping $RUNCMD"
	do_STOP
fi

if [ $_BOL_START -eq 1 ]; then
        log_daemon_msg "Starting $RUNCMD"
	do_START
fi

## DONE!
exit $RETVAL
