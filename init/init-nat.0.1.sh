#! /bin/bash
# Simple Script to Setup NAT Routing

export INSIDE="br0"
export OUTSIDE="wlan0"

declare -ag RULES_ARRAY=("--flush" "--table nat --flush" "--delete-chain" "--table nat --delete-chain" "--table nat --append POSTROUTING --out-interface $OUTSIDE -j MASQUERADE" "--append FORWARD --in-interface $INSIDE -j ACCEPT");
declare -ig _VAR_RULES_ARRAY_COUNT=${#RULES_ARRAY[@]}
declare -ig _VAR_RULES_ARRAY_INDEX=$(( _VAR_RULES_ARRAY_COUNT -1))

for (( _INDEX=0; $((_INDEX)) <= $((_VAR_RULES_ARRAY_INDEX)); _INDEX++ )); do
	iptables ${RULES_ARRAY[ $(( _INDEX )) ]} --verbose
done
echo 1 >/proc/sys/net/ipv4/ip_forward

