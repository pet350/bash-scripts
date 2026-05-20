#!/bin/bash

source /usr/local/src/xen-scripts.sh

StoreXenArray

VAR_COUNT=${#XEN_NAME_ARRAY[@]}
printf "%-15s\t\t%d\n" "Array Count: " $((VAR_COUNT))
printf "%-15s\t\t%d\n" "Found Count: " $((XEN_FOUND_DOMAIN_COUNT))
printf "%-15s\t%d\n" "Reported Count: " $((XEN_REPORTED_DOMAIN_COUNT))
printf "%-15s\t%d\n" "libxl-json Count: " $((XEND_LIBXL_JSON_COUNT))
StoreXendUUID

index=-1
for x in ${XEND_UUID_ARRAY[@]}; do
   ((index++))
   printf "%-7s %-20s\t" "UUID:" "$x"
   printf "%-7s %-17s\t" "NAME:" "${XEND_NAME_ARRAY[$((index))]}"
   printf "%-7s %-5s\t" "VDEV:" "${XEND_VDEV_ARRAY[$((index)),0]}"
   printf "%-7s %-20s\n" "DISK:" "${XEND_DISK_ARRAY[$((index)),0]}"
done

