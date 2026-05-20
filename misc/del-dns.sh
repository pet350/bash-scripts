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

if [ ${#FIRST}	-eq 0 ]; then	declare -i FIRST=10;	fi
if [ ${#SECOND}	-eq 0 ]; then 	declare -i SECOND=20;	fi
if [ ${#THIRD}	-eq 0 ]; then 	declare -i THIRD=1;	fi
if [ ${#FOURTH}	-eq 0 ]; then 	declare -i FOURTH=0;	fi
if [ ${#MAX}	-eq 0 ]; then 	declare -i MAX=255;	fi

if [ ${#DOMAIN}	-eq 0 ]; then	declare -x DOMAIN="gigaware.lan";	fi
if [ ${#REALM}	-eq 0 ]; then	declare -x REALM="GIGAWARE.LAN";	fi
if [ ${#USER}	-eq 0 ]; then	declare -x USER="pete";			fi
if [ ${#PASS}	-eq 0 ]; then	declare -x PASS="Maiden660!!";		fi
if [ ${#SERVER}	-eq 0 ]; then	declare -x SERVER="kdc.$DOMAIN";	fi

function DEL_PTR()
{
    declare -i RETVAL=$FAILURE
    declare -x OPTIONS="dns delete $SERVER $ZONE. $FOURTH PTR $PTR_DATA"
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

    INDEX=-1
    for DATA in $(GET_PTR_NAME); do
	((INDEX++))
	PTR_NAME[$((INDEX))]="$DATA"
    done

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
	done
	echo ""
    fi
done
