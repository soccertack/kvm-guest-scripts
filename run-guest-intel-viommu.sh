#!/bin/bash

source run-guest-common.sh

IOMMU="-device intel-iommu,intremap=on,device-iotlb=on"
IOH="-device ioh3420,id=pcie.1,chassis=1"

NETDEV_IOMMU_OPTION="iommu_platform=on,disable-modern=off,disable-legacy=on,ats=on"
IOMMU_VIRTIO_NETDEV="-netdev tap,id=net2,vhostforce"
IOMMU_VIRTIO_NETDEV="$IOMMU_VIRTIO_NETDEV -device virtio-net-pci,netdev=net2,bus=pcie.1,$NETDEV_IOMMU_OPTION"

MACHINE="q35,accel=kvm,kernel-irqchip=split"

source qemu-command-x86.sh

