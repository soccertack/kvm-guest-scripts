IOMMU="-device intel-iommu,intremap=on"
MACHINE="${MACHINE},kernel-irqchip=split"

if [ "$PI" == 1 ]; then
	QEMU="./qemu-pi/x86_64-softmmu/qemu-system-x86_64"
	IOMMU="$IOMMU,intpost=on"
fi

#TODO: why the options are different?
if [ "$1" == "pt" ]; then
	IOMMU="$IOMMU,caching-mode=on"
elif [ "$1" == "vp" ]; then
	IOMMU="$IOMMU,device-iotlb=on"
fi
