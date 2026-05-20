#!/bin/sh

QEMU_ROOT="/opt/qemu/dev/OpenWRT/arm/32/0.2"
QEMU_CMDLINE="$1 $2 $3 $4 $5 $6 $7 $8 $9"

QEMU_IMAGE_VDA="sdcard/openwrt-armvirt-32-root.ext4"
QEMU_IMAGE_VDB="sdcard/2gb.img"

QEMU_IF_NAME0="tap0"
QEMU_IF_NAME1="tap1"

QEMU_VIDEO="-nographic -M virt"
QEMU_MEMORY="-m 64"

QEMU_NETWORK_INTERFACE="e1000"
#QEMU_NETWORK_INTERFACE="virtio-net-pci"

QEMU_NET_ETH0="-netdev tap,id=veth0,ifname=$QEMU_IF_NAME0,script=no,downscript=no"
QEMU_NET_ETH1="-netdev tap,id=veth1,ifname=$QEMU_IF_NAME1,script=no,downscript=no"

QEMU_DEVICE_ETH0="-device $QEMU_NETWORK_INTERFACE,netdev=veth0,mac=aa:d2:28:65:ad:f6"
QEMU_DEVICE_ETH1="-device $QEMU_NETWORK_INTERFACE,netdev=veth1,mac=aa:d2:28:65:ed:1a"

QEMU_ETH0="$QEMU_NET_ETH0 $QEMU_DEVICE_ETH0"
QEMU_ETH1="$QEMU_NET_ETH1 $QEMU_DEVICE_ETH1"

QEMU_NETWORK="$QEMU_ETH0 $QEMU_ETH1"

QEMU_BOOT_KERNEL="-kernel $QEMU_ROOT/openwrt-armvirt-32-zImage"
QEMU_BOOT_OPTIONS="-append root=/dev/vda"
#QEMU_BOOT_INITRD="-initrd $QEMU_ROOT/openwrt-armvirt-32-zImage-initramfs"
QEMU_BOOT="$QEMU_BOOT_KERNEL $QEMU_BOOT_OPTIONS $QEMU_BOOT_INITRD"

QEMU_DRIVE_VDA="-drive file=$QEMU_ROOT/$QEMU_IMAGE_VDA,format=raw,if=virtio,index=0"
#QEMU_DRIVE_VDB="-drive file=$QEMU_ROOT/$QEMU_IMAGE_VDB,format=raw,if=virtio,index=1"
QEMU_DRIVES="$QEMU_DRIVE_VDA $QEMU_DRIVE_VDB"

QEMU_MACHINE="$QEMU_VIDEO $QEMU_MEMORY $QEMU_NETWORK $QEMU_BOOT $QEMU_DRIVES $QEMU_CMDLINE"

echo $QEMU_MACHINE
echo
echo Executing qemu-system-arm
qemu-system-arm $QEMU_MACHINE

