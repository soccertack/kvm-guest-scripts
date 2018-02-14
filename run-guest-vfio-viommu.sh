#!/bin/bash

source run-guest-common.sh

source vfio-common.sh

if [[ "$ARCH" == "x86_64" ]]; then
	IOMMU="-device intel-iommu,intremap=on,caching-mode=on"
	MACHINE="q35,accel=kvm,kernel-irqchip=split"
	source qemu-command-x86.sh
else
	source qemu-command-arm.sh
fi
