#!/bin/bash

if [ $# -eq 0 ]; then
    echo "Require PCI devices in format:  <domain>:<bus>:<slot>.<function>" 
    echo "Eg: $(basename $0) 0000:00:1b.0"
    exit 1
fi

modprobe pciback

for pcidev in $@; do
    if [ -h /sys/bus/pci/devices/"$pcidev"/driver ]; then
        echo "Unbinding $pcidev from" $(basename $(readlink /sys/bus/pci/devices/"$pcidev"/driver))
        echo -n "$pcidev" > /sys/bus/pci/devices/"$pcidev"/driver/unbind
    fi
    echo "Binding $pcidev to pciback"
    echo -n "$pcidev" > /sys/bus/pci/drivers/pciback/new_slot
    echo -n "$pcidev" > /sys/bus/pci/drivers/pciback/bind
done
