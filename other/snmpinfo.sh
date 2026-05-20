#!/bin/bash
# keytab.sh - Generating Kerberos Keytabs
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
export AUTHOR="Peter Talbott"
export MODIFIED="2023-04-06"

# Define a few more binary variables
for DATA in snmpwalk curl egrep chown sleep cat wc find true; do
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

declare -a CATAGORY_ARRAY=("sysContact" "sysName" "sysLocation" "sysServices" "sysORLastChange" "sysORID" "hrSWInstalledNam" \
    "sysORDescr" "ifNumber" "ifIndex" "ifDescr" "ifType" "ifMtu" "ifSpeed" "ifPhysAddress" "ifAdminStatus" "ifOperStatus" "ifLastChange" "ifInOctets" "ifInUcastPkts" );
declare -a ENABLE_ARRAY=();

# Set each cell in array to 0
declare -i INDEX=-1
for NULL in ${CATAGORY_ARRAY[@]}; do
    ((INDEX++))
    ENABLE_ARRAY[$((INDEX))]=$FALSE
done

for OPTIONS in $@; do
    case $OPTIONS in
	-h  | --help)		declare -i BOL_HELP=$TRUE;;
	-d  | --debug)		declare -i BOL_DEBUG=$TRUE;;
	--bw)			declare -i BOL_COLOR=$FALSE;;
	-v  | --verbose)	declare -i BOL_VERBOSE=$TRUE;;
	--server=*)		declare -x SNMP_SERVER="${OPTIONS#*=}";;
	--community=*)		declare -x SNMP_COMMUNITY="${OPTIONS#*=}";;
	--values-only)  	declare -i BOL_VAL=$FALSE;;
        -nj | --no-justified)	declare -i BOL_JUSTIFIED=$FALSE;;
	-j  | --justified)	declare -i BOL_JUSTIFIED=$TRUE;;
	--all)			declare -i BOL_ALL=$TRUE;;
	--contact)		ENABLE_ARRAY[0]=$TRUE;;
	--name)			ENABLE_ARRAY[1]=$TRUE;;
	--location)		ENABLE_ARRAY[2]=$TRUE;;
	--services)		ENABLE_ARRAY[3]=$TRUE;;
	--last-change)		ENABLE_ARRAY[4]=$TRUE;;
	--orid)			ENABLE_ARRAY[5]=$TRUE;;
	--installed)		ENABLE_ARRAY[6]=$TRUE;;
	--desc)			ENABLE_ARRAY[7]=$TRUE;;
	--ifnumber)		ENABLE_ARRAY[8]=$TRUE;;
	*)
	    declare -i TEMP_LEN=${#CATAGORY_ARRAY[@]}
	    CATAGORY_ARRAY[$((TEMP_LEN))]=$OPTIONS
	    ENABLE_ARRAY[$((TEMP_LEN))]=$TRUE
	    ;;
    esac
done

declare -a HELP_ARRAY=("--contact" "Display Contact Info\n" "--name" "Display server name\n" "--location" "Display location string\n" 	\
  "--services" "Display Services String\n" "--last-change" "Display Last Change String\n" "--orid" "Display orid string\n" 		\
  "--installed" "Display Installed Packages\n" "--ifnumber" "Display number of network interfaces\n" "--desc" "Display description" );

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
  CLB_TEXT; printf "%-24s" $RUN_CMD; CY_TEXT; printf "Version: "; CC_TEXT; printf "%-4s" $VERSION; CN_TEXT; printf "\n"
  CLB_TEXT; printf "By: "; CLR_TEXT; printf "%-20s" "$AUTHOR"; CLB_TEXT; printf "Dated: "; CLR_TEXT; printf "%-20s" "$MODIFIED"; CN_TEXT; printf "\n"
  return $SUCCESS
};

function SHOW_NO_ARGS()
{
    SHOW_HEADER
    CLG_TEXT
    echo -e "for help: $RUN_CMD --help (or -h)\n"
    CN_TEXT
    return $SUCCESS
};

function DEBUG_START_MESSAGE()
{
  declare -i RETVAL=$FAILURE
  if [ ${#1} -gt 0 ]; then
    SHOW_DATE_TIME
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
    SHOW_DATE_TIME
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

function DEBUG_FOUND_MESSAGE()
{
  declare -i RETVAL=$FAILURE
  if [ ${#1} -gt 0 ]; then
    SHOW_DATE_TIME
    CLB_TEXT; printf "[Debug] "
    CY_TEXT;  printf "Found: "
    CC_TEXT;  printf "%s" "$1"
    CN_TEXT;  printf "\n"
    RETVAL=$SUCCESS
  else
    RETVAL=$FAILURE
  fi
  return $RETVAL
};

function DEBUG_INFO_MESSAGE()
{
  declare -i RETVAL=$FAILURE
  if [ ${#1} -gt 0 ]; then
    SHOW_DATE_TIME
    CLB_TEXT; printf "[Debug] "
    CY_TEXT;  printf "Information: "
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
    CLB_TEXT; printf "[Debug] "
    CY_TEXT;  printf "Finished: "
    CC_TEXT;  printf "%s %s" "$1" "$(SHOW_RESULTS)"
    CN_TEXT;  printf "\n"
  fi
  return $RETVAL
};



if [ $BOL_COLOR   	    -eq $TRUE ]; then INIT_COLOR_SHORTHAND;                     		                fi
if [ ${#BOL_VERBOSE}		-eq 0 ]; then declare -i BOL_VERBOSE=$FALSE;						fi
if [ ${#BOL_ALL}		-eq 0 ]; then declare -i BOL_ALL=$FALSE;						fi
if [ ${#BOL_DEBUG}		-eq 0 ]; then declare -i BOL_DEBUG=$FALSE;						fi
if [ ${#BOL_VERSION}		-eq 0 ]; then declare -i BOL_VERSION=$FALSE;						fi
if [ ${#BOL_TEST}		-eq 0 ]; then declare -i BOL_TEST=$FALSE;						fi
if [ ${#BOL_VAL}		-eq 0 ]; then declare -i BOL_VAL=$TRUE;							fi
if [ ${#BOL_JUSTIFIED}		-eq 0 ]; then declare -i BOL_JUSTIFIED=$TRUE;						fi
if [ ${#SNMP_OPTIONS}		-eq 0 ]; then declare -x SNMP_OPTIONS="-mALL -v1";					fi
if [ ${#SNMP_COMMUNITY}		-eq 0 ]; then declare -x SNMP_COMMUNITY="GIGAWARE";					fi
if [ $BOL_ALL		    -eq $TRUE ]; then declare -i BOL_REQUIRED=$TRUE;						fi
if [ $BOL_HELP		    -eq $TRUE ]; then DO_HELP; exit $SUCCESS;							fi
if [ $BOL_DEBUG		    -eq $TRUE ]; then declare -x ERR_OUT="/dev/stderr"; else declare -x ERR_OUT="/dev/null";	fi

# Enable Catagories
if [ ${#BOL_REQUIRED} -eq 0 ]; then declare -i BOL_REQUIRED=$FALSE; fi
for ENABLE in ${ENABLE_ARRAY[@]}; do
    ((INDEX++))
    if [ $ENABLE -eq $TRUE ]; then declare -i BOL_REQUIRED=$TRUE; fi
done

if [ ${#SNMP_OPTIONS} -ne 0 ] && [ ${#SNMP_COMMUNITY} -ne 0 ] && [ ${#SNMP_SERVER} -ne 0 ] && [ $BOL_REQUIRED -eq $TRUE ]; then
    if [ $BOL_JUSTIFIED -eq $TRUE ]; then
      declare -i INDEX=-1
      for ENABLE in ${ENABLE_ARRAY[@]}; do
        ((INDEX++))
	declare -i COUNT=0
	if [ $ENABLE -eq $TRUE ] || [ $BOL_ALL -eq $TRUE ]; then
	    declare -x ITEM="${CATAGORY_ARRAY[$((INDEX))]}"
	    if [ ${#NAME_LEN} -eq 0 ]; then declare -i NAME_LEN=0; fi
	    if [ ${#DATA_LEN} -eq 0 ]; then declare -i DATA_LEN=0; fi
            while IFS= read LINE; do
                ((COUNT++))
                declare -x SNMP_NAME="${LINE%%STRING:*}"
                declare -x SNMP_DATA="${LINE##*STRING:}"
                if [ ${#SNMP_NAME} -gt $NAME_LEN ]; then declare -i NAME_LEN=${#SNMP_NAME}; fi
                if [ ${#SNMP_DATA} -gt $DATA_LEN ]; then declare -i DATA_LEN=${#SNMP_DATA}; fi
            done < <($SNMPWALK_BIN $SNMP_OPTIONS -c$SNMP_COMMUNITY  $SNMP_SERVER $ITEM 2>$ERR_OUT; declare -i RETVAL=$?)
	fi
      done
    else
      declare -i NAME_LEN=10
      declare -i DATA_LEN=10
    fi

    declare -i INDEX=-1
    declare -i COUNT=0
    if [ $BOL_DEBUG -eq $TRUE ]; then
	DEBUG_START_MESSAGE "Loop Through snmpwalk" >$ERR_OUT
	DEBUG_EXEC_MESSAGE "$SNMPWALK_BIN $SNMP_OPTIONS -c$SNMP_COMMUNITY  $SNMP_SERVER $ITEM" >$ERR_OUT
    fi
    for ENABLE in ${ENABLE_ARRAY[@]}; do
        ((INDEX++))
        if [ $ENABLE -eq $TRUE ] || [ $BOL_ALL -eq $TRUE ]; then
            declare -x ITEM="${CATAGORY_ARRAY[$((INDEX))]}"
	    while IFS= read LINE; do
		((COUNT++))
		declare -x SNMP_NAME="${LINE%%STRING:*}"
		declare -x SNMP_DATA="${LINE##*STRING:}"
		if [ $BOL_VAL -eq $TRUE ]; then
		    CY_TEXT;  printf "%-6s: " "$COUNT"
		    CC_TEXT;  printf "%-$((NAME_LEN+1))s " "$SNMP_NAME"
		fi
		CLR_TEXT; printf "%s\n" "$SNMP_DATA"
		CN_TEXT
	    done < <($SNMPWALK_BIN $SNMP_OPTIONS -c$SNMP_COMMUNITY  $SNMP_SERVER $ITEM 2>$ERR_OUT; declare -i RETVAL=$?)
	fi
    done
else
    SHOW_NO_ARGS
    declare -i RETVAL=$FAILURE
fi

exit $RETVAL
