#!/bin/bash

source run-guest-common.sh

source vfio-common.sh

IOMMU="-device intel-iommu,intremap=on,caching-mode=on"

MACHINE="q35,accel=kvm,kernel-irqchip=split"

source qemu-command-x86.sh

