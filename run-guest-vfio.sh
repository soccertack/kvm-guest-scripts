#!/bin/bash

source run-guest-common.sh

source vfio-common.sh

VFIO_DEV="-device vfio-pci,host=$BDF,id=net2"

if [[ "$ARCH" == "x86_64" ]]; then
	source qemu-command-arm.sh
else
	source qemu-command-x86.sh
fi
