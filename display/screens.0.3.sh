#! /bin/bash
# Script for Enabeling and Setting a Multi-Head System
# By: Peter Talbott

# Script Version
export _SCREENS_VER=0.3

# Make Sure We Connect To Local Display Manager
export DISPLAY=:0
XAUTHORITY=~/.Xauthority

# Source Root Path and File(s)
_SOURCE_ROOT="/usr/local/scripts"
_SOURCE_FILE="TextColors.sh"
#source "$_SOURCE_ROOT/$_SOURCE_FILE"

# Define Booleans
export _BOL_REQUIRED_PARAMETER=0
export _BOL_RUN_PARAMETER=0
export _BOL_LOAD_MONITOR_ARRAY=0
export _BOL_DISPLAY_MONITOR_ARRAY=0
export _BOL_HELP=0
export _BOL_VERBOSE=0
export _BOL_COLOR=1
export _BOL_SHOW_ALL=0
export _BOL_SHOW_ONLY=0
export _BOL_SHOW_TOTALS=0
export _BOL_ALT_POS=0

# Define Variables
export _UNKNOWN_PARAMETER_COUNT=0
declare -ag _UNKNOWN_PARAMETER=()

function DisplayTOTALS()
{
	echo -e ""
        echo -e "$COLOR_LT_RED""Total PreDefined Monitor Count:\t""$COLOR_DK_GRAY""$((_PRE_DEFINED_COUNT))""$COLOR_NORMAL"
        echo -e "$COLOR_LT_RED""Total Array Monitor Count:\t""$COLOR_DK_GRAY""$((MONITOR_ARRAY_COUNT))""$COLOR_NORMAL"
        echo -e "$COLOR_LT_RED""Total Output Port Count \t""$COLOR_DK_GRAY""$((_TOTAL_PORTS))""$COLOR_NORMAL"
};

# Define 'DisplayMonitorArray()' Function Shows All Values In MonitorArray
function DisplayMonitorArray()
{

   for (( _AA=0; $((_AA)) <=2; _AA++ ))
     do
	_LENGTH=5
       for (( _BB=0; $((_BB)) <= $((_LENGTH)); _BB++ ))
          do
		_LENGTH="${MONITOR_ARRAY_LENGTH[ $(( _AA )) ]}"
		echo -e "$COLOR_LT_PURPLE""$((_AA)) $((_BB)) ""$COLOR_LT_BLUE""${MONITOR_ARRAY[$((_AA)),$((_BB))]}""$COLOR_NORMAL"
       done
     if [ $_BOL_VERBOSE -eq 1 ]
       then
     		echo -e "$COLOR_LT_CYAN""${_MONITOR_XRANDR[ $((_AA)) ]} \n""$COLOR_NORMAL"
       else
		echo ""
     fi
   done
   export _PRE_DEFINED_COUNT
   export _TOTAL_PORTS
   export MONITOR_ARRAY_COUNT

};

# Initializes Arrays of Pre-Defined Monitors
function AttachedMonitors()
{
   _INDEX=2
   declare -ag MONITOR_MAKE=('AOC' 'Dell' 'Sanyo');			# Monitor Manufacturer Name
   declare -ag MONITOR_MODEL=('"1950W"' '"DELL 1708FP"' '"LCD TV"');	# Monitor Model Name Should Match EDID
   declare -ag OUTPUT_X_NAME=('DP-2' 'DVI-1-0' 'HDMI-1-3');		# XORG Port Output Name
   declare -ag OUTPUT_X_PREFERRED_POS=('544x1080' '1920x952' '0x0');	# XORG Position of Each Monitor
   declare -ag OUTPUT_X_ALTERNATE_POS=('0x0' '0x0' '0x0');		# XORG Alternate Position of Each Monitor
   declare -ag BOL_OUTPUT_X_PRIMARY=('1' '0' '0');			# Boolean Array Defining a Primary Display; If there is one
   export _PRIMARY_OPT='--primary' 					# Option for xrandr
   export _PRE_DEFINED_INDEX=$((_INDEX)) 				# Number of PreDefined Monitor Array Indices; 0 Counts as a Monitor
   export _PRE_DEFINED_COUNT=$((_INDEX))+1				# Number of Total PreDefined Monitors; 0 Does NOT Count as a Monitor
};

# Function for Storing All EDID(s) into Declared Arrays
function StoreEDID()
{
   declare -ag _FULL_MONITOR_EDID=()
   declare -ag _MONITOR_EDID=()
   while IFS= read -r line;
      do
	_TEMP=( "$line" )
	_FULL_MONITOR_EDID+=( "$_TEMP" )
	_MONITOR_EDID+=( "${_TEMP#	*}" )
   done < <( parse-edid <$_DRM_FULL_PATH/edid )
};

# Function for Storing All Video Modes (Resolutions) into Declared Arrays
function StoreMODES()
{
   declare -ag _FULL_MONITOR_MODES=()
   declare -ag _MONITOR_MODES=()
   while IFS= read -r line;
      do
        _TEMP=( "$line" )
        _FULL_MONITOR_MODES+=( "$_TEMP" )
        _MONITOR_MODES+=( "${_TEMP#      *}" )
   done < <( cat $_DRM_FULL_PATH/modes )
};

#function StoreUSERS()
#{
#	for $i in $(users)

# Function to Store 'xrandr' Options
function Store_XRANDR()
{
   declare -ag _MONITOR_XRANDR=()
   _AUTO="--auto"
   _OUTPUT="--output"
   _MODE="--mode"
   _POS="--pos"
   _PRI="--primary"
   for (( _INDEX=0; $((_INDEX)) <= $((MONITOR_ARRAY_INDEX)); _INDEX++ ))
      do
	if [ $_BOL_ALT_POS -eq 0 ]
	  then
		_TEMP_POS=${MONITOR_ARRAY[$((_INDEX)),4]}
	elif [ $_BOL_ALT_POS -eq 1 ] 
	  then
		_TEMP_POS=${MONITOR_ARRAY[$((_INDEX)),5]}
	fi
        _MONITOR_XRANDR[ $(( _INDEX )) ]="$_AUTO $_OUTPUT ${MONITOR_ARRAY[$((_INDEX)),6]} $_MODE ${MONITOR_ARRAY[$((_INDEX)),3]} $_POS $_TEMP_POS"
	if [ ${MONITOR_ARRAY[$((_INDEX)),2]} -eq 1 ]
	  then
		_MONITOR_XRANDR[ $(( _INDEX )) ]="${_MONITOR_XRANDR[ $(( _INDEX )) ]} $_PRI"
		RETVAL=$(( _INDEX ))
	fi
   done
   return $RETVAL
};

# MONITOR_ARRAY[ (Monitor Number), 9 ] is the full string for xrandr to parse
# Function 'run_XRANDR()' run xrander for each monitor
function run_XRANDR()
{
   for (( _INDEX=0; $((_INDEX)) <= $((MONITOR_ARRAY_INDEX)); _INDEX++ ))
     do
	_TEMP=${MONITOR_ARRAY[$((_INDEX)),9]}
	if [ $_BOL_VERBOSE -eq 1 ]
          then
		echo -e "\n$COLOR_LT_PURPLE" "xrandr " "$COLOR_YELLOW" "$_TEMP" "$COLOR_NORMAL"
        fi
	xrandr $_TEMP
	RETVAL=$?
   done
   return $RETVAL
};

# Function to Initialize MultiDimentional MONITOR_ARRAY[ (Monitor Number), (Index Number) ]
# Side Note: This Function Was a Bit of A Challenge and I Enjoyed Writting It...
function init-monitor-array()
{
   declare -Ag MONITOR_ARRAY=()
   declare -ag MONITOR_ARRAY_LENGTH=()
   _TOTAL_PORTS=0
   _MONITOR_NUMBER=-1
   _BB=-1
   for _RAW_STATUS in /sys/class/drm/*/status
   do
	(( _TOTAL_PORTS++ ))
	_DRM_FULL_PATH=${_RAW_STATUS%/status}
	_DRM_NAME=${_DRM_FULL_PATH#/sys/class/drm/*}
	_DRM_STATUS=$(cat $_RAW_STATUS)
	if [ $_DRM_STATUS == 'connected' ]
	  then
		(( _MONITOR_NUMBER++ ))
		_BB=-1
		_FULL_MODEL_NAME=$(parse-edid <$_DRM_FULL_PATH/edid|grep ModelName)
		_CUT_MODEL_NAME="${_FULL_MODEL_NAME#	ModelName *}"
		for _MONITOR_MODEL_ELEMENT in "${MONITOR_MODEL[@]}"
		  do
			if [ "$_MONITOR_MODEL_ELEMENT" == "$_CUT_MODEL_NAME" ]
			  then
				export _DRM_FULL_PATH
				StoreEDID
				StoreMODES
				if [ $_BOL_VERBOSE -eq 1 ]
			          then
					echo -e "Found $_MONITOR_MODEL_ELEMENT"
				fi
				MONITOR_ARRAY[$((_MONITOR_NUMBER)),0]=${MONITOR_MAKE[ $((_BB))+1 ]}
				MONITOR_ARRAY[$((_MONITOR_NUMBER)),1]=${MONITOR_MODEL[ $((_BB))+1 ]}
				MONITOR_ARRAY[$((_MONITOR_NUMBER)),2]=${BOL_OUTPUT_X_PRIMARY[ $((_BB))+1 ]}
				MONITOR_ARRAY[$((_MONITOR_NUMBER)),3]=$(head -n 1 "$_DRM_FULL_PATH/modes")
				MONITOR_ARRAY[$((_MONITOR_NUMBER)),4]=${OUTPUT_X_PREFERRED_POS[ $((_BB))+1 ]}
				MONITOR_ARRAY[$((_MONITOR_NUMBER)),5]=${OUTPUT_X_ALTERNATE_POS[ $((_BB))+1 ]}
				MONITOR_ARRAY[$((_MONITOR_NUMBER)),6]=${OUTPUT_X_NAME[ $((_BB))+1 ]}
				MONITOR_ARRAY[$((_MONITOR_NUMBER)),7]=$_DRM_NAME
				MONITOR_ARRAY[$((_MONITOR_NUMBER)),8]=$_DRM_FULL_PATH
				_AA=9
				for _MONITOR_EDID_ELEMENT in "${_MONITOR_EDID[@]}"
				  do
					((_AA++))
					MONITOR_ARRAY[$((_MONITOR_NUMBER)),$((_AA))]="$_MONITOR_EDID_ELEMENT"
				done
				# Store All Supported Video Modes
				((_AA++))
				MONITOR_ARRAY[$((_MONITOR_NUMBER)),$((_AA))]='Section "Modes"'
                                for _MONITOR_MODE_ELEMENT in "${_MONITOR_MODES[@]}"
                                  do
                                        ((_AA++))
                                        MONITOR_ARRAY[$((_MONITOR_NUMBER)),$((_AA))]="$_MONITOR_MODE_ELEMENT"
                                done
				((_AA++))
				MONITOR_ARRAY[$((_MONITOR_NUMBER)),$((_AA))]='EndSection'
			  else
				(( _BB++ ))
			fi
		done
		MONITOR_ARRAY_LENGTH[ $(( _MONITOR_NUMBER )) ]="$(( _AA ))"
	fi
   done
   export MONITOR_ARRAY_INDEX=$(( _MONITOR_NUMBER ))
   export MONITOR_ARRAY_COUNT=$(( _MONITOR_NUMBER ))+1
   export _TOTAL_PORTS
   Store_XRANDR
   for (( _INDEX=0; $((_INDEX)) <= $((MONITOR_ARRAY_INDEX)); _INDEX++ ))
      do
		MONITOR_ARRAY[$((_INDEX)),9]="${_MONITOR_XRANDR[ $(( _INDEX )) ]}"
   done
};

# Function 'DisplayHELP()' shows the --help message
function DisplayHELP()
{
	echo -e "$COLOR_LT_PURPLE""-a or --alt\t\t\t""$COLOR_LT_BLUE""Load Alternat Stored Monitor Position""$COLOR_NORMAL"
	echo -e "$COLOR_LT_PURPLE""-b or --bw\t\t\t""$COLOR_LT_BLUE""Black and White Text Output""$COLOR_NORMAL"
	echo -e "$COLOR_LT_PURPLE""-c or --color\t\t\t""$COLOR_LT_RED""Color Text Output (Default in this Version)""$COLOR_NORMAL"
	echo -e "$COLOR_LT_PURPLE""-h or --help\t\t\t""$COLOR_LT_RED""Display This Message""$COLOR_NORMAL""$COLOR_NORMAL"
	echo -e "$COLOR_LT_PURPLE""-r or --run\t\t\t""$COLOR_LT_RED""Actually run xrander from MONITOR_ARRAY""$COLOR_NORMAL"
	echo -e "$COLOR_LT_PURPLE""-t or --total\t\t\t""$COLOR_LT_RED""Display Total Monitor Counts""$COLOR_NORMAL"
	echo -e "$COLOR_LT_PURPLE""-v or --verbose\t\t\t""$COLOR_LT_RED""Be Verbose""$COLOR_NORMAL"
};

# Time to parse command line arguments
# I use Booleans as much as possible here
for i in "$@"
do
case $i in
'-sa' | '--show-all')
	_BOL_SHOW_ALL=1
	_BOL_LOAD_MONITOR_ARRAY=1
	_BOL_DISPLAY_MONITOR_ARRAY=1
	_BOL_REQUIRED_PARAMETER=1
	_BOL_SHOW_TOTALS=1
	;;
'-so' | '--show-only')
	_BOL_SHOW_ONLY=1
	_BOL_SHOW_ALL=1
        _BOL_LOAD_MONITOR_ARRAY=1
        _BOL_DISPLAY_MONITOR_ARRAY=1
        _BOL_REQUIRED_PARAMETER=1
	_BOL_SHOW_TOTALS=1
        ;;
'-r' | '--run')
	_BOL_LOAD_MONITOR_ARRAY=1
        _BOL_REQUIRED_PARAMETER=1
        _BOL_RUN_PARAMETER=1
	;;
'-c' | '--color')
	_BOL_COLOR=1
	;;
'-b' | '--bw')
	_BOL_COLOR=0
	;;
'-a' | '--alt')
	_BOL_ALT_POS=1
	;;
'-t' | '--totals')
	_BOL_SHOW_TOTALS=1
	;;
'-h' | '--help')
	_BOL_HELP=1
	;;
'-v' | '--verbose')
	_BOL_VERBOSE=1
	;;
*)
	_UNKNOWN_PARAMETER[ $(( _UNKNOWN_PARAMETER_COUNT )) ]="$i"
	(( _UNKNOWN_PARAMETER_COUNT++ ))
        ;;
esac
done

# Firt Thing First: Enable/Disable Color Text Output
if [ $_BOL_COLOR -eq 1 ]
  then
	source "$_SOURCE_ROOT/$_SOURCE_FILE"
        initialize_color
fi

if [ $_UNKNOWN_PARAMETER_COUNT -ne 0 ]
  then
	# Unknow Parameter Is Enabled, Set All Booleans Off
	export _BOL_REQUIRED_PARAMETER=0
	export _BOL_RUN_PARAMETER=0
	export _BOL_LOAD_MONITOR_ARRAY=0
	export _BOL_DISPLAY_MONITOR_ARRAY=0
	export _BOL_HELP=0
	 echo -e "$COLOR_YELLOW""Attempted ""$COLOR_LT_RED""$((_UNKNOWN_PARAMETER_COUNT))""$COLOR_YELLOW"" Unknown Paramater(s); Cannot Continue""$COLOR_NORMAL"
	if [ $_BOL_VERBOSE -eq 1 ]
	  then
		for (( _XX=0; $((_XX)) <= $((_UNKNOWN_PARAMETER_COUNT))-1; _XX++ ))
		   do
			echo -e "$COLOR_YELLOW""Unknown Option""$COLOR_NORMAL"": ""$COLOR_LT_RED""${_UNKNOWN_PARAMETER[ $(( _XX )) ]}""$COLOR_NORMAL"
		done
	  else
		echo -e "$COLOR_LT_PURPLE""Use -v or --verbose to see the Unknown Parameters""$COLOR_NORMAL"
	fi
fi

# Check to see if all required parameters have been set
if [ $_BOL_REQUIRED_PARAMETER -eq 1 ]
  then # Required Parameter Boolean is set
      #Check To See IF We Are To Populate The Monitor Array
      if [ $_BOL_LOAD_MONITOR_ARRAY -eq 1 ]
        then
		AttachedMonitors
		init-monitor-array
		Store_XRANDR
        else
		export _BOL_RUN_PARAMETER=0
      fi
      # Check To See IF We Are To Display The Monitor Array
      if [ $_BOL_DISPLAY_MONITOR_ARRAY -eq 1 ]
	then
		# Call The Function To Display The Monitor Array
		DisplayMonitorArray
      fi

      # IF Verbose; Display Totals
      if [ $_BOL_SHOW_TOTALS -eq 1 ]
	then
        	DisplayTOTALS
      fi

      # Check To See If We are to Run xrandr
      if [ $_BOL_RUN_PARAMETER -eq 1 ]
	then
		# Here is where we run xrandr
		# Check To See IF _BOL_SHOW_ONLY is Set
		if [ $_BOL_SHOW_ONLY -eq 0 ]
        	  then
			printf "Starting xrandr: "
			run_XRANDR
			RETVAL=$?
        	        [ $RETVAL = 0 ] && echo -e "$COLOR_NORMAL""[ ""$COLOR_LT_GREEN""Success""$COLOR_NORMAL"" ]"
	                [ $RETVAL != 0 ] && echo -e "$COLOR_NORMAL""[ ""$COLOR_LT_RED""Failure""$COLOR_NORMAL"" ]"
		  else
			echo -e "$COLOR_NORMAL""[ ""$COLOR_YELLOW""Skipped""$COLOR_NORMAL"" ]"
		fi
      fi
  else # Required Parameter Boolean is NOT set
      if [ $_BOL_HELP -eq 1 ]
	then
		echo -e "$COLOR_YELLOW""$0:\t""$COLOR_LT_CYAN""Help Section\t""$COLOR_LT_GREEN""Version: $_SCREENS_VER""$COLOR_NORMAL"
		DisplayHELP
	else
		echo "Usage: $0 { -r or --run | -h or --help }"
      fi
fi

# The End!
