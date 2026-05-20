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

declare -x RUN_CMD="$(basename $0)"
declare -x VERSION="0.3"
declare -x AUTHOR="Peter Talbott"
declare -x MODIFIED="2023-04-06"

declare -x HEADER="USE Documents;"
declare -x INSERT="INSERT INTO pdfFiles VALUES"

# Define a few more binary variables
for DATA in tee klist curl egrep chown stat sleep cat wc find true mysql; do
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

if [ ${#BOL_COLOR}		-eq 0 ]; then declare -i BOL_COLOR=$TRUE;				fi
if [ ${#BOL_FORCE_COLOR}	-eq 0 ]; then declare -i BOL_FORCE_COLOR=$TRUE;				fi
if [ ${#MYSQL_HOST}		-eq 0 ]; then declare -x MYSQL_HOST="naboo.vlan10.gigaware.lan";	fi
if [ ${#MYSQL_USER}		-eq 0 ]; then declare -x MYSQL_USER="root";				fi
if [ ${#MYSQL_PASS}		-eq 0 ]; then declare -x MYSQL_PASS='Thund3rstruck!';			fi
if [ $BOL_COLOR		    -eq $TRUE ]; then INIT_COLOR_SHORTHAND;					fi

function GET_FILE_DATE()
{
    declare INDEX=-1
    declare FILE_NAME="$1"
    for DATA in $($STAT_BIN "$FILE_NAME" | $GREP_BIN Birth); do
        ((INDEX++))
        if [ $INDEX -eq 1 ]; then
            echo $DATA
        fi
    done
    return $SUCCESS
};

function GET_PDF_ID()
{
    for DATA in $(echo -e "$HEADER\nSELECT pdf_id from pdfFiles;" | $MYSQL_BIN -h $MYSQL_HOST -u $MYSQL_USER --password=$MYSQL_PASS); do
        $TRUE_BIN
    done
    if [ ${#DATA} -ne 0 ]; then echo $DATA; else echo 0; fi
    return $SUCCESS
};

function ASSEMBLE_QUERY()
{
    printf "%s\n%s (\"%s\", \"%s\", \"%s\", \"%s\", \"%s\", \"%s\", load_file(\'%s\'), \"%s\");\n" "$HEADER" "$INSERT" "$PDF_NAME" "$DESC" "$PDF_NAME" \
    "-" "$FILE_DATE" "NA" "$FULL_NAME" "$PDF_ID"
    return $SUCCESS
};

echo -e $HEADER >/tmp/temp.sql
declare -i PDF_ID=$(GET_PDF_ID)
while IFS= read LINE; do
    ((PDF_ID++))
    declare -x FULL_NAME="$LINE"
    declare -x FILE_NAME="${LINE##*/}"
    declare -x PDF_NAME="${FILE_NAME%.pdf*}"
    declare -x DESC="${LINE%/*}"
    declare -x DESC="${DESC##*/}"
    declare -x FILE_DATE=$(GET_FILE_DATE "$FULL_NAME")
    INFO_MESSAGE "Full Name: $FULL_NAME"
    INFO_MESSAGE "ID: $PDF_ID"
    INFO_MESSAGE "Filename: $FILE_NAME"
    INFO_MESSAGE "PDF Name: $PDF_NAME"
    INFO_MESSAGE "Creation Date: $FILE_DATE"
    INFO_MESSAGE "Description: $DESC"
    ASSEMBLE_QUERY
    ASSEMBLE_QUERY | $MYSQL_BIN -h $MYSQL_HOST -u $MYSQL_USER --password=$MYSQL_PASS
done < <($FIND_BIN $DIR_ROOT -iname '*.pdf');




# insert into pdfFiles values (5, "Hoover Dual Power Max", "Carpet Cleaner Instructions", "Instructions", "User Manual", "2021-05-14", " ", LOAD_FILE('Hoover Dual Power Max.pdf'));


# MariaDB [Documents]> show columns from pdfFiles;
# +-------------+--------------+------+-----+---------+----------------+
# | Field       | Type         | Null | Key | Default | Extra          |
# +-------------+--------------+------+-----+---------+----------------+
# | pdf_id      | bigint(20)   | NO   | PRI | NULL    | auto_increment |
# | Name        | varchar(50)  | YES  |     | NULL    |                |
# | Description | varchar(128) | YES  |     | NULL    |                |
# | Category    | varchar(128) | YES  |     | NULL    |                |
# | SubCategory | varchar(128) | NO   |     | NULL    |                |
# | Date        | date         | NO   |     | NULL    |                |
# | Author      | varchar(128) | NO   |     | NULL    |                |
# | Data        | longblob     | YES  |     | NULL    |                |
# +-------------+--------------+------+-----+---------+----------------+
#