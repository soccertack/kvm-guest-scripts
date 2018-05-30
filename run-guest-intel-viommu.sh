#!/bin/bash

source run-guest-common.sh

IOMMU="-device intel-iommu,intremap=on,device-iotlb=on"

NETDEV_IOMMU_OPTION="iommu_platform=on,disable-modern=off,disable-legacy=on,ats=on"

#Uncomment below if you want to provide one more virtio device behind virtual IOMMU.
#IOH="-device ioh3420,id=pcie.1,chassis=1"
#IOMMU_VIRTIO_NETDEV="-netdev tap,id=net1,vhostforce"
#IOMMU_VIRTIO_NETDEV="$IOMMU_VIRTIO_NETDEV -device virtio-net-pci,netdev=net1,bus=pcie.1,$NETDEV_IOMMU_OPTION"
#VIRTIO_NETDEV=""

IOH2="-device ioh3420,id=pcie.1,chassis=2"
IOMMU_VIRTIO_NETDEV2="-netdev tap,id=net2,vhostforce"
IOMMU_VIRTIO_NETDEV2="$IOMMU_VIRTIO_NETDEV2 -device virtio-net-pci,netdev=net2,bus=pcie.1,$NETDEV_IOMMU_OPTION"

MACHINE="q35,accel=kvm,kernel-irqchip=split"

QEMU="./qemu-posted/x86_64-softmmu/qemu-system-x86_64"
IOMMU="$IOMMU,intpost=on"

#Uncomment below if you want to run Xen as a guest hypervisor
#QEMU="./qemu-xen-fix/x86_64-softmmu/qemu-system-x86_64"
source qemu-command-x86.sh

