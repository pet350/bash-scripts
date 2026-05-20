#!/bin/bash

#gs -sDEVICE=pdfwrite -dCompatibilityLevel=1.4 -dPDFSETTINGS=/ebook -dNOPAUSE -dBATCH -sOutputFile=compressed.pdf input.pdf
# Defile TRUE and FALSE if not deined already
if [ ${#TRUE}	-eq 0 ]; then /bin/true;  TRUE=$?;	fi
if [ ${#FALSE}	-eq 0 ]; then /bin/false; FALSE=$?;	fi

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
export MODIFIED="2026-04-05"
declare -i SCRIPT_RETURN=$SUCCESS

# Define a few more binary variables
for DATA in gs egrep wc find true; do
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
  echo -e "$RUN_CMD\t\tTrim PDF Size Version: $VERSION\nBy: $AUTHOR\tDated: $MODIFIED"
  return $SUCCESS
};

function SHOW_NO_ARGS()
{
    SHOW_HEADER
    echo -e "for help: $RUN_CMD --help (or -h)\n"
    return $SUCCESS
};

if [ ${#IN_FILE}	-eq 0 ]; then SHOW_NO_ARGS; exit 0;									fi
if [ ${#CUT}		-eq 0 ]; then declare -x CUT="-cut";									fi
if [ ${#PDF}		-eq 0 ]; then declare -x PDF=".pdf";									fi
if [ ${#OUT_FILE}	-eq 0 ]; then declare -x TEMP_FILE="${IN_FILE%.pdf*}"; declare -x OUT_FILE="$TEMP_FILE$CUT$PDF";	fi

declare -a PARAMETERS=(	"-sDEVICE" "-dCompatibilityLevel" "-dPDFSETTINGS" "-dNOPAUSE"   "-dBATCH" "-sOutputFile" "$IN_FILE");
declare -a VALUES=(	"=pdfwrite" "=1.4" 		  "=/ebook" 	  "" 		""	  "=$OUT_FILE"   "");

INDEX=-1
for DATA in ${PARAMETERS[@]}; do
    ((INDEX++))
    STRING="$STRING $DATA${VALUES[$INDEX]} "
done

SHOW_HEADER
echo $GS_BIN $STRING
$GS_BIN $STRING
RETVAL=$?
SHOW_RESULTS
exit $RETVAL
