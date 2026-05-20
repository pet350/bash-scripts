#!/bin/bash
# Shell Script By: Peter Talbott
# Ideas sourced from: https://freeipa.readthedocs.io/en/latest/designs/adtrust/samba-domain-member.html

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

declare -ig RETVAL=$SUCCESS
declare -ig BOL_REQ=$FALSE


# Make sure all needed binaries exist and are defined
if [ ${#SLEEP_BIN}	    -eq 0 ]; then echo -e "Error! Binary sleep not found!";		      exit $FAILURE;  fi
if [ ${#IPTABLES_BIN}	    -eq 0 ]; then echo -e "Error! Binary iptables not found!";		      exit $FAILURE;  fi

# Define Global String Variables
export ALLOWED_PORTS="3350,3389,4822,8009,8080,9080"
export GUAC_IFACE="172.16.184.9"
export ANYWHERE="0/0"

declare -ag HELP_ARRAY=("-------------" "-----------------------------------------------------------------\n" \
	"Required" "Command Line Arguments.\n" "start" "Start $RUN_CMD\n" "stop" "Stop $RUN_CMD\n" "restart" "Restart $RUN_CMD\n" \
	"-------------" "-----------------------------------------------------------------");

# Function to create basic iptables firewall on $GUAC_IFACE
function MAKE_GUAC_FW()
{
  declare -i FUNC_RET=$SUCCESS

  $IPTABLES_BIN -A INPUT -s $ANYWHERE -d $GUAC_IFACE -p tcp -m tcp -m multiport ! --dports $ALLOWED_PORTS -j DROP
  FUNC_RET=$?

  $IPTABLES_BIN -A INPUT -s $ANYWHERE -d $GUAC_IFACE -p tcp -m tcp -m multiport   --dports $ALLOWED_PORTS -j ACCEPT
  FUNC_RET=$((FUNC_RET+$?))

  $IPTABLES_BIN -A INPUT -s $ANYWHERE -d $GUAC_IFACE -p icmp -j ACCEPT
  FUNC_RET=$((FUNC_RET+$?))

  $IPTABLES_BIN -A INPUT -s $ANYWHERE -d $GUAC_IFACE -m conntrack -j ACCEPT  --ctstate RELATED,ESTABLISHED
  FUNC_RET=$((FUNC_RET+$?))

  $IPTABLES_BIN -A INPUT -s $ANYWHERE -d $GUAC_IFACE -m state --state ESTABLISHED,RELATED -j ACCEPT
  FUNC_RET=$((FUNC_RET+$?))

  $IPTABLES_BIN -A INPUT -s $ANYWHERE -d $GUAC_IFACE -j DROP
  FUNC_RET=$((FUNC_RET+$?))

  $IPTABLES_BIN -A OUTPUT -s $GUAC_IFACE -d $ANYWHERE -m state --state ESTABLISHED,RELATED -j ACCEPT
  FUNC_RET=$((FUNC_RET+$?))

  $IPTABLES_BIN -A OUTPUT -s $GUAC_IFACE -d $ANYWHERE -p icmp -j ACCEPT
  FUNC_RET=$((FUNC_RET+$?))

  $IPTABLES_BIN -A OUTPUT -s $GUAC_IFACE -d $ANYWHERE -j DROP
  FUNC_RET=$((FUNC_RET+$?))

  $IPTABLES_BIN -A FORWARD -s $GUAC_IFACE -d $ANYWHERE -m state --state ESTABLISHED,RELATED -j ACCEPT
  FUNC_RET=$((FUNC_RET+$?))

  $IPTABLES_BIN -A FORWARD -s $GUAC_IFACE -d $ANYWHERE -j DROP
  FUNC_RET=$((FUNC_RET+$?))

  $IPTABLES_BIN -A FORWARD -s $ANYWHERE -d $GUAC_IFACE -m state --state ESTABLISHED,RELATED -j ACCEPT
  FUNC_RET=$((FUNC_RET+$?))

  $IPTABLES_BIN -A FORWARD -s $ANYWHERE -d $GUAC_IFACE  -j DROP
  FUNC_RET=$((FUNC_RET+$?))

  if [ $BOL_VERBOSE -eq $TRUE ]; then
    $IPTABLES_BIN --list
    FUNC_RET=$((FUNC_RET+$?))
  fi

  return $FUNC_RET
};

function DO_CLEANUP()
{
  declare -i FUNC_RET=$SUCCESS

  $IPTABLES_BIN -F
  FUNC_RET=$?

  $IPTABLES_BIN -X
  FUNC_RET=$((FUNC_RET+$?))

  return $FUNC_RET
};


for i in "$@"
do
case $i in
'-h' | '--help')
	export BOL_HELP=$TRUE
        export VERBOSE=""
        export BOL_DEBUG=$FALSE
        export BOL_VERBOSE=$FALSE
	;;
'-v' | '--verbose')
	export VERBOSE="--verbose"
        export BOL_VERBOSE=$TRUE
        ;;
'-t' | '--test')
	export BOL_TEST=$TRUE
	export IPTABLES_BIN="$TRUE_BIN"
	;;
'--version')
	SHOW_DATE_TIME; echo -e "$RUN_CMD\tVersion: $VERSION\nBy:\t\tPeter Talbott"
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
'start')
	export BOL_REQ=$TRUE
	export BOL_STOP=$FALSE
        export BOL_START=$TRUE
        ;;
'stop')
	export BOL_REQ=$TRUE
        export BOL_STOP=$TRUE
	export BOL_START=$FALSE
        ;;
'restart')
	export BOL_REQ=$TRUE
        export BOL_STOP=$TRUE
        export BOL_START=$TRUE
        ;;
esac
done

if [ $BOL_COLOR -eq $TRUE ]; then INIT_COLOR_SHORTHAND; fi
if [ $BOL_HELP -eq $TRUE ] || [ $BOL_REQ -ne $TRUE ]; then DO_HELP; fi

REQUIRE_ROOT_USER

if [ $BOL_STOP -eq $TRUE ]; then
  DO_CLEANUP
  RETVAL=$?
  LOG_RESULTS
fi

if [ $BOL_START -eq $TRUE ]; then
  MAKE_GUAC_FW
  RETVAL=$?
  LOG_RESULTS
fi

exit $RETVAL
