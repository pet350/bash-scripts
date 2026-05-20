#! /bin/sh

_ARG1=" --directories" 
#_ARG1=" --exports"
_ARG2=" --no-header"

_ARGS="$_ARG1 $_ARG2 $@"
_MOUNT_PREFIX="/nfs"

for EXPORTS in $(showmount $_ARGS) 
do
	if [ ! -d "$_MOUNT_PREFIX" ]
	  then
		 mkdir "$_MOUNT_PREFIX"
	fi
        
	if [ ! -d "$_MOUNT_PREFIX/$1" ]
          then
                 mkdir -p "$_MOUNT_PREFIX/$1"
        fi

        if [ ! -d "$_MOUNT_PREFIX/$1$EXPORTS" ]
          then
                 mkdir -p "$_MOUNT_PREFIX/$1$EXPORTS"
        fi
	mount.nfs -n -v "$1:$EXPORTS" "$_MOUNT_PREFIX/$1$EXPORTS"

done

