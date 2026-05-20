#! /bin/bash

## autofs.sh
## Script to Mount/Unmount All Available NFS Exports on Remote Server
## Peter Talbott  

export _VERSION=0.3.2

# Load Functions Defined in another Script I wrote
# This Source File Has Two Functions In it,
# 'initialize_color()' and 'initialize_color_array()'
# We're only going to use the first function in this script
source /usr/lib/bash/TextColors.sh ## Another Script By: Peter Talbott

# Set Boolean Defaults(s)
BOL_REQUIRED_PARAMETER=0
BOL_RUN_PARAMETER=0
BOL_BOTH_PARAMETERS=0
BOL_UNMOUNT=0
BOL_MOUNT=0
BOL_HELP=0
BOL_TEST=0
BOL_VERBOSE=0
BOL_NO_MTAB=1	# I Enabled This One By Default
BOL_SET_NFS_ARG=0
BOL_SET_NFS_OPTS=0
BOL_SET_NFS_VER=0
BOL_UNKNOWN_PARAMETER=0
BOL_COLOR=1 	# I Enabled This One By Default

# Set Initial Numeric Variables
SERVER_COUNT=-1

# Set Initial String Variables
export _ARG_DIR=" --directories" 
export _ARG_HEADER=" --no-header"
export _MOUNT_PREFIX="/nfs"
export _MOUNT_NFS_OPT="-t nfs"
export _MOUNT_OPT=""
export _MOUNT_EXT_OPT=""

# Set Result String Variables
export _SUCCESS="[$COLOR_GREEN Success $COLOR_NORMAL]"
export _FAILURE="[$COLOR_RED Failure $COLOR_NORMAL]"
export _TEST="[$COLOR_LT_PURPLE Test $COLOR_NORMAL]"
export _NOT_MTAB="[$COLOR_YELLOW Not in /etc/mtab $COLOR_NORMAL]"
export _IN_MTAB="[$COLOR_YELLOW Already in /etc/mtab $COLOR_NORMAL]"
export _STILL_MTAB="Still Exists in $COLOR_YELLOW""/etc/mtab$COLOR_NORMAL"

# Before We Go ANY Further Make 
# Sure Root Is Running This Program
if [ $(id -u) -ne 0 ]; then
        echo "Must be root to run $0 version $_VERSION, Current UID is $(id -u)"
        exit 1;
fi

# Now Check To See If BASH Can Handle Arrays
ARRAY_TEST[0]='test' || (echo 'Failure: arrays not supported in this version of bash.' && exit 2)

# Define 'do_display_help' Function
# This Function Displays the Help Message
do_display_help()
{
   echo -e "$COLOR_YELLOW""$0: Ver $_VERSION: ""$COLOR_LT_BLUE""By: Peter Talbott""$COLOR_LT_GREEN Help!""$COLOR_YELLOW"" Section:""$COLOR_NORMAL"
   echo -e "\n$COLOR_LT_RED""REQUIRED PARAMETER""$COLOR_NORMAL"":"
   echo -e "-m=<ServerName> or --mount=<ServerName>\t\t(Repeat As Needed)"
   echo -e "-u=<ServerName> or --unmount=<ServerName>\t(Repeat As Needed)"
   echo -e "\t""$COLOR_DK_GRAY""Example: -m=pc1 -m=pc2 -m=pc3$COLOR_NORMAL"
   echo -e "\tNote: Cannot Combind -m=<ServerName> and -u=<ServerName>"
   echo -e "\n$COLOR_LT_RED""OPTIONAL PARAMETERS""$COLOR_NORMAL"":"
   echo -e "-2 or --nfs2\t\tAttempt To Mount With NFS V2; (Default is V4)"
   echo -e "-3 or --nfs3\t\tAttempt To Mount With NFS V3; (Default is V4)"
   echo -e "-a or --alt\t\tAlternate Mount; Default /sbin/mount.nfs; Switch to /bin/mount"
   echo -e "-b or --bw\t\tDisable Colorized Text Outputs"
   echo -e "-c or --color\t\tEnable Colorized Text Output (Default)"
   echo -e "-t or --test\t\tTest Mode, Does NOT Actually (Un)Mount"
   echo -e "-h or --help\t\tDisply this Message!"
   echo -e "-v or --verbose\t\tBe Verbose"
 
};

# Define 'dounmount' Function
# This Function Is What Performs The Unmounting
dounmount()
{
   for EXPORTS in $(showmount $_ARGS $_TARGET)
   do
	if [ $BOL_TEST -eq 1 ]
	  then
		echo -e -n "$_TEST   "
	fi
	printf "%-11s %-45s" "Unmounting:" "$_MOUNT_PREFIX/$_TARGET$EXPORTS"
	if [ $BOL_TEST -eq 0 ]
	  then
	    if [ $(cat /etc/mtab | grep $_MOUNT_PREFIX/$_TARGET$EXPORTS | wc -l) -ne 0 ]
	      then
		_OUT=$(umount "$_MOUNT_PREFIX/$_TARGET$EXPORTS")
		RETVAL=$?
		if [ $BOL_VERBOSE -eq 1 ]
		  then
			echo -e "$_OUT"	
        	fi
	        [ $RETVAL = 0 ] && echo -e "$_SUCCESS"
       		[ $RETVAL != 0 ] && echo -e "$_FAILURE"
	    else
		echo -e "$_FAILURE\t$_NOT_MTAB"
		RETVAL=1
	    fi 
	  else
		## Test Parameter is Set
		RETVAL=1
		echo -e "$_SUCCESS"
	fi
      
	# Remove Mount Directory IF Unmount Was Successful
	if [ $RETVAL -eq 0 ]
	  then
		rmdir "$_MOUNT_PREFIX/$_TARGET$EXPORTS"
	fi
   done
   if [ $(cat /etc/mtab | grep $_MOUNT_PREFIX/$_TARGET | wc -l) -eq 0 ]
     then
	if [ -d $_MOUNT_PREFIX/$_TARGET ]
	  then
		echo -e "$COLOR_LT_RED""Removing""$COLOR_NORMAL"": $COLOR_YELLOW $_MOUNT_PREFIX/$_TARGET$COLOR_NORMAL"
		rm -R "$_MOUNT_PREFIX/$_TARGET"
	fi
     else
	echo -e "$COLOR_YELLOW""WARNING$COLOR_NORMAL: $_MOUNT_PREFIX/$_TARGET $_STILL_MTAB"
   fi
};
 
# Define 'domount' Function
# This Function Is What Performs The Mounting
domount()
{
   for EXPORTS in $(showmount $_ARGS $_TARGET) 
   do
	# Create Mount Point if it Does NOT Exist
        if [ ! -d "$_MOUNT_PREFIX/$_TARGET$EXPORTS" ]
          then
		if [ $BOL_TEST -eq 0 ]
		  then
		     if [ $BOL_VERBOSE -eq 1 ]
		       then
			   echo -e "\n$COLOR_LT_GREEN""Creating""$COLOR_NORMAL"": $COLOR_YELLOW  $_MOUNT_PREFIX/$_TARGET""$COLOR_CYAN"" For Our New Mount Point""$COLOR_NORMAL"
		     fi
		     mkdir -p "$_MOUNT_PREFIX/$_TARGET$EXPORTS"
		fi
	  else
		if [ $BOL_VERBOSE -eq 1 ]
		  then
			echo -e "\n"
		fi
        fi
	# IF BOL_TEST is set Display Test Message 
	if [ $BOL_TEST -eq 1 ] 
	  then
		echo -e -n "$_TEST   "
	fi
	printf "%-11s %-45s" "Mounting:" "$_MOUNT_PREFIX/$_TARGET$EXPORTS"
        if [ $BOL_TEST -eq 0 ]
          then
            if [ $(cat /etc/mtab | grep $_MOUNT_PREFIX/$_TARGET$EXPORTS | wc -l) -eq 0 ]
              then
		FULL_MOUNT_STRING="$_MOUNT_NFS_OPT $_TARGET:$EXPORTS $_MOUNT_PREFIX/$_TARGET$EXPORTS"
		_TARGET_NFS_EXPORT="$_TARGET"':'"$EXPORTS"
		_TARGET_MOUNT_DIR="$_MOUNT_PREFIX/$_TARGET$EXPORTS"
		if [ $BOL_VERBOSE -eq 1 ]
		  then
			echo -e "\n$COLOR_PURPLE""mount.nfs""$COLOR_NORMAL"': '"$COLOR_LT_RED""$_TARGET"':'"$EXPORTS" "$COLOR_ORANGE""$_MOUNT_PREFIX/$_TARGET$EXPORTS" "$COLOR_YELLOW""$_MOUNT_OPT" "$COLOR_LT_BLUE""$_MOUNT_EXT_OPT""$COLOR_NORMAL"
			_OUT=$(mount.nfs "$_TARGET_NFS_EXPORT" "$_TARGET_MOUNT_DIR" "$_MOUNT_OPT" "$_MOUNT_EXT_OPT")
			RETVAL=$? 
			echo -e "$COLOR_DK_GRAY$_OUT$COLOR_NORMAL"
			#echo -e "\nmount $FULL_MOUNT_STRING"
			#echo $(mount "$FULL_MOUNT_STRING")
		  else
	        	#mount "$FULL_MOUNT_STRING"
			_OUT=$(mount.nfs "$_TARGET_NFS_EXPORT" "$_TARGET_MOUNT_DIR" "$_MOUNT_OPT" "$_MOUNT_EXT_OPT")
			RETVAL=$?
		fi
		#mount.nfs -n "${_TARGET:$EXPORTS}" "${_MOUNT_PREFIX/$_TARGET$EXPORTS}"
                [ $RETVAL = 0 ] && echo -e "$_SUCCESS"
                [ $RETVAL != 0 ] && echo -e "$_FAILURE"
              else
                echo -e "$_FAILURE\t$_IN_MTAB"
                RETVAL=1
            fi 
          else
                ## Test Parameter is Set
                RETVAL=0
                echo -e "$_SUCCESS"
        fi
   done
export RETVAL
};

# Define 'do_req_parm' Funcion
do_req_parm()
{
   if [ $BOL_RUN_PARAMETER -eq 1 ]
     then
	export _MOUNT_NFS_OPT="$_MOUNT_NFS_OPT"
	if [ $BOL_MOUNT -eq 1 ]
	  then
		for (( MOUNT_COUNT=0; MOUNT_COUNT<=$((SERVER_COUNT)); MOUNT_COUNT++ ))
		do
			# Begin Nested Mount Loop - One Server At A Time
			export _TARGET="${_SERVER_NAME[ $(( MOUNT_COUNT )) ]}"
			export _CURRENT_MOUNT_COUNT=$((MOUNT_COUNT))
			export _MOUNT_OPT="$_MOUNT_OPT"
			export _MOUNT_EXT_OPT="$_MOUNT_EXT_OPT"
			export _MOUNT_NFS_OPT="$_MOUNT_NFS_OPT"
			domount
			RETVAL=$?
		done
		export RETVAL
	elif [ $BOL_UNMOUNT -eq 1 ]
	  then
                for (( MOUNT_COUNT=0; MOUNT_COUNT<=$((SERVER_COUNT)); MOUNT_COUNT++ ))
                do
			# Begin Nested Unmount Loop - One Server At A Time
                        export _TARGET="${_SERVER_NAME[ $(( MOUNT_COUNT )) ]}"
                        export _CURRENT_MOUNT_COUNT=$((MOUNT_COUNT))
                        dounmount
			RETVAL=$?
                done
		export RETVAL
	else
		# This condition should Never Happen!!
		echo -e "How can happen?!?\nSome Debug Stuff:\n"
		echo "BOL_RUN_PARAMETER = $BOL_RUN_PARAMETER"
		echo "BOL_MOUNT = $BOL_MOUNT"
		echo "BOL_UNMOUNT = $BOL_UNMOUNT"
		echo "BOL_BOTH_PARAMETERS = $BOL_BOTH_PARAMETERS"
		export RETVAL=99
	fi		
     else
	echo -n "Nothing to Run?!?"
	if [ $BOL_BOTH_PARAMETERS -eq 1 ]
	  then
		echo -ne "\n$COLOR_RED""Cannot$COLOR_NORMAL Mount and Unmount At The Same Time!!!"
		export RETVAL=100
	fi
	echo
   fi
};
	
# Set Variables and Booleans based on Options Parsed
for i in "$@"
do
case $i in
-m=* | --mount=*)
	((SERVER_COUNT++))
	declare -ag _SERVER_NAME[$((SERVER_COUNT))]="${i#*=}"
	if [ $BOL_UNMOUNT -eq 0 ]
           then
		BOL_REQUIRED_PARAMETER=1
		BOL_RUN_PARAMETER=1
		BOL_MOUNT=1
	   else
		# Cannot Run Both Mount and Unmount Options
		BOL_BOTH_PARAMETERS=1
		BOL_RUN_PARAMETER=0
	fi
	;;
-u=* | --unmount=*)
	((SERVER_COUNT++))
        declare -ag _SERVER_NAME[$((SERVER_COUNT))]="${i#*=}"
        if [ $BOL_MOUNT -eq 0 ]
           then
                BOL_REQUIRED_PARAMETER=1
                BOL_RUN_PARAMETER=1
                BOL_UNMOUNT=1
           else
                # Cannot Run Both Mount and Unmount Options
                BOL_BOTH_PARAMETERS=1
                BOL_RUN_PARAMETER=0
        fi        
        ;;
'-a' | '--alt')
	# Use Alternate Mount Program
	# Default is /sbin/mount.nfs
	# This will Switch it to /bin/mount
	BOL_ALT=1
	;;
'-b' | '--bw')
	# Disable Colorized Text
	# Could Be Useful on Some Older Displays
	# Or A Machine that Cannot Interpret ANSI 
	BOL_COLOR=0
	;;
'-c' | '--color')
	# Enable Colorized Text
	# I Think I Will Make This the Default
	BOL_COLOR=1
	;;
'-t' | '--test')
	# Enable Test Mode
	# Will Loop All The Way Trough The Script
	# But Doesn't Perform the Actual (Un)Mount
	BOL_TEST=1
	;;
'-h' | '--help')
	# Display Help Message
	BOL_HELP=1
	;;
'-v' | '--verbose')
	# Be Verbose, Display What Is Happening
	# In The Background. Doesn't Do Verry Much
	# When Unmounting 
	BOL_VERBOSE=1
	BOL_SET_NFS_ARG=1
	;;
'-3' | '--nfs3')
	BOL_SET_NFS_OPTS=1
	BOL_SET_NFS_VER=1
	NFS_VERS=3
	;;
'-2' | '--nfs2')
        BOL_SET_NFS_OPTS=1
        BOL_SET_NFS_VER=1
        NFS_VERS=2
        ;;
*)
        BOL_RUN_PARAMETER=0
	BOL_UNKNOWN_PARAMETER=1
	echo "Unknown Option: $i"
        ;;
esac
done

# First Thing is First; Enable/Disable Colorized Text
if [ $BOL_COLOR -eq 1 ]
  then
	# Run The Pre-Defined 'initialize_color' Function
	initialize_color
fi

## End The Confusion
## BOL_SET_NFS_ARG is to be used with: mount.nfs
## BOL_SET_NFS_OPTS is to be used with: mount

# Export Number Of Taerget Servers
export SERVER_COUNT=$((SERVER_COUNT))

if [ $BOL_HELP -eq 1 ]
  then
        # IF BOL_HELP Is Enabled, Make Sure All Others are Disabled
        BOL_REQUIRED_PARAMETER=0
        BOL_RUN_PARAMETER=0
fi

if [ $BOL_UNKNOWN_PARAMETER -eq 1 ]
  then
        # IF BOL_UNKNOWN_PARAMETER Is Enabled, Make Sure All Others are Disabled
        BOL_REQUIRED_PARAMETER=0
        BOL_RUN_PARAMETER=0
fi

if [ $BOL_SET_NFS_ARG -eq 1 ]
  then
        _MOUNT_OPT="$_MOUNT_OPT""-"
fi

if [ $BOL_NO_MTAB -eq 1 ]
  then
        _MOUNT_OPT="$_MOUNT_OPT""n"
fi

if [ $BOL_VERBOSE -eq 1 ]
  then
	_MOUNT_OPT="$_MOUNT_OPT""v"
fi

if [ $BOL_SET_NFS_OPTS -eq 1 ]
  then
	_MOUNT_NFS_OPT="$_MOUNT_NFS_OPT -o "
	if [ $BOL_SET_NFS_VER -eq 1 ]
	  then
		## Default 'mount.nfs' Options
		_MOUNT_EXT_OPT="-o,vers=$((NFS_VERS))"

		## Alternate 'mount' Options
		_MOUNT_NFS_OPT="$_MOUNT_NFS_OPT vers=$NFS_VERS"
	fi
fi

# Assemble _ARGS for showmount
export _TARGET="${_SERVER_NAME[0]}"
export _ARGS="$_ARG_DIR $_ARG_HEADER"
export _MOUNT_OPT="$_MOUNT_OPT"
export _MOUNT_EXT_OPT="$_MOUNT_EXT_OPT"
export _MOUNT_NFS_OPT="$_MOUNT_NFS_OPT"

if [ $BOL_REQUIRED_PARAMETER -eq 1 ]
  then
	# Export All Booleans Before Calling Next Function
	export BOL_REQUIRED_PARAMETER=$((BOL_REQUIRED_PARAMETER))
	export BOL_RUN_PARAMETER=$((BOL_RUN_PARAMETER))
	export BOL_BOTH_PARAMETERS=$((BOL_BOTH_PARAMETERS))
	export BOL_UNMOUNT=$((BOL_UNMOUNT))
	export BOL_MOUNT=$((BOL_MOUNT))
	export BOL_HELP=$((BOL_HELP))
	export BOL_TEST=$((BOL_TEST))
	export BOL_VERBOSE=$((BOL_VERBOSE))
	export BOL_NO_MTAB=$((BOL_NO_MTAB))
	export BOL_SET_NFS_OPTS=$((BOL_SET_NFS_OPTS))
        export BOL_SET_NFS_VER=$((BOL_SET_NFS_VER))
        export BOL_SET_NFS_ARG=$((BOL_SET_NFS_ARG))
	export BOL_UNKNOWN_PARAMETER=$((BOL_UNKNOWN_PARAMETER))

	# All Is Good! Call 'do_req_parm()' Function!
	do_req_parm
  else
	if [ $BOL_HELP -eq 1 ]
	  then
		# Call Dispaly Help Function
		do_display_help
	  else
		echo "Usage: $0 {-m=<server> --mount=<server>|-u=<server> --unmount=<server>|-h --help }"
	fi
	RETVAL=1
fi
## End Of Script, Now We Can Exit!
exit $RETVAL
