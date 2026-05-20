#!/bin/sh

/nfs/lxc.gigaware.lan/usr/local/scripts/misc/UnisonServers-0.4.1.sh --custom-folder=/usr/local/{bin,etc,games,include,lib,lib64,libexec,sbin,scripts,share} \
 --add-folder=/home/pete/{.config,.kde,.local,Desktop,Documents,Downloads,Music,Pictures} $@

