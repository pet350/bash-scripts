#!/bin/bash
# Script to setup Open vSwitch System Configurations
# Loads Configuration File(s) Stored in: /etc/network/config.d
# By: Peter Talbott


# Source LSB function library.
source /lib/lsb/init-functions

export RUN_CMD="$(basename $0)"
_VER=0.1

if [ $(id -u) -gt 0 ]; then
    echo -e "Must be ran as Root!!"
    exit 1
fi

if [ $# -eq 0 ]
  then
    echo -e "$RUN_CMD Version $_VER\nUsage: $RUN_CMD {start|stop|restart}"
    exit 1
fi

# Source function library for storing XEN info
source /usr/local/src/xen-scripts.sh

export PREFIX="/etc/network/config.d"
export BIN_PREFIX="/usr/bin"
export OVS_BIN="$BIN_PREFIX/ovs-vsctl"

# Define BOOLEAN Variables
declare -ig TRUE=1
declare -ig FALSE=0

declare -ig SUCCESS=0
declare -ig FAILURE=1

declare -ig BOL_START=$FALSE
declare -ig BOL_STOP=$FALSE
declare -ig BOL_RUN=$FALSE
declare -ig BOL_VERBOSE=$FALSE
declare -ig BOL_HELP=$FALSE

declare -ig VAR_UNKNOWN=0
declare -ig VAR_WAIT=1
declare -ig RETVAL=$FAILURE

function do_START()
{
  declare -a DATA_ARRAY=();
  declare -a NET_IFACE_ARRAY=();
  declare -i INDEX=-1
  declare -i NET_IFACE_INDEX=-1
  declare -i BOL_BRIDGE=$FALSE
  declare -i BOL_BOND=$FALSE
  declare -i BOL_IP_ADDRESS=$FALSE
  declare -i BOL_BCAST_ADDRESS=$FALSE
  declare -i BOL_DEFAULT_GATEWAY=$FALSE
  declare -i BOL_NET_IFACE=$FALSE
  declare -i BOL_BOND_IFACE=$FALSE
  declare -i BOL_BRIDGE_IFACE=$FALSE
  declare -i BOL_BCAST_ADDRESS=$FALSE
  declare -i BOL_UNKNOWN=$FALSE

  if [ ! -f $PREFIX/* ]; then
    echo "Error! No Config Files Found In $PREFIX!"
    RETVAL=$FAILURE
  else
    for LIST in $(ls -1 $PREFIX); do
      INDEX=-1
      DATA_ARRAY=();
      for DATA in $(cat $PREFIX/$LIST); do
	((INDEX++))
	DATA_ARRAY[$((INDEX))]="$DATA"
      done

      NET_IFACE_ARRAY=();
      INDEX=-1
      NET_IFACE_INDEX=-1

      DATA=""
      BOND_IFACE=""
      BRIDGE_IFACE=""
      NETWORK_IFACE=""
      OPTION_DATA=""
      IP_ADDRESS=""
      BROADCAST_ADDRESS=""
      DEFAULT_GATEWAY=""
      BCAST_ADDRESS=""

      BOL_BRIDGE=$FALSE
      BOL_BOND=$FALSE
      BOL_BOL_IP_ADDRESS=$FALSE
      BOL_DEFAULT_GATEWAY=$FALSE
      BOL_BCAST_ADDRESS=$FALSE
      BOL_NET_IFACE=$FALSE
      BOL_BOND_IFACE=$FALSE
      BOL_BRIDGE_IFACE=$FALSE
      BOL_BCAST_ADDRESS=$FALSE

      for DATA in ${DATA_ARRAY[@]}; do
	((INDEX++))
	if [ $BOL_VERBOSE -eq $TRUE ]; then
		echo -e "Index: $INDEX\tDATA:$DATA"
	fi
	case $DATA in
	NETWORK-INTERFACE=* | network-interface=*)
		TEMP_DATA="${DATA#*=}"
		TEMP_DATA=`echo $TEMP_DATA | sed 's/.\(.*\)/\1/' | sed 's/\(.*\)./\1/'`
		NETWORK_IFACE="$NETWORK_IFACE $TEMP_DATA "
		ip addr flush $TEMP_DATA
		((NET_IFACE_INDEX++))
		NET_IFACE_ARRAY[$((NET_IFACE_INDEX))]="$TEMP_DATA"
		BOL_NET_IFACE=$TRUE
		;;
	BOND-INTERFACE=* | bond-interface=*)
                TEMP_DATA="${DATA#*=}"
		TEMP_DATA=`echo $TEMP_DATA | sed 's/.\(.*\)/\1/' | sed 's/\(.*\)./\1/'`
		BOND_IFACE="$BOND_IFACE $TEMP_DATA "
		BOL_BOND_IFACE=$TRUE
		;;
	OPTION=* | option=*)
		TEMP_DATA="${DATA#*=}"
		TEMP_DATA=`echo $TEMP_DATA | sed 's/.\(.*\)/\1/' | sed 's/\(.*\)./\1/'`
		OPTION_DATA="$OPTION_DATA $TEMP_DATA "
		;;
	BRIDGE-INTERFACE=* | bridge-interface=*)
		TEMP_DATA="${DATA#*=}"
		TEMP_DATA=`echo $TEMP_DATA | sed 's/.\(.*\)/\1/' | sed 's/\(.*\)./\1/'`
		BRIDGE_IFACE="$BRIDGE_IFACE $TEMP_DATA "
		BOL_BRIDGE_IFACE=$TRUE
		;;
	IP-ADDRESS=* | ip-address=*)
                TEMP_DATA="${DATA#*=}"
                TEMP_DATA=`echo $TEMP_DATA | sed 's/.\(.*\)/\1/' | sed 's/\(.*\)./\1/'`
		IP_ADDRESS="$TEMP_DATA"
		BOL_IP_ADDRESS=$TRUE
		;;
	BROADCAST=* | broadcast=*)
                TEMP_DATA="${DATA#*=}"
                TEMP_DATA=`echo $TEMP_DATA | sed 's/.\(.*\)/\1/' | sed 's/\(.*\)./\1/'`
		BCAST_ADDRESS="$TEMP_DATA"
		BOL_BCAST_ADDRESS=$TRUE
		;;
	DEFAULT-GATEWAY=* | default-gateway=*)
                TEMP_DATA="${DATA#*=}"
                TEMP_DATA=`echo $TEMP_DATA | sed 's/.\(.*\)/\1/' | sed 's/\(.*\)./\1/'`
		DEFAULT_GATEWAY="$TEMP_DATA"
		BOL_DEFAULT_GATEWAY=$TRUE
		;;
	'BOND="YES"' | 'bond="yes"')
		BOL_BOND=$TRUE
		;;
        'BOND="NO"' | 'bond="no"')
                BOL_BOND=$FALSE
		;;
	'BRIDGE="YES"' | 'bridge="yes"')
		BOL_BRIDGE=$TRUE
		;;
        'BRIDGE="NO"' | 'bridge="no"')
                BOL_BRIDGE=$FALSE
                ;;
	*)
		BOL_UNKNOWN=$TRUE
		;;
	esac
      done
      if [ $BOL_UNKNOWN -eq $TRUE ]; then
		RETVAL=$FAILURE
      else
    		if [ $BOL_VERBOSE -eq $TRUE ]; then
      		     echo -e "add-br $BRIDGE_IFACE"
		fi
		$OVS_BIN add-br $BRIDGE_IFACE

                if [ $BOL_VERBOSE -eq $TRUE ]; then
                     echo -e "set bridge $BRIDGE_IFACE $OPTION_DATA"
                fi
		$OVS_BIN set bridge $BRIDGE_IFACE $OPTION_DATA

		if [ $BOL_BOND -eq $TRUE ]; then
		     if [ $BOL_VERBOSE -eq $TRUE ]; then
			echo -e "$OVS_BIN add-bond $BRIDGE_IFACE $BOND_IFACE $NETWORK_IFACE"
		     fi
		     $OVS_BIN add-bond $BRIDGE_IFACE $BOND_IFACE $NETWORK_IFACE
		     RETVAL=$?
		elif [ $BOL_BRIDGE -eq $TRUE ]; then
		     if [ $BOL_VERBOSE -eq $TRUE ]; then
			echo -e "$OVS_BIN add-port $BRIDGE_IFACE $NETWORK_IFACE"
		     fi
		     $OVS_BIN add-port $BRIDGE_IFACE $NETWORK_IFACE
		     RETVAL=$?
		else
		     RETVAL=$FAILURE
		fi

		for ETH_TEMP in ${NET_IFACE_ARRAY[@]}; do
		     if [ $BOL_VERBOSE -eq $TRUE ]; then
			echo -e "ip link set $ETH_TEMP up"
		     fi
		     ip link set $ETH_TEMP up
		done

		if [ $BOL_IP_ADDRESS -eq $TRUE ]; then
		     if [ $BOL_BCAST_ADDRESS -eq $TRUE ]; then
			if [ $BOL_VERBOSE -eq $TRUE ]; then
			   echo -e "ip addr add $IP_ADDRESS broadcast $BCAST_ADDRESS dev $BRIDGE_IFACE"
			fi
			ip addr add $IP_ADDRESS broadcast $BCAST_ADDRESS dev $BRIDGE_IFACE
		     else
		     	if [ $BOL_VERBOSE -eq $TRUE ]; then
			   echo -e "ip addr add $IP_ADDRESS dev $BRIDGE_IFACE"
		     	fi
		     	ip addr add $IP_ADDRESS dev $BRIDGE_IFACE
		     fi
		fi

		if [ $BOL_DEFAULT_GATEWAY -eq $TRUE ]; then
		     if [ $BOL_VERBOSE -eq $TRUE ]; then
                        echo -e "ip route add default via $DEFAULT_GATEWAY dev $BRIDGE_IFACE"
		     fi
		     ip route add default via $DEFAULT_GATEWAY dev $BRIDGE_IFACE
		fi

		if [ $BOL_VERBOSE -eq $TRUE ]; then
		     echo -e "ip link set $BRIDGE_IFACE up"
		fi
		ip link set $BRIDGE_IFACE up

                sleep $VAR_WAIT
      fi
    done
  fi
  return $RETVAL
};


function do_STOP()
{
   RETVAL=$SUCCESS
   return $RETVAL
};

for i in "$@"
do
case $i in
'start')
        export BOL_START=$TRUE
        ;;
'stop')
	export BOL_STOP=$TRUE
	;;
'restart')
	export BOL_STOP=$TRUE
	export BOL_START=$TRUE
	;;
'-v' | '--verbose')
	export VERBOSE="--verbose"
        export BOL_VERBOSE=$TRUE
        ;;
'-h' | '--help')
	export BOL_HELP=$TRUE
	;;
*)
        (( VAR_UNKNOWN++ ))
	echo -e "Unknown Parameter $i"
        ;;
esac
done

if [ $BOL_HELP -eq $TRUE ]; then
        BOL_START=$FALSE
        BOL_STOP=$FALSE
	#do_HELP
        RETVAL=1
fi

if [ $VAR_UNKNOWN -gt 0 ]; then
	BOL_START=$FALSE
	BOL_STOP=$FALSE
	RETVAL=$VAR_UNKNOWN
fi

if [ $BOL_STOP -eq $TRUE ]; then
        log_daemon_msg "Stopping $RUN_CMD"
        do_STOP
        RETVAL=$?
fi

if [ $BOL_START -eq $TRUE ]; then
        log_daemon_msg "Starting $RUN_CMD"
	do_START
	RETVAL=$?
fi

if [ $((RETVAL)) = $((SUCCESS)) ]; then
        log_success_msg "OK!"
else
	log_failure_msg "FAIL!"
fi

exit $RETVAL
## Done!
