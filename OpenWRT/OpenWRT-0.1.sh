#!/bin/sh

QEMU_ROOT="/opt/bak/MD2/OpenWRT/arm32"

QEMU_IMAGE_VDA="sdcard/openwrt-armvirt-32-root.ext4"
QEMU_IMAGE_VDB="sdcard/2gb.img"

QEMU_VIDEO="-nographic -M virt"
QEMU_MEMORY="-m 64"

QEMU_DEVICE_ETH0="-device e1000,netdev=eth0,id=eth0"
QEMU_NET_ETH0="-netdev tap,id=eth0,ifname=host-bridge-br0,script=no,downscript=no"
QEMU_ETH0="$QEMU_DEVICE_ETH0 $QEMU_NET_ETH0"

QEMU_DEVICE_ETH1="-device e1000,netdev=eth1,id=eth1"
QEMU_NET_ETH1="-netdev tap,id=eth1,ifname=host-bridge-br1,script=no,downscript=no"
QEMU_ETH1="$QEMU_DEVICE_ETH1 $QEMU_NET_ETH1"

QEMU_NETWORK="$QEMU_ETH0 $QEMU_ETH1"

QEMU_BOOT_KERNEL="-kernel $QEMU_ROOT/openwrt-armvirt-32-zImage"
QEMU_BOOT_KERNEL_OPTIONS="-append 'root=/dev/vda rootwait'"
QEMU_BOOT="$QEMU_BOOT_KERNEL $QEMU_BOOT_KERNEL_OPTIONS"

QEMU_DRIVE_VDA="-drive file=$QEMU_ROOT/$QEMU_IMAGE_VDA,format=raw,if=virtio"
QEMU_DRIVE_VDB="-drive file=$QEMU_ROOT/$QEMU_IMAGE_VDB,format=raw,if=virtio"
QEMU_DRIVES="$QEMU_DRIVE_VDA $QEMU_DRIVE_VDB"

QEMU_MACHINE="$QEMU_VIDEO $QEMU_MEMORY $QEMU_NETWORK $QEMU_BOOT_KERNEL $QEMU_DRIVES $QEMU_BOOT_KERNEL_OPTIONS"

echo $QEMU_MACHINE
echo
echo Executing qemu-system-arm
qemu-system-arm $QEMU_MACHINE

