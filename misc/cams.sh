#!/bin/bash
# keytab.sh - Generating Kerberos Keytabs
# Shell Script By: Peter Talbott
####  ffplay rtsp://pete:'Bl4ck3nd!!'@10.40.1.22:554/unicast/c1/s0/live"
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
export VERSION="0.3"
export AUTHOR="Peter Talbott"
export MODIFIED="2023-04-06"

# Define a few more binary variables
for DATA in ffplay egrep chown sleep cat wc find true; do
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

function HEADER()
{
	printf "%-25s\tversion %s\n" ${RUN_CMD%%/*} $VERSION
	printf "%-21s\t%s\n\n" $AUTHOR $MODIFIED
	return 0
};

for OPTIONS in $@; do
    case $OPTIONS in
	--ip=*)		declare -x RTSP_IP="${OPTIONS#*=}";;
	--port=*)	declare -i RTSP_PORT="${OPTIONS#*=}";;
	--user=*)	declare -x RTSP_USER="${OPTIONS#*=}";;
	--pass=*)	declare -x RTSP_PASS="${OPTIONS#*=}";;
	--stream=*)	declare -x RTSP_STREAM="/s${OPTIONS#*=}";;
	--log=*)	declare -x LOG="${OPTIONS#*=}";;
	--error=*)	declare -x ERR="${OPTIONS#*=}";;
	*)		CAMS="$CAMS /c${OPTIONS#*=}";;
    esac
done

if [ ${#CAMS}		-eq 0 ]; then HEADER; echo "$RUN_CMP --help for options"; exit 1; fi
if [ ${#RTSP_IP}	-eq 0 ]; then declare -x RTSP_IP="10.40.1.22";		fi
if [ ${#RTSP_PORT}	-eq 0 ]; then declare -i RTSP_PORT=554;			fi
if [ ${#RTSP_USER}	-eq 0 ]; then declare -x RTSP_USER="pete";		fi
if [ ${#RTSP_PASS}	-eq 0 ]; then declare -x RTSP_PASS='Bl4ck3nd!!';	fi
if [ ${#RTSP_PREFIX}	-eq 0 ]; then declare -x RTSP_PREFIX="/unicast";	fi
if [ ${#RTSP_STREAM}	-eq 0 ]; then declare -x RTSP_STREAM="/s0";		fi
if [ ${#RTSP_SUFFIX}	-eq 0 ]; then declare -x RTSP_SUFFIX="/live";		fi
if [ ${#LOG}		-eq 0 ]; then declare -x LOG="/dev/null";		fi
if [ ${#ERR}		-eq 0 ]; then declare -x ERR="/dev/null";		fi

for CAMERA in $CAMS; do
	declare -x URL="rtsp://$RTSP_USER:$RTSP_PASS@$RTSP_IP:$RTSP_PORT$RTSP_PREFIX$CAMERA$RTSP_STREAM$RTSP_SUFFIX"
	$FFPLAY_BIN "$URL" >$LOG 2>$ERR &
	RV=$?
	$SLEEP_BIN 1
done

exit $RV
