#! /bin/bash
## VERY Simple Script to Create LXC Volume Symlinks

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

# Define RUN_CMD and VERSION
export RUN_CMD="$(basename $0)"
export VERSION="0.1"
export AUTHOR="Peter Talbott"
export MODIFIED="2021-08-26, 2021-09-14, 2021-10-23"

for ARGS in $@; do
  case ${ARGS,,} in
    --verbose | -v) export VERBOSE="-v"; declare -i BOL_VERBOSE=$TRUE;;
    --prefix=*) CFG_PRE="${ARGS#*=}";;
    --config=*)	CFG_FILE="${ARGS#*=}";;
    --version) printf "%-35s\tVersion: %s\nBy: %-30s\tLast Updated: %s\n\n" "$RUN_CMD" "$VERSION" "$AUTHOR" "$MODIFIED";;
  esac
done

if [ ${#CFG_PRE}	-eq 0 ]; then export CFG_PRE="/etc/libvirt/lxc/volumes";			fi
if [ ${#CFG_FILE}	-eq 0 ]; then export CFG_FILE="$CFG_PRE/vol.cfg";				fi
if [ -f $CFG_FILE	      ]; then . $CFG_FILE; else echo -e "$CFG_FILE Not Found!"; exit $FAILURE;	fi

declare -i INDEX=-1
for VOL_LABEL in ${LABEL_ARRAY[@]}; do
  ((INDEX++))
  $LN_BIN $VERBOSE -s -f $($BLKID_BIN --label $VOL_LABEL) $CFG_PRE/$VOL_LABEL
done

