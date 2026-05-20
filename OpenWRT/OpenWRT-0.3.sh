#!/bin/bash
## Script To Run OpenWRT In a QEMU Environment
## Peter Talbott

# Set Default Boolean Variables
REQUIRED_PARAMETER=0
RUN_PARAMETER=0
UNKNOWN_PARAMETER=0
SHOW_OPTS=0
SET_SERIAL=0
SET_SERIAL_SERVER=1
SET_SERIAL_NOWAIT=1
SET_SERIAL_NODELAY=1
SET_HELP=0

SET_SERIAL_SERVER_COUNT=0
SET_SERIAL_NOWAIT_COUNT=0
SET_SERIAL_NODELAY_COUNT=0

# Set inital variables
_IMG_VER="0.3"
_IMG_ARCH="arm"
_IMG_NAME="OpenWRT"
_EMULATOR="qemu"
_PID_PREFIX="/run"

# QEMU Path and Binary
_QEMU_BIN_PREFIX="/usr/bin"
_QEMU_BIN_EXEC="$_EMULATOR-system-$_IMG_ARCH"

# Status: Production (prod)/ Development (dev)
_IMG_STATUS="prod"

# QEMU Default Drive Image(s)
QEMU_IMAGE_VDA="sdcard/openwrt-armvirt-32-root.qcow2"
QEMU_IMAGE_VDB="sdcard/openwrt-armvirt-32-opt.qcow2"

# QEMU Default 64MB RAM
_QEMU_RAM=64

# QEMU Default Basic Network Component Elements
QEMU_IF_NAME0="tap0"
QEMU_IF_NAME1="tap1"
QEMU_NETWORK_INTERFACE_ETH0="e1000"
QEMU_NETWORK_INTERFACE_ETH1="e1000"
QEMU_NETWORK_MAC0="mac=aa:d2:28:65:ad:f6"
QEMU_NETWORK_MAC1="mac=aa:d2:28:65:ed:1a"

# Default Address and Port for Serial Console
QEMU_SERIAL_ADDRESS="172.16.185.2"
QEMU_SERIAL_PORT="65501"

for i in "$@"
do
case $i in
'-c' | '--console')
	if [ $REQUIRED_PARAMETER -eq 0 ]
	then
		REQUIRED_PARAMETER=1
		RUN_PARAMETER=1
		SET_SERIAL=0
        	QEMU_MODE="Console Mode: "
        	QEMU_VIDEO="-nographic -M virt"
	else
		# Cannot Run as both Console and Daemon
		RUN_PARAMETER=0
	fi
        ;;

'-d' | '--daemon')
        if [ $REQUIRED_PARAMETER -eq 0 ]
        then
		REQUIRED_PARAMETER=1
		RUN_PARAMETER=1
		SET_SERIAL=1
	        QEMU_MODE="Daemon Mode: "
	        QEMU_VIDEO="-display none -daemonize -M virt"
        else
                # Cannot Run as both Console and Daemon
                RUN_PARAMETER=0
        fi
        ;;
-a=* | --append=*)
	QEMU_CMDLINE="${i#*=}"
	;;
-m=* | --mem=* | --memory=*)
	_QEMU_RAM="${i#*=}"
	;;
'--serial-nowait')
	SET_SERIAL_NOWAIT=1
	;;
'--serial-wait')
	SET_SERIAL_NOWAIT=0
	;;
'--serial-nodelay')
	((SET_SERIAL_NODELAY_COUNT++))
	SET_SERIAL_NODELAY=1
	;;
'--serial-delay')
	((SET_SERIAL_NODELAY_COUNT++))
	SET_SERIAL_NODELAY=0
	;;
'--prod')
	_IMG_STATUS="prod"
	;;
'--dev')
	_IMG_STATUS="dev"
	;;
'--show')
	SHOW_OPTS=1
	;;
'--show-only')
	SHOW_OPTS=2
	;;
'-h' | '--help')
	SET_HELP=1
	;;
*)
        RUN_PARAMETER=0
	(( UNKNOWN_PARAMETER++ ))
	echo "Unknown Option: $i; Cannot Continue"
        ;;
esac
done

if [ $UNKNOWN_PARAMETER -ne 0 ]
  then
	# Unknow Parameter Is Enabled, Do Not Run
        REQUIRED_PARAMETER=0
        RUN_PARAMETER=0
        SHOW_OPTS=0
        SET_SERIAL=0
	echo "Attempted $((UNKNOWN_PARAMETER)) Unknown Paramater(s)"
fi

if [ $SET_HELP -eq 1 ]
  then
	# IF SET_HELP Is Enabled, Make Sure All Others are Disabled
	REQUIRED_PARAMETER=0
	RUN_PARAMETER=0
	SHOW_OPTS=0
	SET_SERIAL=0
fi

# Assemble QEMU Root Path
QEMU_ROOT="/opt/qemu/$_IMG_STATUS/OpenWRT/arm/32/$_IMG_VER"

# Assemble QEMU Memory
QEMU_MEMORY="-m $_QEMU_RAM"

# Assemble QEMU Boot Options
QEMU_BOOT_KERNEL="-kernel $QEMU_ROOT/openwrt-armvirt-32-zImage"
QEMU_BOOT_OPTIONS="-append root=/dev/vda"
#QEMU_BOOT_INITRD="-initrd $QEMU_ROOT/openwrt-armvirt-32-zImage-initramfs"
QEMU_BOOT="$QEMU_BOOT_KERNEL $QEMU_BOOT_OPTIONS $QEMU_BOOT_INITRD"

# Assemble QEMU Drive(s)
QEMU_DRIVE_VDA="-drive file=$QEMU_ROOT/$QEMU_IMAGE_VDA,format=qcow2,if=virtio,index=0"
QEMU_DRIVE_VDB="-drive file=$QEMU_ROOT/$QEMU_IMAGE_VDB,format=qcow2,if=virtio,index=1"
QEMU_DRIVES="$QEMU_DRIVE_VDA $QEMU_DRIVE_VDB"

# Assemble QEMU Network Elements
QEMU_NET_ETH0="-netdev tap,id=veth0,ifname=$QEMU_IF_NAME0,script=no,downscript=no"
QEMU_NET_ETH1="-netdev tap,id=veth1,ifname=$QEMU_IF_NAME1,script=no,downscript=no"
QEMU_DEVICE_ETH0="-device $QEMU_NETWORK_INTERFACE_ETH0,netdev=veth0,$QEMU_NETWORK_MAC0"
QEMU_DEVICE_ETH1="-device $QEMU_NETWORK_INTERFACE_ETH1,netdev=veth1,$QEMU_NETWORK_MAC1"
QEMU_ETH0="$QEMU_NET_ETH0 $QEMU_DEVICE_ETH0"
QEMU_ETH1="$QEMU_NET_ETH1 $QEMU_DEVICE_ETH1"
QEMU_NETWORK="$QEMU_ETH0 $QEMU_ETH1"

## Assemble Serial Console Redirect If SET_SERIAL is enabled
if [ $SET_SERIAL -eq 1 ]
  then
	# Check And Set Serial Option: Server/No server (If Applicable)
	if [ $SET_SERIAL_SERVER -eq 1 ]
          then
		QEMU_SERIAL_SERVER=",server"
	fi
        if [ $SET_SERIAL_SERVER -eq 2 ]
          then
                QEMU_SERIAL_SERVER=",noserver"
        fi
	# Check And Set Serial Option: No Wait (If Applicable)
	if [ $SET_SERIAL_NOWAIT -eq 1 ]
	  then
		QEMU_SERIAL_NOWAIT=",nowait"
	  else
		QEMU_SERIAL_NOWAIT=""
	fi
	# Check And Set Serial Option: No Delay (If Applicable)
	if [ $SET_SERIAL_NODELAY -eq 1 ]
	  then
		QEMU_SERIAL_NODELAY=",nodelay"
	  else
		QEMU_SERIAL_NODELAY=""
	fi
	QEMU_SERIAL_OPTIONS="$QEMU_SERIAL_SERVER$QEMU_SERIAL_NOWAIT$QEMU_SERIAL_NODELAY"
	QEMU_SERIAL="-serial tcp:$QEMU_SERIAL_ADDRESS:$QEMU_SERIAL_PORT$QEMU_SERIAL_OPTIONS"
  else
	QEMU_SERIAL=""
fi

## Assemble QEMU Binary Prefix and Executable
QEMU_BIN="$_QEMU_BIN_PREFIX/$_QEMU_BIN_EXEC"

## Assemble QEMU PID Prefix And Directory Structure
_ARG_FILE="$_IMG_NAME.arg"
_PID_FILE="$_IMG_NAME.pid"
_PID_PREFIX="$_PID_PREFIX/$_EMULATOR/$_IMG_NAME/$_IMG_ARCH/$_IMG_STATUS/$_IMG_VER"
if [ ! -d "$_PID_PREFIX" ]
  then
	mkdir -p "$_PID_PREFIX"
fi

## Assemble QEMU_PID
QEMU_PID="-pidfile $_PID_PREFIX/$_PID_FILE"

## Assemble All The Variables Into One Long String
QEMU_MACHINE="$QEMU_VIDEO $QEMU_MEMORY $QEMU_NETWORK $QEMU_BOOT $QEMU_DRIVES $QEMU_SERIAL $QEMU_PID $QEMU_CMDLINE"

if [ $REQUIRED_PARAMETER -eq 1 ]
  then
  if [ $SHOW_OPTS -eq 1 ]
     then
	echo "QEMU Command Line:"
	echo -n $QEMU_MACHINE
	echo
  fi
  if [ $SHOW_OPTS -eq 2 ]
     then
	RUN_PARAMETER=0
        echo "QEMU Command Line:"
        echo -n $QEMU_MACHINE
        echo
  fi

  if [ $RUN_PARAMETER -eq 1 ]
     then
	echo -n "Starting $prog in $QEMU_MODE"
	echo -e "Executable Binary:\t$QEMU_BIN" >$_PID_PREFIX/$_ARG_FILE
	echo -e "Execution Time:\t$(date)" >>$_PID_PREFIX/$_ARG_FILE
	echo -e "Arguments:\t$QEMU_MACHINE" >>$_PID_PREFIX/$_ARG_FILE
	$QEMU_BIN $QEMU_MACHINE
        RETVAL=$?
        [ $RETVAL = 0 ] && echo Success
        [ $RETVAL != 0 ] && echo Failure
        echo
     else
	echo -n "Not Starting QEMU"
	echo
  fi
  else
        # Display Help Message, if SET_HELP Is Enabled
	if [ $SET_HELP -eq 1 ]
	   then
		# Display Help Message
		echo $0
		echo "\tREQUIRED PARAMETER:"
		echo "-c  or  --console\t\tRun OpenWRT In A Console Window"
		echo "-d  or  --daemon\t\tRun OpenWRT As A Daemon"
		echo "\n\tOPTIONAL PARAMETERS:"
		echo "-h  or  --help\t\t\tDisplay This Message"
		echo "--dev\t\t\t\tUse Dev Image Path. (Prod is Default)"
		echo "--show\t\t\t\tDisplay QEMU Command Line and then Execute"
		echo "--show-only\t\t\tDisplay QEMU Command Line and then Exit\n"
	    else
		echo "Usage: $0 { -c --console | -d --daemon | -h --help }"
	fi
        RETVAL=1
fi
exit $RETVAL
