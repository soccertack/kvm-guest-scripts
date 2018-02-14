#!/bin/bash

source run-guest-common.sh

source vfio-common.sh

IOMMU="-device intel-iommu,intremap=on,caching-mode=on"

MACHINE="q35,accel=kvm,kernel-irqchip=split"

VFIO_DEV="-device vfio-pci,host=$BDF,id=net2"

# Don't provide virtio-net for now. We eventually need it to pin L2 vcpus
VIRTIO_NETDEV=""

source qemu-command-x86.sh

