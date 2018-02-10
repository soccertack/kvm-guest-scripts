#!/bin/bash

sudo $QEMU	\
	-smp $SMP -m $MEMSIZE -M $MACHINE -cpu host	\
	-drive if=none,file=$FS,id=vda,cache=none,format=raw	\
	-device virtio-blk-pci,drive=vda	\
	--nographic	\
	-qmp unix:/var/run/qmp,server,nowait \
	-serial $CONSOLE	\
	$USER_NETDEV	\
	$VIRTIO_NETDEV	\
	$IOMMU		\
	$IOH		\
	$IOMMU_VIRTIO_NETDEV	\
	$IOH2		\
	$IOMMU_VIRTIO_NETDEV2	\
	$VFIO_DEV	\
