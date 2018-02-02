#!/bin/bash

source run-guest-common.sh
source run-guest-L0.sh

IOMMU="-device virtio-iommu-device"

NETDEV_IOMMU_OPTION="iommu_platform=on,disable-modern=off,disable-legacy=on"
NETDEV="-netdev tap,id=net2,vhost=off"
NETDEV="$NETDEV -device virtio-net-pci,netdev=net2,$NETDEV_IOMMU_OPTION"

source qemu-command.sh
