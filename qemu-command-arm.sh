
VCONSOLE="-chardev socket,server,host=*,nowait,port=6666,telnet,id=mychardev0"
VCONSOLE="$VCONSOLE -device virtio-serial-device"
VCONSOLE="$VCONSOLE -device virtconsole,chardev=mychardev0"

$QEMU \
        -smp $SMP -m $MEMSIZE -machine $MACHINE -cpu host,$NESTED \
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
	$VFIO_DEV	\
	$VCONSOLE	\

	
