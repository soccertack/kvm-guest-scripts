#!/bin/bash

if [[ -n $VIRTIO_NETDEV ]]; then
	./net.sh
fi

if [[ -n $IOMMU_VIRTIO_NETDEV ]]; then
	./net.sh
fi

if [[ -n $VIOMMU_VIRTIO_NETDEV2 ]]; then
	./net.sh
fi

if [[ -n $QEMU_F ]]; then
	QEMU=$QEMU_F/x86_64-softmmu/qemu-system-x86_64
fi

if [[ -n $MONITOR_F ]]; then
	CONSOLE="telnet:127.0.0.1:$TELNET_PORT,server,nowait"
	MON="-monitor stdio"
fi

echo "---------- QEMU setup -------------"
echo "SMP: "$SMP
echo "MEMSIZE: "${MEMSIZE}G
echo "FS: "$FS
echo "MACHINE: "$MACHINE
echo "IOMMU: "$IOMMU
echo "VIRTIO-net: "$VIRTIO_NETDEV
echo "VFIO_DEV: "$VFIO_DEV
echo "VFIO_DEV2: "$VFIO_DEV2
echo "IOMMU_VIRTIO_NETDEV: " $IOMMU_VIRTIO_NETDEV
echo "IOMMU_VIRTIO_NETDEV2: " $IOMMU_VIRTIO_NETDEV2
echo "---------- QEMU setup end ---------"
sudo $QEMU	\
	$IOMMU		\
	-smp $SMP -m ${MEMSIZE}G -M $MACHINE -cpu host$CPU_HV	\
	-drive if=none,file=$FS,id=vda,cache=none,format=raw	\
	-device virtio-blk-pci,drive=vda	\
	--nographic	\
	-qmp unix:/var/run/qmp,server,nowait \
	-serial $CONSOLE	\
	$USER_NETDEV	\
	$VIRTIO_NETDEV	\
	$IOH		\
	$IOMMU_VIRTIO_NETDEV	\
	$IOH2		\
	$IOMMU_VIRTIO_NETDEV2	\
	$VFIO_DEV	\
	$MON		\
	"${MIGRAION[@]}"	\
	$WINDOWS_OPTIONS	\
#	-trace enable=vfio_region_setup,file=abc \

