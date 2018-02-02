#!/bin/bash

source run-guest-common.sh

IOMMU="-device smmuv3"

NETDEV_IOMMU_OPTION="iommu_platform=on,disable-modern=off,disable-legacy=on"
IOMMU_VIRTIO_NETDEV="-netdev tap,id=net2,vhost=off"
IOMMU_VIRTIO_NETDEV="$IOMMU_VIRTIO_NETDEV -device virtio-net-pci,netdev=net2,$NETDEV_IOMMU_OPTION"

source qemu-command.sh
