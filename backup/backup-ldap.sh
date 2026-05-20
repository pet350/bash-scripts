#! /bin/bash
## VERRY Simple Script to Backup LDAP Database

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


if [ $(id -u) -ne 0 ]; then
	echo "Must be ran as root!"
	exit 1
fi

# define dow (day of week) and hostname
dow=$(date +%w)
hostname=$(hostname -s)

# Define Destination Path
dest="/opt/bak/$hostname"

# Create Destination if it does NOT exist
if [ ! -d $dest ]; then
        mkdir -p $dest
fi

# Define SLAPCAT location and binary
SLAPCAT="/usr/sbin/slapcat"

# Define Prefix
PREFIX="/usr/local/sbin"

# Define Archive File Name
archive_file="$dow-$hostname-mdb.tar.gz"

# Use slapcat to dump databse into ldif files
nice ${SLAPCAT} -n 0 > ${dest}/config.ldif
nice ${SLAPCAT} -n 1 > ${dest}/gigaware.lan.ldif

# Python scripts to remove extra crap that isn't needed
python $PREFIX/RmCfgStruct.py >/dev/null
python $PREFIX/RmDBStruct.py >/dev/null

# Compress all ldif files into gzip
tar czvf $dest/$archive_file $dest/*.ldif

# Remove Not Needed Files
rm $dest/*.ldif

# Done!
