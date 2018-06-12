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

#SMP=2
#MEMSIZE=24
echo "---------- QEMU setup -------------"
echo "SMP: "$SMP
echo "MEMSIZE: "${MEMSIZE}G
echo "MACHINE: "$MACHINE
echo "IOMMU: "$IOMMU
echo "VIRTIO-net: "$VIRTIO_NETDEV
echo "VFIO_DEV: "$VFIO_DEV
echo "VFIO_DEV2: "$VFIO_DEV2
echo "IOMMU_VIRTIO_NETDEV: " $IOMMU_VIRTIO_NETDEV
echo "IOMMU_VIRTIO_NETDEV2: " $IOMMU_VIRTIO_NETDEV2
echo "---------- QEMU setup end ---------"
sleep 3

#	-trace enable=vtd_err*,file=pi\
#	-trace enable=vtd_pi_setup_irq,file=pi\
#	-trace enable=vtd_ir_irte_get,file=pi\
#	-trace enable=vtd_irq_generate,file=pi\
#	-trace enable=vtd_ir_remap*,file=pi\
#	-trace enable=vtd_mem_ir_write,file=pi\
#	-trace enable=kvm_dbg,file=pi\
#	-trace enable=kvm_dbg*\
#	-trace enable=vtd_err_*\
#	-trace enable=vtd_ir_remap\
#
#	-trace enable=kvm_x86_add_msi_route\
#	-trace enable=kvm_irqchip_add_msi_route\
#	-trace enable=vtd_pi_setup_irq\
#	-trace enable=vtd_reg_ir_root\
#	-trace enable=kvm_dbg_int\
#	-trace enable=ioapic_dbg,file=$TRACE_OUT\
#	-trace enable=kvm_irqchip_update_msi_route,file=$TRACE_OUT\
#
TRACE_OUT=/sdc/pi3
sudo $QEMU	\
	$IOMMU		\
	-smp $SMP -m ${MEMSIZE}G -M $MACHINE -cpu host	\
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
	-monitor telnet::6666,server,nowait \
	-trace enable=vtd_ir_remap,file=$TRACE_OUT\
	-trace enable=vhost_dbg,file=$TRACE_OUT\
	-trace enable=kvm_i386_dbg,file=$TRACE_OUT\
	-trace enable=vtd_err,file=$TRACE_OUT\
	-trace enable=vtd_err_1,file=$TRACE_OUT\
	-trace enable=kvm_irqchip_commit_routes,file=$TRACE_OUT\
	-trace enable=x86_iommu_iec_notify,file=$TRACE_OUT\
	-trace enable=vtd_ir_irte_pi_get,file=$TRACE_OUT\
	-trace enable=vtd_ir_irte_get,file=$TRACE_OUT\
	-trace enable=kvm_irqchip_update_msi_route,file=$TRACE_OUT\
	-trace enable=kvm_irqchip_update_msi_route,file=$TRACE_OUT\
	-trace enable=kvm_x86_remove_msi_route,file=$TRACE_OUT\
	-trace enable=kvm_x86_add_msi_route,file=$TRACE_OUT\
	-trace enable=virtio_set_status,file=$TRACE_OUT\
	-trace enable=virtio_dbg,file=$TRACE_OUT\
	-trace enable=kvm_irqchip_add_msi_route,file=$TRACE_OUT\
	-trace enable=kvm_dbg_hex,file=$TRACE_OUT\
	-trace enable=kvm_dbg_int,file=$TRACE_OUT\

	
