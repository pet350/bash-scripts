#! /bin/sh

# Set Boolean(s)
BOL_REQUIRED_PARAMETER=0
BOL_RUN_PARAMETER=0
BOL_BOTH_PARAMETERS=0
BOL_UNMOUNT=0
BOL_MOUNT=0
BOL_HELP=0

export _ARG_DIR=" --directories" 
export _ARG_HEADER=" --no-header"
export _MOUNT_PREFIX="/nfs"

do_display_help()
{
   echo "Help! Section"
};

# Define 'dounmount' Function
dounmount()
{
   for EXPORTS in $(showmount $_ARGS)
   do
	echo "Unmounting $_MOUNT_PREFIX/$_TARGET$EXPORTS"
	umount "$_MOUNT_PREFIX/$_TARGET$EXPORTS" >/dev/null
        RETVAL=$?
        [ $RETVAL = 0 ] && echo -e "\t[Success]"
        [ $RETVAL != 0 ] && echo -e "\t[Failure]"
        echo
	if [ $RETVAL -eq 0 ]
	  then
		rmdir "$_MOUNT_PREFIX/$_TARGET$EXPORTS"
	fi
   done
}
 
# Define 'domount' Function
domount()
{
   for EXPORTS in $(showmount $_ARGS) 
   do
        if [ ! -d "$_MOUNT_PREFIX/$_TARGET$EXPORTS" ]
          then
                 mkdir -p "$_MOUNT_PREFIX/$_TARGET$EXPORTS"
        fi
	echo "mounting $_MOUNT_PREFIX/$_TARGET$EXPORTS"
	mount.nfs -n "$_TARGET:$EXPORTS" "$_MOUNT_PREFIX/$_TARGET$EXPORTS"
        RETVAL=$?
        [ $RETVAL = 0 ] && echo -e "\t[Success]"
        [ $RETVAL != 0 ] && echo -e "\t[Failure]"
        echo
   done
};

# Define 'do_req_parm' Funcion
do_req_parm()
{
   if [ $BOL_RUN_PARAMETER -eq 1 ]
     then
	if [ $BOL_MOUNT -eq 1 ]
	  then
		domount
	fi
	if [ $BOL_UNMOUNT -eq 1 ]
	  then
		dounmount
	fi		
     else
	echo -n "Nothing to Run?!?"
	echo
   fi
};
	
# Set Variables and Booleans based on Options Parsed
for i in "$@"
do
case $i in
-m=* | --mount=*)
	export _TARGET="${i#*=}"
	if [ $BOL_REQUIRED_PARAMETER -eq 0 ]
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
        export _TARGET="${i#*=}"
        if [ $BOL_REQUIRED_PARAMETER -eq 0 ]
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
'-h' | '--help')
	BOL_HELP=1
	;;
esac
done

if [ $BOL_HELP -eq 1 ]
  then
        # IF BOL_HELP Is Enabled, Make Sure All Others are Disabled
        BOL_REQUIRED_PARAMETER=0
        BOL_RUN_PARAMETER=0
fi

# Assemble _ARGS for showmount
export _ARGS="$_ARG_DIR $_ARG_HEADER $_TARGET"

if [ $BOL_REQUIRED_PARAMETER -eq 1 ]
  then
	export BOL_REQUIRED_PARAMETER=$BOL_REQUIRED_PARAMETER
	export BOL_RUN_PARAMETER=$BOL_RUN_PARAMETER
	export BOL_BOTH_PARAMETERS=$BOL_BOTH_PARAMETERS
	export BOL_UNMOUNT=$BOL_UNMOUNT
	export BOL_MOUNT=$BOL_MOUNT
	export BOL_HELP=$BOL_HELP
	do_req_parm
  else
	if [ $BOL_HELP -eq 1 ]
	  then
		do_display_help
	  else
		echo "Usage: $0 { -m=<server> --mount=<server> | -u=<server> --unmount=<server> | -h --help }"
	fi
  RETVAL=1
fi
exit $RETVAL
