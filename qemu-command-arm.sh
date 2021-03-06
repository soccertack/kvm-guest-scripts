
VCONSOLE="-chardev socket,server,host=*,nowait,port=6666,telnet,id=mychardev0"
VCONSOLE="$VCONSOLE -device virtio-serial-device"
VCONSOLE="$VCONSOLE -device virtconsole,chardev=mychardev0"

echo "SMMU: "$SMMU

#CONSOLE="telnet:127.0.0.1:4444,server,nowait"
#MON="-monitor stdio"

if [[ -n $VIRTIO_NETDEV ]]; then
	./net.sh
fi

if [[ -n $QEMU_F ]]; then
    QEMU=./$QEMU_F/aarch64-softmmu/qemu-system-aarch64
fi

$QEMU \
        -smp $SMP -m ${MEMSIZE}G -machine $MACHINE -cpu host,$NESTED \
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
	$MON		\

	
