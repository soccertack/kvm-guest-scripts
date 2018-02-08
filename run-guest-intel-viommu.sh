#!/bin/bash

source run-guest-common.sh

QEMU=./qemu/x86_64-softmmu/qemu-system-x86_64
FS=/vm/guest0.img

SMP=6
MEMSIZE=$((16 * 1024))

IOMMU="-device intel-iommu,intremap=on,device-iotlb=on"
IOH="-device ioh3420,id=pcie.1,chassis=1"

NETDEV_IOMMU_OPTION="iommu_platform=on,disable-modern=off,disable-legacy=on,ats=on"
IOMMU_VIRTIO_NETDEV="-netdev tap,id=net2,vhostforce"
IOMMU_VIRTIO_NETDEV="$IOMMU_VIRTIO_NETDEV -device virtio-net-pci,netdev=net2,bus=pcie.1,$NETDEV_IOMMU_OPTION"

source qemu-command-x86.sh

