#!/bin/bash
# finish-init.sh
# Version 0.1
# Peter Talbott

# Simple Sell Script to Finialize Initialization Upon Opening A Shell

for STRING in initTimeExists initialize_time_date BOOLEAN TEMP_DATA TEMP GetPathExists DATA ADD_PATHS_ARRAY initTimeExists; do
  unset $STRING
done

unset STRING

