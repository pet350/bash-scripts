#!/bin/bash
# Shell Script By: Peter Talbott
# 2022-01-17,18

## Whats new in Version 0.6 - 02-27-2023
## took out the loop at the end
## Took too long for DHCP server to issue IP
## Clients were timing ouit waiting
## Added option for MANUAL_ZONE

## Whats new in version 0.5
## Bugfixes to DELETE command

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

declare -x RUN_CMD="$(basename $0)"
declare -x VERSION="0.8.1"
declare -x AUTHOR="Peter Talbott"
declare -x MODIFIED="2023-2-27"

# Define a few more binary variables
for DATA in nslookup st host find; do
  declare -x TEMP="$DATA"
  TEMP_BIN=$(GET_BIN)
  if [ $? -eq $SUCCESS ]; then
    declare -x "${DATA^^}_BIN"="$TEMP_BIN"
  else
    echo -e "Missing required binary: $DATA"
    exit $FAILURE
  fi
  unset TEMP_BIN
  unset TEMP
done


# Statically Set Integer Variables
declare -i SKIP=255

# Define Global Arrays
declare -ag HOST_RECORD_NAME_ARRAY=();
declare -ag HOST_RECORD_ADDRESS_ARRAY=();

function DEBUG_START_MESSAGE()
{
  declare -i RETVAL=$FAILURE
  if [ ${#1} -gt 0 ]; then
    PRINT_DATE_TIME
    CLB_TEXT; printf "[Debug] "
    CY_TEXT;  printf "Starting: "
    CC_TEXT;  printf "%s" "$1"
    CN_TEXT;  printf "\n"
    RETVAL=$SUCCESS
  else
    RETVAL=$FAILURE
  fi
  return $RETVAL
};

function DEBUG_EXEC_MESSAGE()
{
  declare -i RETVAL=$FAILURE
  if [ ${#1} -gt 0 ]; then
    PRINT_DATE_TIME
    CLB_TEXT; printf "[Debug] "
    CY_TEXT;  printf "Executing: "
    CC_TEXT;  printf "%s" "$1"
    CN_TEXT;  printf "\n"
    RETVAL=$SUCCESS
  else
    RETVAL=$FAILURE
  fi
  return $RETVAL
};

function DEBUG_DONE_MESSAGE()
{
  if [ ${#1} -gt 0 ]; then
    PRINT_DATE_TIME
    CLB_TEXT; printf "[Debug] "
    CY_TEXT;  printf "Finished: "
    CC_TEXT;  printf "%s %s" "$1" "$(SHOW_RESULTS)"
    CN_TEXT;  printf "\n\n"
  fi
  return $RETVAL
};


# Simple Function To Display The Date and Time in Color
function PRINT_DATE_TIME()
{
  printf "%b[ %10s @ %5s ] %b" $COLOR_LT_GREEN $(date +%F) $(date +%R) $COLOR_NORMAL
  return $SUCCESS
};

# Simple Function to Display a Header
function SHOW_HEADER()
{
  declare -i RETVAL=$SUCCESS
  if [ $BOL_DEBUG -eq $TRUE ]; then DEBUG_START_MESSAGE "SHOW_HEADER" >/dev/stderr; fi
  CLB_TEXT; printf "%-24s" $RUN_CMD; CY_TEXT; printf "Version: "; CC_TEXT; printf "%-4s" $VERSION; CN_TEXT; printf "\n"
  CLB_TEXT; printf "By: "; CLR_TEXT; printf "%-20s" "$AUTHOR"; CLB_TEXT; printf "Dated: "; CLR_TEXT; printf "%-20s" "$MODIFIED"; CN_TEXT; printf "\n"
  if [ $BOL_DEBUG -eq $TRUE ]; then DEBUG_DONE_MESSAGE "SHOW_HEADER" >/dev/stderr; fi
  return $RETVAL
};

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
  if [ $BOL_DEBUG -eq $TRUE ]; then DEBUG_START_MESSAGE "USAGE" >/dev/stderr; fi
  echo -e "\nUSAGE:\t\t\t--help | -h for more help"
  echo -e "  $RUN_CMD add ip-address mac-address hostname"
  echo -e "  $RUN_CMD delete ip-address mac-address hostname"
  return $SKIP
};

function VERBOSE_HEADER()
{
  declare -i RETVAL=$SUCCESS
  SHOW_HEADER
  if [ $BOL_DEBUG -eq $TRUE ]; then DEBUG_START_MESSAGE "VERBOSE_HEADER" >/dev/stderr; fi
  CC_TEXT
  echo ''
  echo -e "Script Function:\t$SCRIPT_FUNCTION"
  echo -e "IP Address:\t\t$IP_ADDRESS"
  echo -e "MAC Address:\t\t$MAC_ADDRESS"
  echo -e "Host Name:\t\t$HOST_NAME"
  echo -e "Existing A Record:\t$A_RECORD"
  echo -e "Existing PTR Record:\t$PTR_RECORD"
  echo -e "Log Filename:\t\t$LOGFILE"
  echo -e "VLAN:\t\t\t$VLAN"
  echo ''
  CN_TEXT
  if [ $BOL_DEBUG -eq $TRUE ]; then DEBUG_DONE_MESSAGE "VERBOSE_HEADER" >/dev/stderr; fi
  return $RETVAL
};

function GET_VLAN_ID()
{
  declare -i RETVAL=$SUCCESS
  if [ $BOL_DEBUG -eq $TRUE ]; then DEBUG_START_MESSAGE "GET_VLAN_ID" >/dev/stderr; fi
  declare -x IP_ADDRESS=$1
  declare -x TEMP_IP=${IP_ADDRESS#*.}
  declare -x SECOND=${TEMP_IP%%.*}
  case $SECOND in
    '16')    declare -i VLAN_ID=10;;
       *)    declare -i VLAN_ID=$SECOND;;
  esac
  echo -e "$VLAN_ID"
  if [ $BOL_DEBUG -eq $TRUE ]; then DEBUG_DONE_MESSAGE "GET_VLAN_ID: $VLAN_ID" >/dev/stderr; fi
  return $RETVAL
};


# Get and set PTR Record from host binary based on IP Address
function GET_PTR()
{
  declare -i INDEX=-1
  declare -i RETVAL=$SUCCESS
  if [ $BOL_DEBUG -eq $TRUE ]; then DEBUG_START_MESSAGE "GET_PTR" >/dev/stderr; fi
  if [ ${#IP_ADDRESS} -ne 0 ]; then
    if [ $BOL_DEBUG -eq $TRUE ]; then DEBUG_EXEC_MESSAGE "$HOST_BIN -4 $IP_ADDRESS" >/dev/stderr; fi
    HOST_DATA=$($HOST_BIN -4 $IP_ADDRESS 2>/dev/null; declare -i RETVAL=$?)
    if [ $BOL_DEBUG -eq $TRUE ]; then DEBUG_DONE_MESSAGE "$HOST_BIN -4 $IP_ADDRESS" >/dev/stderr; fi
    if [ $BOL_DEBUG -eq $TRUE ]; then DEBUG_DONE_MESSAGE "Host Data: $HOST_DATA; Retval: $RETVAL" >/dev/stderr; fi
    if [ $RETVAL -eq $SUCCESS ]; then
      if [ $BOL_DEBUG -eq $TRUE ]; then DEBUG_EXEC_MESSAGE "Data Loop" >/dev/stderr; fi
      for DATA in $HOST_DATA; do
        ((INDEX++))
        if [ $INDEX -eq 0 ]; then
	    case ${DATA,,} in
		host)	INDEX=-1;;
		*) 	OUTPUT="$DATA";	echo $DATA;;
	    esac
	fi
      done
      if [ $BOL_DEBUG -eq $TRUE ]; then DEBUG_DONE_MESSAGE "Data Loop: $OUTPUT" >/dev/stderr; fi
    else
      RETVAL=$FAILURE
    fi
  else
    RETVAL=$FAILURE
  fi
  if [ $BOL_DEBUG -eq $TRUE ]; then DEBUG_DONE_MESSAGE "GET_PTR: $RETVAL" >/dev/stderr; fi
  return $RETVAL
};

# Get and set A record from host binary based on IP address
function GET_A_RECORD()
{
  declare INDEX=-1
  declare RETVAL=$SUCCESS
  if [ $BOL_DEBUG -eq $TRUE ]; then DEBUG_START_MESSAGE "GET_A_RECORD" >/dev/stderr; fi
  if [ ${#HOST_NAME} -ne 0 ]; then
    if [ $BOL_DEBUG -eq $TRUE ]; then DEBUG_EXEC_MESSAGE "$HOST_BIN -4 $HOST_NAME" >/dev/stderr; fi
    HOST_DATA=$($HOST_BIN -4 $HOST_NAME 2>/dev/null; declare -i RETVAL=$?)
    if [ $BOL_DEBUG -eq $TRUE ]; then DEBUG_DONE_MESSAGE "$HOST_BIN -4 $HOST_NAME" >/dev/stderr; fi
    if [ $RETVAL -eq $SUCCESS ]; then
      for DATA in $HOST_DATA; do
        ((INDEX++))
        if [ $INDEX -eq 3 ]; then echo $DATA; fi
      done
    else
      RETVAL=$FAILURE
    fi
  else
    RETVAL=$FAILURE
  fi
  if [ $BOL_DEBUG -eq $TRUE ]; then DEBUG_DONE_MESSAGE "GET_A_RECORD" >/dev/stderr; fi
  return $RETVAL
};

# Set PTR based on IP Address without the use of host binary
function SET_PTR()
{
  declare -i INDEX=-1
  declare -i RETVAL=$SUCCESS
  declare -x TEMP_IP=$IP_ADDRESS
  declare -x TEMP_PTR=""
  if [ $BOL_DEBUG -eq $TRUE ]; then DEBUG_START_MESSAGE "SET_PTR" >/dev/stderr; fi
  while [ $INDEX -ne 3 ]; do
    ((INDEX++))
    LAST_OCTET=${TEMP_IP##*.} # Store Last Octet
    TEMP_IP=${TEMP_IP%.*}     # Strip Last Octet
    TEMP_PTR="$TEMP_PTR${LAST_OCTET}."
  done
  TEMP_PTR="${TEMP_PTR}in-addr.arpa"
  echo $TEMP_PTR
  if [ $BOL_DEBUG -eq $TRUE ]; then DEBUG_DONE_MESSAGE "SET_PTR" >/dev/stderr; fi
  return $RETVAL
};

# Set host based on host binary
function SET_HOST()
{
  declare -i INDEX=-1
  if [ $BOL_DEBUG -eq $TRUE ]; then DEBUG_START_MESSAGE "SET_HOST" >/dev/stderr; fi
  for DATA in $($HOST_BIN $IP_ADDRESS); do									# Bug fixed in Ver 0.2
    ((INDEX++))
  done
  echo $DATA; declare -i RETVAL=$?
  if [ $BOL_DEBUG -eq $TRUE ]; then DEBUG_DONE_MESSAGE "SET_HOST" >/dev/stderr; fi
  return $RETVAL
};

# Function will populate HOST_RECORD_ARRAY
# Function Added: Version 0.3 March 30th, 2022
function GET_HOST_RECORD_ARRAY()
{
  declare -i FUNCTION_RETURN=$SUCCESS
  declare -i ADDRESS_INDEX=-1
  declare -i NAME_INDEX=-1
  declare -i BOL_SERVER=$FALSE
  declare -i BOL_NAME=$FALSE
  declare -i BOL_ADDRESS=$FALSE
  declare -i RECORD_LENGTH=$($NSLOOKUP_BIN $HOST_NAME | $WC_BIN -l)

  if [ $BOL_DEBUG -eq $TRUE ]; then DEBUG_START_MESSAGE "GET_HOST_RECORD_ARRAY" >/dev/stderr; fi
  while IFS= read LINE; do
    for WORD in ${LINE,,}; do
      if [ $BOL_NAME    -eq $TRUE ]; then ((NAME_INDEX++));	HOST_RECORD_NAME_ARRAY[$((NAME_INDEX))]="$WORD";		fi
      if [ $BOL_ADDRESS	-eq $TRUE ]; then ((ADDRESS_INDEX++));	HOST_RECORD_ADDRESS_ARRAY[$((ADDRESS_INDEX))]="$WORD";		fi
      case $WORD in
        'address:')	BOL_ADDRESS=$TRUE;;
	'name:')	BOL_NAME=$TRUE;;
	'server:')	BOL_SERVER=$TRUE;;
        *)		BOL_SERVER=$FALSE;	BOL_NAME=$FALSE;	BOL_ADDRESS=$FALSE;;
      esac
    done
  done < <( $NSLOOKUP_BIN $HOST_NAME | $TAIL_BIN --lines=$((RECORD_LENGTH-2)) )
  if [ $NAME_INDEX -ne $ADDRESS_INDEX ] || [ $NAME_INDEX -eq -1 ] || [ $ADDRESS_INDEX -eq -1 ]; then FUNCTION_RETURN=$FAILURE;	fi
  declare -i RETVAL=$FUNCTION_RETURN
  if [ $BOL_DEBUG -eq $TRUE ]; then DEBUG_DONE_MESSAGE "GET_HOST_RECORD_ARRAY" >/dev/stderr; fi
  return $FUNTION_RETURN
};

# Delete A record and PTR record in one function
# Function Modified: Version 0.3 March 31st, 2022
function DEL_RECORD()
{
  if [ $BOL_DEBUG -eq $TRUE ]; then DEBUG_START_MESSAGE "DEL_RECORD" >/dev/stderr; fi
  # Delete A Record Section
  if [ ${#A_RECORD} -ne 0 ]; then
    if [ ${#MANUAL_ZONE} -eq 0 ]; then ZONE=${HOST_NAME#*.}; else ZONE=$MANUAL_ZONE; fi
    COMMAND="Delete DNS A Record"
    GET_HOST_RECORD_ARRAY
    for LOOP_IP_ADDRESS in ${HOST_RECORD_ADDRESS_ARRAY[@]}; do										 # Changed in Ver 0.2
      if [ $BOL_VERBOSE -eq $TRUE ]; then PRINT_DATE_TIME; printf  "Deleting Old A Record: %s from zone: %s\n" "$A_RECORD" "$ZONE"; fi
      if [ $BOL_DEBUG -eq $TRUE ]; then PRINT_DATE_TIME;echo "[Debug] $ST_BIN dns delete $SERVER $ZONE ${HOST_NAME%%.*} A $LOOP_IP_ADDRESS --username=$UPDATE_USER --password=$UPDATE_PASS" >/dev/stderr; fi
      printf "%s Delete old DNS A Record %s %s from zone %s: " "$(date)" "$LOOP_IP_ADDRESS" "${HOST_NAME%%.*}" "$ZONE" >>$LOGFILE
      $ST_BIN dns delete $SERVER $ZONE ${HOST_NAME%%.*} A $LOOP_IP_ADDRESS --username=$UPDATE_USER --password=$UPDATE_PASS >/dev/null 2>/dev/null
      declare -x RETVAL=$?; if [ $BOL_QUIET -ne $TRUE ]; then PRINT_DATE_TIME; LOG_RESULTS; echo ''; fi                 # Added in Ver 0.2
      declare -x A_REC_RETVAL=$RETVAL
      COMMAND=''; SHOW_RESULTS >>$LOGFILE
    done
  else
    if [ $BOL_VERBOSE -eq $TRUE ]; then PRINT_DATE_TIME; echo -e "No old A Record found, skipping deletion of old A Record"; fi
    declare -x RETVAL=$SUCCESS; A_REC_RETVAL=$RETVAL; COMMAND="Skip Deletion"
    if [ $BOL_QUIET -ne $TRUE ]; then PRINT_DATE_TIME; LOG_RESULTS; echo ''; fi
  fi

  # Delete PTR Record Section
  if [ ${#PTR_RECORD} -eq 0 ] && [ $BOL_FORCE -eq $TRUE ]; then PTR_RECORD=$(SET_PTR); fi ## Added in Ver 0.2 if PTR is not set by host binary and force is set then set it from the IP Address
  if [ ${#PTR_RECORD} -ne 0 ]; then
    ZONE=${PTR_RECORD#*.}
    COMMAND="Delete DNS PTR Record"										 # Changed in Ver 0.2
    if [ $BOL_VERBOSE -eq $TRUE ]; then PRINT_DATE_TIME; printf  "Deleting Old PTR Record: %s from zone: %s\n" "$PTR_RECORD" "$ZONE"; fi
    if [ $BOL_DEBUG -eq $TRUE ]; then PRINT_DATE_TIME; echo "[Debug] $ST_BIN dns delete $SERVER $ZONE $PTR_RECORD PTR $HOST_NAME --username=$UPDATE_USER --password=$UPDATE_PASS" >/dev/stderr; fi
    printf "%s Delete old DNS PTR Record %s %s from zone %s: " "$(date)" "$PTR_RECORD" "$HOST_NAME" "$ZONE" >>$LOGFILE
    $ST_BIN dns delete $SERVER $ZONE $PTR_RECORD PTR $HOST_NAME --username=$UPDATE_USER --password=$UPDATE_PASS  >/dev/null 2>/dev/null
    declare -x RETVAL=$?; if [ $BOL_QUIET -ne $TRUE ]; then PRINT_DATE_TIME; LOG_RESULTS; echo ''; fi                 # Added in Ver 0.2
    COMMAND=''; SHOW_RESULTS >>$LOGFILE
  else
    if [ $BOL_VERBOSE -eq $TRUE ]; then PRINT_DATE_TIME; echo -e "No old PTR Record found, skipping deletion of old PTR Record"; fi
    declare -x RETVAL=$SUCCESS; COMMAND="Skip Deletion"
    if [ $BOL_QUIET -ne $TRUE ]; then PRINT_DATE_TIME; LOG_RESULTS; echo ''; fi
  fi
  declare -i RETVAL=$((RETVAL+A_REC_RETVAL))
  if [ $BOL_DEBUG -eq $TRUE ]; then DEBUG_DONE_MESSAGE "DEL_RECORD" >/dev/stderr; fi
  return $RETVAL
};

# Add A record and PTR record in one function
function ADD_RECORD()
{
  if [ $BOL_DEBUG -eq $TRUE ]; then DEBUG_START_MESSAGE "ADD_RECORD" >/dev/stderr; fi
  if [ ${#PTR_RECORD} -eq 0 ]; then PTR_RECORD=$(SET_PTR); fi ## Added in Ver 0.2 if PTR is not set by host binary then set it from the IP Address
  if [ ${#MANUAL_ZONE} -eq 0 ]; then ZONE=${HOST_NAME#*.}; else ZONE=$MANUAL_ZONE; fi
  COMMAND="Add DNS A Record"									# Changed in Ver 0.2
  if [ $BOL_VERBOSE -eq $TRUE ]; then PRINT_DATE_TIME; printf "Adding New A Record: %s to zone: %s\n" "$HOST_NAME" "$ZONE"; fi
  if [ $BOL_DEBUG -eq $TRUE ]; then PRINT_DATE_TIME; echo "[Debug] $ST_BIN dns add $SERVER $ZONE $HOST_NAME A $IP_ADDRESS --username=$UPDATE_USER --password=$UPDATE_PASS" >/dev/stderr; fi
  printf "%s Add A Record %s %s to zone %s: " "$(date)" "$IP_ADDRESS" "$HOST_NAME" "$ZONE" >>$LOGFILE
  $ST_BIN dns add $SERVER $ZONE $HOST_NAME A $IP_ADDRESS --username=$UPDATE_USER --password=$UPDATE_PASS >/dev/null 2>/dev/null
  declare -x RETVAL=$?; if [ $BOL_QUIET -ne $TRUE ]; then PRINT_DATE_TIME; LOG_RESULTS; echo ''; fi			# Added in Ver 0.2
  COMMAND=''; SHOW_RESULTS >>$LOGFILE

  ZONE=${PTR_RECORD#*.}
  COMMAND="Add DNS PRT Record"									# Changed in Ver 0.2
  if [ $BOL_VERBOSE -eq $TRUE ]; then PRINT_DATE_TIME; printf  "Adding New PTR Record: %s to zone: %s\n" "$PTR_RECORD" "$ZONE"; fi
  if [ $BOL_DEBUG -eq $TRUE ]; then PRINT_DATE_TIME; echo "[Debug] $ST_BIN dns add $SERVER $ZONE $PTR_RECORD PTR $HOST_NAME --username=$UPDATE_USER --password=$UPDATE_PASS" >/dev/stderr; fi
  printf "%s Add PTR Record %s to zone %s: " "$(date)" "$PTR_RECORD" "$ZONE" >>$LOGFILE
  $ST_BIN dns add $SERVER $ZONE $PTR_RECORD PTR $HOST_NAME --username=$UPDATE_USER --password=$UPDATE_PASS  >/dev/null 2>/dev/null
  declare -x RETVAL=$?; if [ $BOL_QUIET -ne $TRUE ]; then PRINT_DATE_TIME; LOG_RESULTS; echo ''; fi			# Added in Ver 0.2
  COMMAND=''; SHOW_RESULTS >>$LOGFILE
  if [ $BOL_DEBUG -eq $TRUE ]; then DEBUG_DONE_MESSAGE "ADD_RECORD" >/dev/stderr; fi
  return $RETVAL
};

declare -i OPT_INDEX=-1
# Parse Command Line Arguments
for OPTIONS in $@; do
  ((OPT_INDEX++))
  case ${OPTIONS,,} in
    --verbose)		declare -i BOL_VERBOSE=$TRUE;	declare -i BOL_QUIET=$FALSE;;
    --quiet)		declare -i BOL_VERBOSE=$FALSE;	declare -i BOL_QUIET=$TRUE;;				# Added in Ver 0.2
    --force)		declare -i BOL_FORCE=$TRUE;;								# Added in Ver 0.2
    -h | --help)	declare -i BOL_HELP=$TRUE;;
    -v | --version)	SHOW_HEADER; exit $SUCCESS;;
    -d | --debug)	declare -i BOL_DEBUG=$TRUE;;
    --config=*)		declare -x CONFIG_FILE="${OPTIONS#*=}";;
    --USER=*)		declare -x UPDATE_USER="${OPTIONS#*=}";;
    --pass=*)		declare -x UPDATE_PASS="${OPTIONS#*=}";;
    --ip=*)		declare -x IP_ADDRESS="${OPTIONS#*=}";;
    --host=*)		declare -x HOST_NAME="${OPTIONS#*=}";;
    --mac=*)		declare -x MAC_ADDRESS="${OPTIONS#*=}";;
    --server=*)		declare -x SERVER="${OPTIONS#*=}";;
    --ptr=*)		declare -x PTR_RECORD="${OPTIONS#*=}";;
    --zone=*)		declare -x MANUAL_ZONE="${OPTIONS#*=}";;
    --domain=*)		declare -x DOMAIN="${OPTIONS#*=}";;
    --threshold=*)	declare -x THRESHOLD="${OPTIONS#*=}";;							# Added in Ver 0.2
    --logfile=*)	declare -x LOGFILE="${OPTIONS#*=}";;							# Added in Ver 0.2
    'add' | --add)	declare -x SCRIPT_FUNCTION="ADD";;
    'delete' | --del)	declare -x SCRIPT_FUNCTION="DELETE";;
    --use-vlan)		declare -i BOL_VLAN=$TRUE;;
    --bw)		declare -i BOL_COLOR=$FALSE;;
    --color)		declare -i BOL_COLOR=$TRUE;;
    --force-color)	declare -i BOL_FORCE_COLOR=$TRUE;	declare -i BOL_COLOR=$TRUE;;
    *)
	if   [ $OPT_INDEX -eq 1 ]; then IP_ADDRESS="$OPTIONS"
	elif [ $OPT_INDEX -eq 2 ]; then MAC_ADDRESS="$OPTIONS"
	elif [ $OPT_INDEX -eq 3 ]; then HOST_NAME="$OPTIONS"
	else echo -e "Unknown Option: $OPTIONS"
	fi ;;
  esac
done

if [ ${#BOL_VLAN}	-eq 0	]; then declare -i BOL_VLAN=$FALSE;					fi
if [ $BOL_COLOR	  -eq $TRUE     ]; then INIT_COLOR_SHORTHAND;						fi
if [ ${#LOGFILE}	-eq 0	]; then declare -x LOGFILE="/var/log/dhcp-ddns.log";			fi	# Added in Ver 0.2
if [ ${#BOL_FORCE}	-eq 0	]; then declare -i BOL_FORCE=$FALSE;					fi	# Added in Ver 0.2
if [ ${#CONFIG_FILE}	-eq 0	]; then declare -x CONFIG_FILE="/etc/named/dns-update.conf";		fi
if [ -f $CONFIG_FILE		]; then . $CONFIG_FILE;							fi
if [ ${#THRESHOLD}	-eq 0	]; then declare -i THRESHOLD=2;						fi	# Added in Ver 0.2
if [ ${#IP_ADDRESS}	-eq 0	]; then declare -x IP_ADDRESS=$2;					fi
if [ ${#VLAN}		-eq 0	]; then declare -x VLAN="vlan$(GET_VLAN_ID $IP_ADDRESS)";		fi	# Added in Ver 0.8.1
if [ ${#MAC_ADDRESS}	-eq 0	]; then declare -x MAC_ADDRESS=$3;					fi
if [ ${#HOST_NAME}	-eq 0	]; then declare -x HOST_NAME=$4;					fi
if [ ${#PTR_RECORD}	-eq 0	]; then declare -x PTR_RECORD=$(GET_PTR);				fi
if [ ${#A_RECORD}	-eq 0	]; then declare -x A_RECORD=$(GET_A_RECORD);				fi
if [ ${#UPDATE_USER}	-eq 0	]; then declare -x UPDATE_USER="dhcpduser@GIGAWARE.LAN";		fi
if [ ${#UPDATE_PASS}	-eq 0	]; then declare -x UPDATE_PASS='Bl4ck3nd';				fi
if [ ${#SERVER}		-eq 0	]; then declare -x SERVER="lxc.gigaware.lan";				fi	# Changed 06/05/2025
if [ ${#DOMAIN}		-eq 0	]; then declare -x DOMAIN="gigaware.lan";				fi
if [ $BOL_VLAN	  -eq $TRUE	]; then declare -x DOMAIN="$VLAN.$DOMAIN";				fi	# Added in Ver 0.8.1
if [ ${#BOL_VERBOSE}	-eq 0	]; then declare -x BOL_VERBOSE=$FALSE;					fi
if [ ${#BOL_QUIET}	-eq 0	]; then declare -x BOL_QUIET=$FALSE;					fi
if [ $BOL_VERBOSE -eq $TRUE	]; then VERBOSE_HEADER;							fi
if [ ${#BOL_LOOP}	-eq 0   ]; then declare -i BOL_LOOP=$FALSE;					fi

declare -i FINAL_VALUE=$SUCCESS
declare -i DEL_RETVAL=$SUCCESS
declare -i ADD_RETVAL=$SUCCESS
declare -i LOOP=$TRUE
declare -i COUNT=0

case $SCRIPT_FUNCTION in
  ADD)
    if [ ${#PTR_RECORD} -eq 0 ]; then PTR_RECORD=$(SET_PTR); fi					# If PTR record is NOT set, set it based on IP
    HOST_NAME=$HOST_NAME.$DOMAIN
#    while [ $LOOP -eq $TRUE ]; do								# Added loop section here in Ver 0.2
#      ((COUNT++))
#      DEL_RECORD; DEL_RETVAL=$?
      ADD_RECORD; ADD_RETVAL=$?
      FINAL_VALUE=$((DEL_RETVAL+ADD_RETVAL))
#      if [ $BOL_LOOP -eq $FALSE  ] || [ $FINAL_VALUE -eq $SUCCESS ] \
#      || [ $COUNT -gt $THRESHOLD ] || [ $COUNT     -eq $THRESHOLD ]; then LOOP=$FALSE; fi
#    done
    ;;
  DELETE)
    HOST_NAME="$HOST_NAME.$DOMAIN"
    PTR_RECORD=$(SET_PTR)
    A_RECORD=$(GET_A_RECORD)
    if [ $BOL_DEBUG -eq $TRUE ]; then
	echo -e "Hostname: $HOST_NAME"
        echo -e "A Record: $A_RECORD"
	echo -e "PTR Record: $PTR_RECORD"
    fi
#    while [ $LOOP -eq $TRUE ]; do								 # Added loop section here in Ver 0.2
#      ((COUNT++))
      DEL_RECORD; FINAL_VALUE=$?
#      if [ $BOL_LOOP -eq $FALSE  ] || [ $FINAL_VALUE -eq $SUCCESS ] \
#      || [ $COUNT -gt $THRESHOLD ] || [ $COUNT     -eq $THRESHOLD ]; then LOOP=$FALSE; fi
#    done
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
