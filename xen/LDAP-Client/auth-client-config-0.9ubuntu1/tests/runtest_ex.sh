#!/bin/bash

#set -x

# example usage for successful run
#$ACCPATH/usr/sbin/auth-client-config -h >> $ACCTMP/result 2>&1 || exit 1

# example usage for failed run
#$ACCPATH/usr/sbin/auth-client-config -a -p ldap >> $ACCTMP/result 2>&1 && exit 1

# remove this when implementing real test
touch $ACCTMP/result || exit 1

exit 0
