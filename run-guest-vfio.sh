#!/bin/bash

source run-guest-common.sh

source setup-vfio.sh

# Do not provide a normal virtio-net device.
# Doing that resulted in a severe performance drop for vp on x86
VIRTIO_NETDEV=""

if [[ "$ARCH" == "x86_64" ]]; then
	QEMU=./qemu-vfio-migration/x86_64-softmmu/qemu-system-x86_64
	CONSOLE="telnet:127.0.0.1:$TELNET_PORT,server,nowait"
	MON="-monitor stdio"
	source qemu-command-x86.sh
else
	source qemu-command-arm.sh
fi
