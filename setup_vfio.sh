#/bin/bash

modprobe vfio-pci
modprobe -v vfio_iommu_type1 allow_unsafe_interrupts=1
echo 0000:00:04.0 > /sys/bus/pci/devices/0000\:00\:04.0/driver/unbind
echo 1af4 1041 > /sys/bus/pci/drivers/vfio-pci/new_id
ls /dev/vfio/

