#! /bin/bash
# Script For Activating ScreenSaver: Providing Exception BlackList Isn't Running
# Peter Talbott
# 2018/12/25 -- Christmas Day And I'm Shell Scripting.... LOL!

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


export _VERSION=0.1

# Make Sure We Connect To Local Display Manager
export DISPLAY=:0
XAUTHORITY=~/.Xauthority

function init-blacklist()
{
	declare -ag _blacklist=('mplayer' 'smplayer' 'xine' 'gmplayer');
	export _blacklist_index=3
	return $_blacklist_index
};

function DisplayBlackList()
{
  printf "List of all Exceptions: "
  for (( _INDEX=0; $((_INDEX)) <= $((_blacklist_index)); _INDEX++ ))
    do
	printf "${_blacklist[ $(( _INDEX )) ]} "
  done
  printf "\n"
};

function DisplayHELP()
{
	printf "$0 Version:$_VERSION\tHELP!\n"
	printf "\t%-15s:\t\t%-40s\n" "-h  or  --help" "Display This Help Message"
	printf "\t%-15s:\t\t%-40s\n" "-i  or  --ignore-all" "Ignore All of the Exception List"
        printf "\t%-15s:\t\t%-40s\n" "-v  or  --verbose" "Be Verbose With All Output"
        printf "\t%-15s:\t\t%-40s\n" "-r  or  --run" "Run Screensaver Adhearing to Exception BlackList"
        printf "\t%-15s:\t\t%-40s\n" "-l  or  --list" "List All of the Exception BlackList"
        printf "%-15s:\t%-40s\n" "-b=program  or  --blacklist=program" "Add Additional Program"
	return 1
};

function run_NOT_SET()
{
   # Time To Go! Should We Explain Why?
   if [ $_BOL_VERBOSE -eq 1 ]
     then
	# YES - Here is the Explaination
	printf "Boolean (run_NOT_SET) Flagged!\n"
	printf "%d out of %d Exception BlackListed Task(s) Are Running\n" "$_RUNNING_TASK_COUNT" "$_TASK_COUNT"
	printf "Abort Initializing ScreenSaver\n"
	RETVAL=$_RUNNING_TASK_COUNT
     else
	# No - Just Exit Gracefully
	RETVAL=1
   fi
   return $RETVAL
};

function CheckTASKS()
{
  _RUNNING_TASK_COUNT=0
  for (( _INDEX=0; $((_INDEX)) <= $((_blacklist_index)); _INDEX++ ))
    do
	export _BLACK_LIST_NAME=${_blacklist[ $(( _INDEX )) ]}
	export _TEMP=$(pgrep $_BLACK_LIST_NAME )
	_PID=$(echo $_TEMP | cut -d ' ' -f 1)
	_PID=$((_PID))
	if [ $_PID -ne 0 ]
           then
		((_RUNNING_TASK_COUNT++))
		if [ $_BOL_VERBOSE -eq 1 ]
		   then
			printf "%-13s: %-17s%-25s %d\n" "$_BLACK_LIST_NAME" "Is Running!" "First Matching PID:" "$_PID"
		fi
	   else
		if [ $_BOL_VERBOSE -eq 1 ]
		   then
			printf "%-13s: %-17s%-25s %s\n" "$_BLACK_LIST_NAME" "Is NOT Running!" "First Matching PID:" "(null)"
		fi
	fi
  done
  if [ $((_RUNNING_TASK_COUNT)) -eq 0 ]
     then
	_BOL_RUN_PARAMETER=1
     else
	_BOL_RUN_PARAMETER=0
  fi
  if [ $_BOL_VERBOSE -eq 1 ]; then
     printf "%-21s: %-2d\n" "Running Task Count" "$((_RUNNING_TASK_COUNT))"
     printf "%-21s: %-2d\n" "Run Paramater" "$((_BOL_RUN_PARAMETER))"
  fi
  export _BOL_RUN_PARAMETER
  export _RUNNING_TASK_COUNT
  return $_RUNNING_TASK_COUNT
};

# Define all Booleans
declare -ig _BOL_LIST_ALL=0
declare -ig _BOL_IGNORE_ALL=0
declare -ig _BOL_HELP=0
declare -ig _BOL_VERBOSE=0
declare -ig _BOL_RUN_PARAMETER=0
declare -ig _BOL_REQUIRED_PARAMETER=0

# Define Integer Variables
declare -ig _UNKNOWN_PARAMETER_COUNT=0
declare -ig _UNKNOWN_PARAMETER_INDEX=$((_UNKNOWN_PARAMETER_COUNT))-1

# Define Arrays
declare -ag _UNKNOWN_PARAMETER=()

init-blacklist

# Time to parse command line arguments
# I use Booleans as much as possible here
for i in "$@"
do
case $i in
'-l' | '--list')
	export _BOL_LIST_ALL=1
	export _BOL_REQUIRED_PARAMETER=1
	;;
'-i' | '--ignore-all')
	export _BOL_IGNORE_ALL=1
	export _BOL_REQUIRED_PARAMETER=1
	;;
'-h' | '--help')
	export _BOL_HELP=1
	;;
'-r' | '--run')
	export _BOL_RUN_PARAMETER=1
	export _BOL_REQUIRED_PARAMETER=1
	;;
'-v' | '--verbose')
	export _BOL_VERBOSE=1
	;;
-b=* | --blacklist=*)
	((_blacklist_index++))
	_blacklist[ $(( _blacklist_index )) ]="${i#*=}"
	;;
*)
	_UNKNOWN_PARAMETER[ $(( _UNKNOWN_PARAMETER_COUNT )) ]="$i"
	(( _UNKNOWN_PARAMETER_COUNT++ ))
	echo -e "Unknown Parameter: $_UNKNOWN_PARAMETER; Cannot Continue"
        ;;
esac
done

# Make sure that IF help is set, all others are unset
if [ $_BOL_HELP -eq 1 ]
   then
	_BOL_RUN_PARAMETER=0
	_BOL_REQUIRED_PARAMETER=0
fi

# If there is an Unknown Parameter Do Not Try To RUN!
if [ $_UNKNOWN_PARAMETER_COUNT -ne 0 ]
   then
	_BOL_RUN_PARAMETER=0
	_BOL_REQUIRED_PARAMETER=0
fi

# Check to see if Required Parameter is Set
if [ $_BOL_REQUIRED_PARAMETER -eq 1 ]
   then
	# OK Required Parameter is set; continuing on:

	CheckTASKS
	# Check to see if we are to ignore the blacklist or not
	if [ $_BOL_IGNORE_ALL -eq 1 ]
	   then
		_BOL_RUN_PARAMETER=1
		if [ $_BOL_VERBOSE -eq 1 ]
		   then
			echo -e "Ignore All Flag is Enabled: Running ScreenSaver Reguardless of Other Tasks!"
		fi
	fi

	if [ $_BOL_LIST_ALL -eq 1 ]
	   then
		DisplayBlackList
	fi

	if [ $_BOL_RUN_PARAMETER -eq 1 ]
	   then
		# OK Run Parameter is set, its a go!
	 	xscreensaver-command -activate
		RETVAL=$?
	   else
		# Run Parameter is NOT Set, Aborting!
		run_NOT_SET
	fi
    else
	# Required Parameter is NOT set
	if [ $_BOL_HELP -eq 1 ]
	   then
		# Help IS Set Call Help Section
		DisplayHELP
		RETVAL=99
	   else
		# Help is NOT Set Required Parameter is NOT set!
		RETVAL=98
		echo "Usage: $0 { -r or --run | -h or --help }"
	fi
fi
exit $RETVAL
# All Done!
