#!/bin/bash
# getpath.sh: Script dealing with $PATH
# By: Peter Talbott: February 28th 2019

declare -ig TRUE=1
declare -ig FALSE=0

declare -ig SUCCESS=0
declare -ig FAILURE=1
declare -ig CONDITION_NOT_MET=255
declare -ig GetPathExists=$TRUE

# Function Will Get The Current $PATH And Store Each into PATH_ARRAY[@]
function getPATH()
{
  declare -ag PATH_ARRAY=()				# Define single dimential array; PATH_ARRAY[@]
  declare -i INDEX=0					# Set INDEX to 0
  declare -i BOL_DONE=$FALSE				# Set $BOL_DONE to FALSE
  while [ $BOL_DONE -ne $TRUE ]; do			# Loop until $BOL_DONE equals $TRUE
    ((INDEX++))						# Add 1 to INDEX
    TEMP_DATA=$( echo $PATH | cut -d : -f $((INDEX)) )	# Set $TEMP_DATA to the Next $PATH Value
    if [ ${#TEMP_DATA} -eq 0 ]; then			# Check to see if $TEMP_DATA Contains Any data
      BOL_DONE=$TRUE					# If there is no data set BOL_DONE to TRUE
    else						# Else If $TEMP_DATA has a Value
      PATH_ARRAY[$((INDEX))-1]="$TEMP_DATA"		# Store that data to PATH_ARRAY[@]
    fi							# Done with IF statement
  done							# If $BOL_DONE equals True; Done With Loop
  return $((INDEX-1))					# Return INDEX Value
};							# Done with getPATH Function

function setPATH()
{
  # setPATH: Will add a path stored in $TEMP to the system PATH if it isn't there Already
  declare -i BOL_PATH_EXISTS=$FALSE		# Define BOL_PATH_EXISTS for 'Boolean Path Exists'
  declare -i RETVAL=$FAILURE			# Define RETVAL for function 'Return Value'
  if [ ${#TEMP} -ne 0 ]; then			# Check for data in $TEMP
    # There is data stored in $TEMP
    getPATH					# Populate PATH_ARRAY with Current $PATH
    for TEMP_DATA in ${PATH_ARRAY[@]}; do	# Loop Through PATH_ARRAY[@] setting $TEMP_DATA each loop
      if [ $TEMP_DATA == $TEMP ]; then		# Check if TEMP_DATA equals $TEMP
        BOL_PATH_EXISTS=$TRUE			# If so Set BOL_PATH_EXISTS to TRUE
      fi					# Done With IF Statement
    done					# Done With Loop through PATH_ARRAY[@]
    if [ $BOL_PATH_EXISTS -eq $FALSE ]; then	# Check BOL_PATH_EXISTS
      export PATH="$PATH:$TEMP"			# If PATH does NOT exist, append $TEMP to $PATH
      RETVAL=$SUCCESS				# Set RETVAL to Success!
    else					# If PATH does exist
      RETVAL=$FAILURE				# Set RETVAL to Failure
    fi						# Done with IF Statement; Check BOL_PATH_EXISTS
  else						# If Nothing Stored in $TEMP
    RETVAL=$CONDITION_NOT_MET			# Set RETVAL to CONDITION_NOT_MET
  fi						# Done with IF Statement; Check for data in $TEMP
  return $RETVAL				# Retrun RETVAL
};						# Done with setPATH Function

function printPATH()
{
  getPATH
  echo -e "Current Path: $PATH\n"
  echo -e "Broken Down Into Index:"
  declare -i INDEX=-1
  for x in ${PATH_ARRAY[@]}; do
    ((INDEX++))
    echo -e "Index: $INDEX\tValue: $x"
  done
  return $INDEX
};

declare -a ADD_PATHS_ARRAY=('/bin' '/sbin' '/usr/bin' '/usr/sbin' '/usr/local/bin' '/usr/local/sbin' '/usr/local/scripts');
for TEMP in ${ADD_PATHS_ARRAY[@]}; do
  ## Add Elements of ADD_PATHS_ARRAY[@] to $PATH if their not Already there
  export TEMP="$TEMP"
  setPATH
done

unset BOOLEAN
unset TEMP_DATA
unset TEMP
unset INDEX
unset BOL_PATH_EXISTS
unset x
# Done!!
