#!/bin/bash
# Shell Script By: Peter Talbott

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
export VERSION="0.1"
export MOD_DATE="2021-08-23"

declare -ag SEARCH_ARRAY=();
declare -ag IGNORE_ARRAY=();

declare -ig SEARCH_ARRAY_LEN=${#SEARCH_ARRAY[@]}
declare -ig IGNORE_ARRAY_LEN=${#IGNORE_ARRAY[@]}
declare -ig RETURN_VALUE=$SUCCESS

function STORE_INSTALLED
for ARGS in $@; do
  case ${ARGS,,} in
    --not-installed	| --ni)	declare -ig LIST_INSTALLED=$FALSE;	declare -ig LIST_NOT_INSTALLED=$TRUE;;
    --installed		| --i)	declare -ig LIST_INSTALLED=$TRUE;	declare -ig LIST_NOT_INSTALLED=$FALSE;;
    --verbose		| -v)   declare -ig BOL_VERBOSE=$TRUE;		declare -ig BOL_QUIET=$FALSE;		export VERBOSE="--verbose";;
    --quiet		| -q)   declare -ig BOL_VERBOSE=$FALSE		declare -ig BOL_QUIET=$TRUE;		export VERBOSE="";;
    --test		| -t)   declare -ig BOL_TEST=$TRUE;;
    --version) printf "%-20s\tVersion: %s\nBy: Peter Talbott\t%s\n" $RUN_CMD $MOD_DATE; 			exit $SUCCESS;;
    --ignore=*)			IGNORE_ARRAY_LEN=${#IGNORE_ARRAY[@]};	IGNORE_ARRAY[$((IGNORE_ARRAY_LEN))]="${ARGS#*=}";;
    *)				SEARCH_ARRAY_LEN=${#SEARCH_ARRAY[@]};	SEARCH_ARRAY[$((SEARCH_ARRAY_LEN))]=$ARGS;;
  esac
done

IGNORE_ARRAY_LEN=${#IGNORE_ARRAY[@]};		SEARCH_ARRAY_LEN=${#SEARCH_ARRAY[@]}; 
if [ ${#LIST_INSTALLED}	-eq 0 ] && [ ${#LIST_NOT_INSTALLED} -eq 0 ] && [ $SEARCH_ARRAY_LEN -eq 0 ] && [ $IGNORE_ARRAY_LEN -eq 0 ]; then printf "%-20s\tVersion: %s\nNothing to do!\n" $RUN_CMD $VERSION; 	exit $SUCCESS;	fi

exit $RETURN_VALUE
