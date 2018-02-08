#!/bin/bash

modprobe -v vfio-pci
modprobe -v vfio_iommu_type1
echo 0000:01:00.0 | tee /sys/bus/pci/devices/0000\:01\:00.0/driver/unbind
echo 1af4 1041 | sudo tee /sys/bus/pci/drivers/vfio-pci/new_id
ls /dev/vfio
