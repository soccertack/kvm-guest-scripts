#!/bin/bash

source run-guest-common.sh

source setup-vfio.sh

if [[ "$ARCH" == "x86_64" ]]; then
	IOMMU="-device intel-iommu,intremap=on,caching-mode=on"
	MACHINE="q35,accel=kvm,kernel-irqchip=split"
	QEMU="./qemu-vtd-fix/x86_64-softmmu/qemu-system-x86_64"
	source qemu-command-x86.sh
else
	source qemu-command-arm.sh
fi
