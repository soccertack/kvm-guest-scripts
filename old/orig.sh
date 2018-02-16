CONSOLE=mon:stdio


#		-drive file=/vm/guest0.img,format=raw \
FS=/vm/guest0.img

sudo ./qemu/x86_64-softmmu/qemu-system-x86_64 -M q35,accel=kvm,kernel-irqchip=split -m 16G -smp 6 \
			-cpu host \
			-device intel-iommu,intremap=on,device-iotlb=on \
			-device ioh3420,id=pcie.1,chassis=1 \
			-device virtio-net-pci,bus=pcie.1,netdev=net0,disable-legacy=on,disable-modern=off,iommu_platform=on,ats=on \
			-netdev tap,id=net0,vhostforce \
			-device ioh3420,id=pcie.2,chassis=2 \
			-device virtio-net-pci,bus=pcie.2,netdev=net1,disable-legacy=on,disable-modern=off,iommu_platform=on,ats=on \
			-netdev tap,id=net1,vhostforce \
			-qmp unix:/var/run/qmp,server,nowait \
			--nographic	\
			-drive if=none,file=$FS,id=vda,cache=none,format=raw \
			-device virtio-blk-pci,drive=vda \
			-serial $CONSOLE

