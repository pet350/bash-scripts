#! /bin/sh

# What to backup
backup_source="/opt/video/movies"

# Where to backup to.
dest="/opt/bak/MD0/movies"

# Archive file name
arch_name="movies"

# Create destination directory if it does not exist
if [ ! -d "$dest" ]
then
   mkdir $dest
   chown root:root $dest
   chmod 0700 $dest
fi

## Do the backup Job with these options:
## -as		Synchronize archive contents
## -r		Recurse subdirectories
## -rr10	Add data recovery record
## -s		Create solid groups
## -m0		Set compression level (0-store)
## -ow		Save file owner and group
## -ol		Save symbolic links as the link instead of the file
## -v512M	Create volumes with size=512Mb
## -vn		Traditional Names (.rar, .r00, .r01, etc.)
## -y		Assume Yes on all queries
rar u -r -rr10 -s -m0 -ow -ol -v512M -y $dest/$arch_name $backup_source/*

chown root:root $dest/*
chmod -v 0600 $dest/*
