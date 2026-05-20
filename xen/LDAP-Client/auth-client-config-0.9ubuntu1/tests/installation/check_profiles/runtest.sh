#!/bin/bash

$ACCPATH/usr/sbin/auth-client-config -l >> $ACCTMP/result || exit 1
$ACCPATH/usr/sbin/auth-client-config -L >> $ACCTMP/result || exit 1

exit 0
