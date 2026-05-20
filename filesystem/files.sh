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


declare -x RUN_CMD="$(basename $0)"
declare -x VERSION="0.1"
declare -x AUTHOR="Peter Talbott"
declare -x MODIFIED="2023-09-12"


# Define a few more binary variables
for DATA in mysql host find sha256sum; do
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

if [ ${#MYSQL_HOST}	 -eq  0     ]; then declare -x MYSQL_HOST="naboo.vlan10.gigaware.lan";					fi
if [ ${#MYSQL_DATABASE}	 -eq  0     ]; then declare -x MYSQL_DATABASE="FileSystem";						fi
if [ ${#MYSQL_TABLE}	 -eq  0     ]; then declare -x MYSQL_TABLE="Files";							fi
if [ ${#MYSQL_USER}	 -eq  0     ]; then declare -x MYSQL_USER="fileuser";							fi
if [ ${#MYSQL_PASS}	 -eq  0     ]; then declare -x MYSQL_PASS="filepass";							fi


declare -x HOST_NAME=$(hostname --fqdn)
declare -x START_INSERT_CMD='INSERT INTO '"$MYSQL_TABLE"' (HostName, Filename, sha256sum, UUID) VALUES ('
declare -x CLOSE_INSERT_CMD="uuid());"

function STORE_CHECKSUM()
{
    declare -x PREFIX=$1
    while IFS= read FILE_NAME; do
       declare -x DATA="$($SHA256SUM_BIN $FILE_NAME)"
       declare -i INDEX=-1
       for CHECK in $DATA; do
            ((INDEX++))
            if [ $INDEX -eq 0 ]; then CHECKSUM=$CHECK; fi
       done
       OPTS=$(printf "%s%s, %s, %s, %s"  "$START_INSERT_CMD" "$HOST_NAME" "$FILE_NAME" "$CHECKSUM" "$CLOSE_INSERT_CMD")
       INFO_EXEC_MESSAGE "$OPTS"
       CMD="$(printf "USE %s;\n%s\n" "$MYSQL_DATABASE" "$OPTS") | $MYSQL_BIN -h $MYSQL_HOST -u $MYSQL_USER --password=$MYSQL_PASS 2>/dev/null"
       echo -e $CMD
       printf "USE %s;\n%s\n" "$MYSQL_DATABASE" $OPTS | $MYSQL_BIN -h $MYSQL_HOST -u $MYSQL_USER --password=$MYSQL_PASS 2>/dev/null
       declare -i RETVAL=$?
       declare -x COMMAND=$MYSQL_BIN
       INFO_DONE_MESSAGE "Insert MYSQL Statement"
    done < <($FIND_BIN $PREFIX -type f)
    return $?
};

if [ $BOL_COLOR   -eq $TRUE   ]; then INIT_COLOR_SHORTHAND;				      	                      		fi
STORE_CHECKSUM /usr/local/dev
