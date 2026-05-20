#! /bin/bash
# Setup new root file system
#
for i in run proc sys dev/pts dev; do sudo umount mnt/; done
#
for i in dev dev/pts sys proc run; do sudo mount --bind / mnt/; done
