#!/bin/bash
# Shell Script By: Peter Talbott
# 2022-01-17,18

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
export VERSION="0.2"
export AUTHOR="Peter Talbott"
export MODIFIED="2022-01-17"

# Statically Set Integer Variables
declare -i SKIP=255

function PRINT_DATE_TIME()
{
  printf "%b[ %10s @ %5s ] %b" $COLOR_LT_GREEN $(date +%F) $(date +%R) $COLOR_NORMAL
  return $SUCCESS
};

function SHOW_HEADER()
{
  echo -e "$RUN_CMD\tVersion: $VERSION\nBy: $AUTHOR\tDated: $MODIFIED"
  return $SUCCESS
};

# script is based on samba-tool. exit if not found
export TEMP="samba-tool"; GET_BIN >/dev/null
if [ $? -eq $SUCCESS ]; then export ST_BIN=$(GET_BIN); else SHOW_HEADER; echo -e "$TEMP not found"; exit $FAILURE; fi

export TEMP="host"; GET_BIN >/dev/null
if [ $? -eq $SUCCESS ]; then export HOST_BIN=$(GET_BIN); else SHOW_HEADER; echo -e "$TEMP not found"; exit $FAILURE; fi

function SHOW_RESULTS()
{
  if [ $RETVAL -eq $SUCCESS ]; then
    echo -e "Success. Return Value: $RETVAL"
  else
    echo -e "Failure. Return Value: $RETVAL"
  fi
};

function USAGE()
{
  SHOW_HEADER
  echo -e "\nUSAGE:\t\t\t--help | -h for more help"
  echo -e "  $RUN_CMD add ip-address mac-address hostname"
  echo -e "  $RUN_CMD delete ip-address mac-address"
  return $SKIP
};

function VERBOSE_HEADER()
{
  SHOW_HEADER
  echo ''
  echo -e "Script Function:\t$SCRIPT_FUNCTION"
  echo -e "IP Address:\t\t$IP_ADDRESS"
  echo -e "MAC Address:\t\t$MAC_ADDRESS"
  echo -e "Host Name:\t\t$HOST_NAME"
  echo -e "Existing A Record:\t$A_RECORD"
  echo -e "Existing PTR Record:\t$PTR_RECORD"
  echo -e "Log Filename:\t\t$LOGFILE"
  echo ''
  return $SUCCESS
};

# Get and set PTR Record from host binary based on IP Address
function GET_PTR()
{
  declare INDEX=-1
  declare RETVAL=$SUCCESS
  if [ ${#IP_ADDRESS} -ne 0 ]; then
    $HOST_BIN -4 $IP_ADDRESS >/dev/null 2>/dev/null
    if [ $? -eq $SUCCESS ]; then
      for DATA in $($HOST_BIN -4 $IP_ADDRESS); do
        ((INDEX++))
        if [ $INDEX -eq 0 ]; then echo $DATA; fi
      done
    else
      RETVAL=$FAILURE
    fi
  else
    RETVAL=$FAILURE
  fi
  return $RETVAL
};

# Get and set A record from host binary based on IP address
function GET_A_RECORD()
{
  declare INDEX=-1
  declare RETVAL=$SUCCESS
  if [ ${#HOST_NAME} -ne 0 ]; then
    $HOST_BIN -4 $HOST_NAME >/dev/null 2>/dev/null
    if [ $? -eq $SUCCESS ]; then
      for DATA in $($HOST_BIN -4 $HOST_NAME); do
        ((INDEX++))
        if [ $INDEX -eq 3 ]; then echo $DATA; fi
      done
    else
      RETVAL=$FAILURE
    fi
  else
    RETVAL=$FAILURE
  fi
  return $RETVAL
};

# Set PTR based on IP Address without the use of host binary
function SET_PTR()
{
  declare INDEX=-1
  export TEMP_IP=$IP_ADDRESS
  export TEMP_PTR=""
  while [ $INDEX -ne 3 ]; do
    ((INDEX++))
    LAST_OCTET=${TEMP_IP##*.} # Store Last Octet
    TEMP_IP=${TEMP_IP%.*}     # Strip Last Octet
    TEMP_PTR="$TEMP_PTR${LAST_OCTET}."
  done
  TEMP_PTR="${TEMP_PTR}in-addr.arpa"
  echo $TEMP_PTR
  return $SUCCESS
};

# Set host based on host binary
function SET_HOST()
{
  declare -i INDEX=-1
  for DATA in $($HOST_BIN $IP_ADDRESS); do									# Bug fixed in Ver 0.2
    ((INDEX++))
  done
  echo $DATA
  return $?
};

# Delete A record and PTR record in one function
function DEL_RECORD()
{
  # Delete A Record Section
  if [ ${#A_RECORD} -ne 0 ]; then
    ZONE=${HOST_NAME#*.}
    COMMAND="Delete DNS A Record"										 # Changed in Ver 0.2
    if [ $BOL_VERBOSE -eq $TRUE ]; then PRINT_DATE_TIME; printf  "Deleting Old A Record: %s from zone: %s\n" "$A_RECORD" "$ZONE"; fi
    if [ $BOL_DEBUG -eq $TRUE ]; then PRINT_DATE_TIME;echo "[Debug] $ST_BIN dns delete $SERVER $ZONE $HOST_NAME A $IP_ADDRESS --username=$UPDATE_USER --password=$UPDATE_PASS"; fi
    printf "%s Delete old DNS A Record %s %s from zone %s: " "$(date)" "$IP_ADDRESS" "$HOST_NAME" "$ZONE" >>$LOGFILE
    $ST_BIN dns delete $SERVER $ZONE $HOST_NAME A $IP_ADDRESS --username=$UPDATE_USER --password=$UPDATE_PASS >/dev/null 2>/dev/null
    export RETVAL=$?; if [ $BOL_QUIET -ne $TRUE ]; then PRINT_DATE_TIME; LOG_RESULTS; echo ''; fi                 # Added in Ver 0.2
    export A_REC_RETVAL=$RETVAL
    COMMAND=''; SHOW_RESULTS >>$LOGFILE
  else
    if [ $BOL_VERBOSE -eq $TRUE ]; then PRINT_DATE_TIME; echo -e "No old A Record found, skipping deletion of old A Record"; fi
    export RETVAL=$SUCCESS; A_REC_RETVAL=$RETVAL; COMMAND="Skip Deletion"
    if [ $BOL_QUIET -ne $TRUE ]; then PRINT_DATE_TIME; LOG_RESULTS; echo ''; fi
  fi

  # Delete PTR Record Section
  if [ ${#PTR_RECORD} -eq 0 ] && [ $BOL_FORCE -eq $TRUE ]; then PTR_RECORD=$(SET_PTR); fi ## Added in Ver 0.2 if PTR is not set by host binary and force is set then set it from the IP Address
  if [ ${#PTR_RECORD} -ne 0 ]; then
    ZONE=${PTR_RECORD#*.}
    COMMAND="Delete DNS PTR Record"										 # Changed in Ver 0.2
    if [ $BOL_VERBOSE -eq $TRUE ]; then PRINT_DATE_TIME; printf  "Deleting Old PTR Record: %s from zone: %s\n" "$PTR_RECORD" "$ZONE"; fi
    if [ $BOL_DEBUG -eq $TRUE ]; then PRINT_DATE_TIME; echo "[Debug] $ST_BIN dns delete $SERVER $ZONE $PTR_RECORD PTR $HOST_NAME --username=$UPDATE_USER --password=$UPDATE_PASS"; fi
    printf "%s Delete old DNS PTR Record %s %s from zone %s: " "$(date)" "$PTR_RECORD" "$HOST_NAME" "$ZONE" >>$LOGFILE
    $ST_BIN dns delete $SERVER $ZONE $PTR_RECORD PTR $HOST_NAME --username=$UPDATE_USER --password=$UPDATE_PASS  >/dev/null 2>/dev/null
    export RETVAL=$?; if [ $BOL_QUIET -ne $TRUE ]; then PRINT_DATE_TIME; LOG_RESULTS; echo ''; fi                 # Added in Ver 0.2
    COMMAND=''; SHOW_RESULTS >>$LOGFILE
  else
    if [ $BOL_VERBOSE -eq $TRUE ]; then PRINT_DATE_TIME; echo -e "No old PTR Record found, skipping deletion of old PTR Record"; fi
    export RETVAL=$SUCCESS; COMMAND="Skip Deletion"
    if [ $BOL_QUIET -ne $TRUE ]; then PRINT_DATE_TIME; LOG_RESULTS; echo ''; fi
  fi

  return $((RETVAL+A_REC_RETVAL))
};

# Add A record and PTR record in one function
function ADD_RECORD()
{
  if [ ${#PTR_RECORD} -eq 0 ]; then PTR_RECORD=$(SET_PTR); fi ## Added in Ver 0.2 if PTR is not set by host binary then set it from the IP Address
  ZONE=${HOST_NAME#*.}
  COMMAND="Add DNS A Record"									# Changed in Ver 0.2
  if [ $BOL_VERBOSE -eq $TRUE ]; then PRINT_DATE_TIME; printf "Adding New A Record: %s to zone: %s\n" "$HOST_NAME" "$ZONE"; fi
  if [ $BOL_DEBUG -eq $TRUE ]; then PRINT_DATE_TIME; echo "[Debug] $ST_BIN dns add $SERVER $ZONE $HOST_NAME A $IP_ADDRESS --username=$UPDATE_USER --password=$UPDATE_PASS"; fi
  printf "%s Add A Record %s %s to zone %s: " "$(date)" "$IP_ADDRESS" "$HOST_NAME" "$ZONE" >>$LOGFILE
  $ST_BIN dns add $SERVER $ZONE $HOST_NAME A $IP_ADDRESS --username=$UPDATE_USER --password=$UPDATE_PASS >/dev/null 2>/dev/null
  export RETVAL=$?; if [ $BOL_QUIET -ne $TRUE ]; then PRINT_DATE_TIME; LOG_RESULTS; echo ''; fi			# Added in Ver 0.2
  COMMAND=''; SHOW_RESULTS >>$LOGFILE

  ZONE=${PTR_RECORD#*.}
  COMMAND="Add DNS PRT Record"									# Changed in Ver 0.2
  if [ $BOL_VERBOSE -eq $TRUE ]; then PRINT_DATE_TIME; printf  "Adding New PTR Record: %s to zone: %s\n" "$PTR_RECORD" "$ZONE"; fi
  if [ $BOL_DEBUG -eq $TRUE ]; then PRINT_DATE_TIME; echo "[Debug] $ST_BIN dns add $SERVER $ZONE $PTR_RECORD PTR $HOST_NAME --username=$UPDATE_USER --password=$UPDATE_PASS"; fi
  printf "%s Add PTR Record %s to zone %s: " "$(date)" "$PTR_RECORD" "$ZONE" >>$LOGFILE
  $ST_BIN dns add $SERVER $ZONE $PTR_RECORD PTR $HOST_NAME --username=$UPDATE_USER --password=$UPDATE_PASS  >/dev/null 2>/dev/null
  export RETVAL=$?; if [ $BOL_QUIET -ne $TRUE ]; then PRINT_DATE_TIME; LOG_RESULTS; echo ''; fi			# Added in Ver 0.2
  COMMAND=''; SHOW_RESULTS >>$LOGFILE
  return $RETVAL
};

# Parse Command Line Arguments
for OPTIONS in $@; do
  case ${OPTIONS,,} in
    --verbose)		export BOL_VERBOSE=$TRUE;	export BOL_QUIET=$FALSE;;
    --quiet)		export BOL_VERBOSE=$FALSE;	export BOL_QUIET=$TRUE;;				# Added in Ver 0.2
    --force)		export BOL_FORCE=$TRUE;;								# Added in Ver 0.2
    -h | --help)	export BOL_HELP=$TRUE;;
    -v | --version)	SHOW_HEADER; exit $SUCCESS;;
    --debug)		export BOL_DEBUG=$TRUE;;
    --config=*)		export CONFIG_FILE="${OPTIONS#*=}";;
    --USER=*)		export UPDATE_USER="${OPTIONS#*=}";;
    --pass=*)		export UPDATE_PASS="${OPTIONS#*=}";;
    --ip=*)		export IP_ADDRESS="${OPTIONS#*=}";;
    --host=*)		export HOST_NAME="${OPTIONS#*=}";;
    --mac=*)		export MAC_ADDRESS="${OPTIONS#*=}";;
    --server=*)		export SERVER="${OPTIONS#*=}";;
    --ptr=*)		export PTR_RECORD="${OPTIONS#*=}";;
    --domain=*)		export DOMAIN="${OPTIONS#*=}";;
    --threshold=*)	export THRESHOLD="${OPTIONS#*=}";;							# Added in Ver 0.2
    --logfile=*)	export LOGFILE="${OPTIONS#*=}";;							# Added in Ver 0.2
    'add' | --add)	export SCRIPT_FUNCTION="ADD";;
    'delete' | --del)	export SCRIPT_FUNCTION="DELETE";;
  esac
done

if [ ${#LOGFILE}	-eq 0	]; then export LOGFILE="/var/log/dhcp-ddns.log";		fi		# Added in Ver 0.2
if [ ${#BOL_FORCE}	-eq 0	]; then export BOL_FORCE=$FALSE;				fi		# Added in Ver 0.2
if [ ${#CONFIG_FILE}	-eq 0	]; then export CONFIG_FILE="/etc/named/dns-update.conf";	fi
if [ -f $CONFIG_FILE		]; then . $CONFIG_FILE;						fi
if [ ${#THRESHOLD}	-eq 0	]; then declare -i THRESHOLD=2;					fi		# Added in Ver 0.2
if [ ${#IP_ADDRESS}	-eq 0	]; then export IP_ADDRESS=$2;					fi
if [ ${#MAC_ADDRESS}	-eq 0	]; then export MAC_ADDRESS=$3;					fi
if [ ${#HOST_NAME}	-eq 0	]; then export HOST_NAME=$4;					fi
if [ ${#PTR_RECORD}	-eq 0	]; then export PTR_RECORD=$(GET_PTR);				fi
if [ ${#A_RECORD}	-eq 0	]; then export A_RECORD=$(GET_A_RECORD);			fi
if [ ${#UPDATE_USER}	-eq 0	]; then export UPDATE_USER="dhcpduser";				fi
if [ ${#UPDATE_PASS}	-eq 0	]; then export UPDATE_PASS='Bl4ck3nd';				fi
if [ ${#SERVER}		-eq 0	]; then export SERVER="dc.gigaware.lan";			fi
if [ ${#DOMAIN}		-eq 0	]; then export DOMAIN="gigaware.lan";				fi
if [ ${#BOL_VERBOSE}	-eq 0	]; then export BOL_VERBOSE=$FALSE;				fi
if [ ${#BOL_QUIET}	-eq 0	]; then export BOL_QUIET=$FALSE;				fi
if [ $BOL_VERBOSE -eq $TRUE	]; then VERBOSE_HEADER;						fi

declare -i FINAL_VALUE=$SUCCESS
declare -i DEL_RETVAL=$SUCCESS
declare -i ADD_RETVAL=$SUCCESS
declare -i LOOP=$TRUE
declare -i COUNT=0

case $SCRIPT_FUNCTION in
  ADD)
    if [ ${#PTR_RECORD} -eq 0 ]; then PTR_RECORD=$(SET_PTR); fi					# If PTR record is NOT set, set it based on IP
    HOST_NAME=$HOST_NAME.$DOMAIN
    while [ $LOOP -eq $TRUE ]; do								# Added loop section here in Ver 0.2
      ((COUNT++))
      DEL_RECORD; DEL_RETVAL=$?
      ADD_RECORD; ADD_RETVAL=$?
      FINAL_VALUE=$((DEL_RETVAL+ADD_RETVAL))
      if [ $FINAL_VALUE -eq $SUCCESS ] || [ $COUNT -gt $THRESHOLD ] || [ $COUNT -eq $THRESHOLD ]; then LOOP=$FALSE; fi
    done
    ;;
  DELETE)
    HOST_NAME=$(SET_HOST)
    PTR_RECORD=$(SET_PTR)
    while [ $LOOP -eq $TRUE ]; do								 # Added loop section here in Ver 0.2
      ((COUNT++))
      DEL_RECORD; FINAL_VALUE=$?
      if [ $FINAL_VALUE -eq $SUCCESS ] || [ $COUNT -gt $THRESHOLD ] || [ $COUNT -eq $THRESHOLD ]; then LOOP=$FALSE; fi
    done
    ;;
  *)
    USAGE
    FINAL_VALUE=$?
    ;;
esac
RETVAL=$FINAL_VALUE
COMMAND="Command Results"
if [ $BOL_QUIET -ne $TRUE ] && [ $FINAL_VALUE -ne $SKIP ]; then PRINT_DATE_TIME; LOG_RESULTS; fi
echo -e '' >>$LOGFILE
exit $FINAL_VALUE
