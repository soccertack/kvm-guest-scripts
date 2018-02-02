./qemu-system-aarch64 \
        -smp $SMP -m $MEMSIZE -machine virt${DUMPDTB} -cpu host,$NESTED \
        -kernel ${KERNEL} -enable-kvm ${DTB} \
        -drive if=none,file=$FS,id=vda,cache=none,format=raw \
        -device virtio-blk-pci,drive=vda \
        -display none \
	-serial $CONSOLE \
	-qmp unix:/var/run/qmp,server,nowait \
	-append "console=ttyAMA0 root=/dev/vda rw $CMDLINE" \
	$USER_NETDEV	\
	$VIRTIO_NETDEV	\
	$IOMMU	\
	$IOMMU_VIRTIO_NETDEV	\

	
