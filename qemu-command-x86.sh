#!/bin/bash

sudo $QEMU	\
	-smp $SMP -m $MEMSIZE -M $MACHINE -cpu host	\
	-drive if=none,file=$FS,id=vda,cache=none,format=raw	\
	-device virtio-blk-pci,drive=vda	\
	--nographic	\
	$USER_NETDEV	\
	$VIRTIO_NETDEV	\
	$IOMMU		\
	$IOH		\
	$IOMMU_VIRTIO_NETDEV	\
	$VFIO_DEV	\