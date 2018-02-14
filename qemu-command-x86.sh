#!/bin/bash

echo "---------- QEMU setup -------------"
echo "SMP: "$SMP
echo "MEMSIZE: "$MEMSIZE
echo "MACHINE: "$MACHINE
echo "IOMMU: "$IOMMU
echo "VIRTIO-net: "$VIRTIO_NETDEV
echo "VFIO_DEV: "$VFIO_DEV
echo "VFIO_DEV2: "$VFIO_DEV2
echo "IOMMU_VIRTIO_NETDEV: " $IOMMU_VIRTIO_NETDEV
echo "IOMMU_VIRTIO_NETDEV2: " $IOMMU_VIRTIO_NETDEV2
echo "---------- QEMU setup end ---------"
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
