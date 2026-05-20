#!/bin/bash


BIN_PREFIX="/usr/bin"
OVS_BIN="$BIN_PREFIX/ovs-vsctl"

BRIDGE_CONFIG="stp_enable=true other_config:stp-max-age=6 other_config:stp-forward-delay=4"

BRIDGE="$1"
BOND="$2"
NET0="$3"
NET1="$4"

$OVS_BIN addbr $BRIDGE
$OVS_BIN set bridge $BRIDGE $BRIDGE_CONFIG
$OVS_BIN add-bond $BRIDGE $BOND $NET0 $NET1

