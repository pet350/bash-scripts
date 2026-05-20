#! /bin/sh

_LIB_PREFIX="/lib/modules"
_LIB_PREFIX_KERNEL="$(uname -r)"
_LIB_PREFIX="$_LIB_PREFIX/$_LIB_PREFIX_KERNEL/kernel/drivers/xen"
_LIB_PCIBACK_PATH="xen-pciback"
_TARGET_MODULE="xen-pciback.ko"

ls "$_LIB_PREFIX/$_LIB_PCIBACK_PATH/$_TARGET_MODULE"
