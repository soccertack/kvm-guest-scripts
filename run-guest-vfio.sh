#!/bin/bash

source run-guest-common.sh

source vfio-common.sh

VFIO_DEV="-device vfio-pci,host=$BDF,id=net2"

# Do not provide a normal virtio-net device.
# Doing that will result in a severe performance drop.
VIRTIO_NETDEV=""

if [[ "$ARCH" == "x86_64" ]]; then
	source qemu-command-x86.sh
else
	source qemu-command-arm.sh
fi
