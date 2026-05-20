#! /bin/sh

_ARG1=" --directories" 
_ARG2=" --no-header"

_ARGS="$_ARG1 $_ARG2 $@"
echo $_ARGS

_TMP_FILE="/tmp/auto.nfs.tmp"

showmount $_ARGS >$_TMP_FILE

# read $FILE using the file descriptors
exec 3<&0
exec 0<$_TMP_FILE
while read PATHNAME
do


	echo $1		$PATHNAME
done
exec 0<&3

#rm -v $_TMP_FILE

# Other Way
	for M in $(showmount $_ARGS) 
	do
		echo $M
	done

