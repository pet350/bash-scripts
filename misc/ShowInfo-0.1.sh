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

export RUN_CMD="$(basename $0)"
export VERSION="0.1"

# Define Global Arrays
declare -ag PCI_OPTS=();
declare -ag USB_OPTS=();
declare -ag CPU_OPTS=();
declare -ag HDD_OPTS=();

# Define Globak Boolean Variables
if [ ${#BOL_HDD}	-eq 0 ]; then declare -ig BOL_HDD=$FALSE;		fi
if [ ${#BOL_CPU}	-eq 0 ]; then declare -ig BOL_CPU=$FALSE;		fi
if [ ${#BOL_PCI}        -eq 0 ]; then declare -ig BOL_PCI=$FALSE;		fi
if [ ${#BOL_USB}        -eq 0 ]; then declare -ig BOL_USB=$FALSE;		fi

# Define Globalk Index Variables
if [ ${#CPU_INDEX}	-eq 0 ]; then declare -ig CPU_INDEX=${#CPU_OPTS[@]};	fi
if [ ${#HDD_INDEX}	-eq 0 ]; then declare -ig HDD_INDEX=${#HDD_OPTS[@]};	fi
if [ ${#PCI_INDEX}	-eq 0 ]; then declare -ig PCI_INDEX=${#PCI_OPTS[@]};	fi
if [ ${#USB_INDEX}	-eq 0 ]; then declare -ig USB_INDEX=${#USB_OPTS[@]};	fi

function SHOW_HDD_INFO()
{
  declare -i LINE_COUNT=-1

  echo -e "Controller: $DEVICE_NAME $SMART_EXT_OPTIONS" >$OUTPUT
  while IFS= read LINE; do
    ((LINE_COUNT++))
    if [ $LINE_COUNT -gt 3 ] && [ $LINE_COUNT -lt 21 ]; then
      echo -e "$LINE"  >$OUTPUT
    fi
  done < <($SMARTCTL_BIN -a $DEVICE_NAME $SMART_OPTIONS $SMART_EXT_OPTIONS ${HDD_OPTS[@]})
  printf "\n\n" >$OUTPUT
  return $LINE_COUNT
};

function SMARTCTL_LOOP()
{
  declare -i DEVICE_NUMBER=-1
  declare -i MAX_DEVICE=3
  declare -i FUNCTION_RETURN=0

  for CONTROLLER in twa0 twa1; do
    DEVICE_NUMBER=-1
    export DEVICE_NAME="/dev/$CONTROLLER"
    while [ $DEVICE_NUMBER -lt $MAX_DEVICE ]; do
      ((DEVICE_NUMBER++))
      export SMART_OPTIONS="-d"
      export SMART_EXT_OPTIONS="3ware,$((DEVICE_NUMBER))"
      SHOW_HDD_INFO
      FUNCTION_RETURN=$((FUNCTION_RETURN+$?))
    done
  done
  return $FUNCTION_RETURN
};

function SHOW_CPU()
{
  while IFS= read LINE; do
    echo -e "$LINE" >$OUTPUT
  done < <($LSCPU_BIN ${CPU_OPTS[@]} 2>/dev/null)
};

function SHOW_PCI()
{
  while IFS= read LINE; do
    echo -e "$LINE" >$OUTPUT
  done < <($LSPCI_BIN ${PCI_OPTS[@]} 2>/dev/null)
};


function SHOW_USB()
{
  while IFS= read LINE; do
    echo -e "$LINE" >$OUTPUT
  done < <($LSUSB_BIN ${USB_OPTS[@]} 2>/dev/null)
};


for i in "$@"; do
  case $i in
    '-h' | '--help')
	export BOL_HELP=$TRUE
	;;
    '--all' | '-a')
	export BOL_CPU=$TRUE
	export BOL_HDD=$TRUE
	export BOL_PCI=$TRUE
	export BOL_USB=$TRUE
	;;
    '--cpu')
	export BOL_CPU=$TRUE
	;;
    --cpu=*)
        export BOL_CPU=$TRUE
        CPU_INDEX=${#CPU_OPTS[@]}
        CPU_OPTS[$((CPU_INDEX))]="${i#*=}"
        ;;
    '--hdd')
	export BOL_HDD=$TRUE
	;;
    --hdd=*)
        export BOL_HDD=$TRUE
        HDD_INDEX=${#HDD_OPTS[@]}
        HDD_OPTS[$((HDD_INDEX))]="${i#*=}"
        ;;
    '--pci')
	export BOL_PCI=$TRUE
	;;
    --pci=*)
        export BOL_PCI=$TRUE
        PCI_INDEX=${#PCI_OPTS[@]}
        PCI_OPTS[$((PCI_INDEX))]="${i#*=}"
        ;;
    '--usb')
	export BOL_USB=$TRUE
	;;
    --usb=*)
        export BOL_USB=$TRUE
        USB_INDEX=${#USB_OPTS[@]}
        USB_OPTS[$((USB_INDEX))]="${i#*=}"
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
    '--enable-root')
	export BOL_ENABLE_ROOT=$TRUE
	;;
    '--version')
	SHOW_DATE_TIME; echo -e "$RUN_CMD\tVersion: $VERSION\nBy:\t\tPeter Talbott"
	exit $SUCCESS
	;;
    *)
       export OUTPUT="$OUTPUT $i"
       ;;
  esac
done

if [ ${#OUTPUT}         -eq 0	  ]; then export OUTPUT="/dev/stdout";	fi
if [ $BOL_COLOR		-eq $TRUE ]; then INIT_COLOR_SHORTHAND;		fi
if [ $BOL_HELP		-eq $TRUE ]; then DO_HELP;			fi
if [ $(id -u)		-ne 0	  ]; then CHECK_ROOT_USER;		fi
if [ $BOL_CPU		-eq $TRUE ]; then SHOW_CPU;			fi
if [ $BOL_HDD		-eq $TRUE ]; then SMARTCTL_LOOP;		fi
if [ $BOL_PCI		-eq $TRUE ]; then SHOW_PCI;			fi
if [ $BOL_USB		-eq $TRUE ]; then SHOW_USB;			fi

exit $SUCCESS
