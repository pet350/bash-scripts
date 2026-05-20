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
export VERSION="0.2"

# Define a few more binary variables
for DATA in curl st egrep chown sleep find; do
  export TEMP="$DATA"
  TEMP_BIN=$(GET_BIN)
  if [ $? -eq $SUCCESS ]; then
    export "${DATA^^}_BIN"="$TEMP_BIN"
  else
    echo -e "Missing required binary: $DATA"
    exit $FAILURE
  fi
  unset TEMP_BIN
  unset TEMP
done

function SHOW_RESULTS()
{
  if [ $RETVAL -eq $SUCCESS ]; then
    echo -e "Success. Return Value: $RETVAL"
  else
    echo -e "Failure. Return Value: $RETVAL"
  fi
};

function SHOW_DATE_TIME()
{
  printf "%b[ %10s @ %5s ] %b" $COLOR_LT_GREEN $(date +%F) $(date +%R) $COLOR_NORMAL
  return $SUCCESS
};

function SHOW_HEADER()
{
  echo -e "$RUN_CMD\t\t\tRemote Unlock Version: $VERSION\nBy: $AUTHOR\tDated: $MODIFIED"
  return $SUCCESS
};

function SHOW_NO_ARGS()
{
    SHOW_HEADER
    echo -e "for help: $RUN_CMD --help (or -h)\n"
    return $SUCCESS
};

function INFO_START_MESSAGE()
{
  declare -i RETVAL=$FAILURE
  if [ ${#1} -gt 0 ]; then
    SHOW_DATE_TIME
    CLB_TEXT; printf "[INFO] "
    CY_TEXT;  printf "Starting: "
    CC_TEXT;  printf "%s" "$1"
    CN_TEXT;  printf "\n"
    RETVAL=$SUCCESS
  else
    RETVAL=$FAILURE
  fi
  return $RETVAL
};

function INFO_EXEC_MESSAGE()
{
  declare -i RETVAL=$FAILURE
  if [ ${#1} -gt 0 ]; then
    SHOW_DATE_TIME
    CLB_TEXT; printf "[INFO] "
    CY_TEXT;  printf "Executing: "
    CC_TEXT;  printf "%s" "$1"
    CN_TEXT;  printf "\n"
    RETVAL=$SUCCESS
  else
    RETVAL=$FAILURE
  fi
  return $RETVAL
};

function INFO_FOUND_MESSAGE()
{
  declare -i RETVAL=$FAILURE
  if [ ${#1} -gt 0 ]; then
    SHOW_DATE_TIME
    CLB_TEXT; printf "[INFO] "
    CY_TEXT;  printf "Found: "
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
    SHOW_DATE_TIME
    CLB_TEXT; printf "[DEBUG] "
    CY_TEXT;  printf "Finished: "
    CC_TEXT;  printf "%s %s" "$1" "$(SHOW_RESULTS)"
    CN_TEXT;  printf "\n"
  fi
  return $RETVAL
};

function GET_OCTETS()
{
   declare -x IP="$1"
   FIRST=${IP%%.*}
   TEMP_IP=${IP#*.}
   SECOND=${TEMP_IP%%.*}
   TEMP_IP=${TEMP_IP#*.}
   THIRD=${TEMP_IP%%.*}
   FOURTH=${TEMP_IP#*.}
   if [ $BOL_VERBOSE -eq $TRUE ]; then INFO_FOUND_MESSAGE "IP Address: $FIRST.$SECOND.$THIRD.$FOURTH";	fi
   return $SUCCESS
};

for OPTIONS in $@; do
  case $OPTIONS in
    --verbose | -v)	declare -i BOL_VERBOSE=$TRUE;;
    --debug | -d)	declare -i BOL_DEBUG=$TRUE;;
    --ip=*)		declare -x IP_ADDRESS="${OPTIONS#*=}";;
    --max=*)		declare -i MAX="${OPTIONS#*=}";;
  esac
done

if [ ${#FIRST}		-eq 0 ]; then	declare -i FIRST=10;						fi
if [ ${#SECOND}		-eq 0 ]; then 	declare -i SECOND=20;						fi
if [ ${#THIRD}		-eq 0 ]; then 	declare -i THIRD=1;						fi
if [ ${#FOURTH}		-eq 0 ]; then 	declare -i FOURTH=0;						fi
if [ ${#MAX}		-eq 0 ]; then 	declare -i MAX=255;						fi
if [ ${#IP_ADDRESS}     -gt 0 ]; then   GET_OCTETS "$IP_ADDRESS";                                       fi
if [ ${#DOMAIN}		-eq 0 ]; then	declare -x DOMAIN="gigaware.lan";				fi
if [ ${#REALM}		-eq 0 ]; then	declare -x REALM="${DOMAIN^^}";					fi
if [ ${#USERNAME}	-eq 0 ]; then	declare -x USERNAME="dhcpduser@$REALM";				fi
if [ ${#PASS}		-eq 0 ]; then	declare -x PASS="Bl4ck3nd";					fi
if [ ${#SERVER}		-eq 0 ]; then	declare -x SERVER="kdc.$DOMAIN";				fi

function DEL_PTR()
{
    declare -i RETVAL=$FAILURE
    declare -x OPTIONS="dns delete $SERVER $ZONE. $FOURTH PTR $PTR_DATA --username=$USERNAME --password=$PASS"
    declare -x COMMAND="$ST_BIN $OPTIONS"

    echo -e "Executing: $COMMAND"
    $ST_BIN $OPTIONS
    RETVAL=$?
    LOG_RESULTS

    return $RETVAL
};

function GET_PTR_DATA()
{
    declare -i WORD_INDEX=-1
    declare -i BOL_WORD_INDEX=$FALSE
    declare -i RETVAL=$FAILURE
    while IFS= read LINE; do
        WORD_INDEX=-1
	BOL_WORD_INDEX=$FALSE
        for WORD in $LINE; do
	    case $WORD in
		'name')		BOL_WORD_INDEX=$TRUE;;
	    esac
	    if [ $BOL_WORD_INDEX -eq $TRUE ]; then ((WORD_INDEX++)); fi
	    if [ $WORD_INDEX -eq 2 ]; then echo $WORD; fi
        done
    done < <(nslookup $IP; RETVAL=$?)
    return $RETVAL
};

function GET_PTR_NAME()
{
    declare -i WORD_INDEX=-1
    declare -i RETVAL=$FAILURE
    while IFS= read LINE; do
        WORD_INDEX=-1
        for WORD in $LINE; do
            ((WORD_INDEX++))
            if [ $WORD_INDEX -eq 0 ]; then echo $WORD; fi
        done
    done < <(nslookup $IP; RETVAL=$?)
    return $RETVAL
};

declare -a PTR_NAME=();
declare -a PTR_DATA=();
declare -i RETVAL=$SUCCESS
declare -i SCRIPT_RETURN=$SUCCESS

while [ $FOURTH -lt $MAX ]; do
    ((FOURTH++))
    export IP=$FIRST.$SECOND.$THIRD.$FOURTH
    LEN=$(nslookup $IP|wc -l)

    PTR_DATA=();
    PTR_NAME=();

    INDEX=-1
    for DATA in $(GET_PTR_DATA); do
	((INDEX++))
	PTR_DATA[$((INDEX))]="$DATA"
    done
    if [ $BOL_DEBUG -eq $TRUE ]; then DEBUG_DONE_MESSAGE "${PTR_DATA[@]}"; fi

    INDEX=-1
    for DATA in $(GET_PTR_NAME); do
	((INDEX++))
	PTR_NAME[$((INDEX))]="$DATA"
    done
    if [ $BOL_DEBUG -eq $TRUE ]; then DEBUG_DONE_MESSAGE "${PTR_NAME[@]}"; fi

    declare -i PTR_DATA_LEN=${#PTR_DATA[@]}
    declare -i PTR_NAME_LEN=${#PTR_NAME[@]}

    echo -en "\rIP Address: $IP\tLength: $((LEN-1))\c\b"
    LEN=$(nslookup $IP|wc -l)
    if [ $LEN -gt 2 ]; then
        echo -e "\n\t$IP: has more than on PTR Record ${PTR_DATA[@]}, attempting to delete them...\n"
	INDEX=-1
	for DATA in ${PTR_DATA[@]}; do
	    ((INDEX++))
	    NAME="${PTR_NAME[$((INDEX))]}"
	    export ZONE=${NAME#$FOURTH.*}
	    printf "\tName: %-30s\t\tData: %-40s\t\tZone: %-30s\n" $NAME $DATA $ZONE
	    DEL_PTR
	    SCRIPT_RETURN=$((SCRIPT_RETURN+?))
	done
	echo ""
    fi
done
echo -e "\n"
exit $SCRIPT_RETURN
