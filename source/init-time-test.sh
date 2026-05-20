#! /bin/bash

source "/usr/local/scripts/source/init-time.sh"
initialize_time_date
RETVAL=$?

echo -e "${_TIME_DATE[4]} \t $RETVAL"

