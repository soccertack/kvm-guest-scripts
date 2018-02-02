./qemu-system-aarch64 \
        -smp $SMP -m $MEMSIZE -machine virt${DUMPDTB} -cpu host,nested=true \
        -kernel ${KERNEL} -enable-kvm ${DTB} \
        -drive if=none,file=$FS,id=vda,cache=none,format=raw \
        -device virtio-blk-pci,drive=vda \
        -netdev user,id=net0,hostfwd=tcp::2222-:22 \
        -device virtio-net-pci,netdev=net0,mac=de:ad:be:ef:41:49 \
	$BRIDGE_IF \
        -display none \
	-serial $CONSOLE \
	-qmp unix:/var/run/qmp,server,nowait \
	-append "console=ttyAMA0 root=/dev/vda rw $CMDLINE" \
	$IOMMU	\
	$NETDEV	\
	
