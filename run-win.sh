#!/bin/sh
WINIMG=en_windows_server_2016_updated_feb_2018_x64_dvd_11636692.iso
VIRTIMG=virtio-win.iso
DISK_IMG=win.img

QEMU=/srv/vm/qemu/x86_64-softmmu/qemu-system-x86_64
$QEMU --enable-kvm -drive driver=raw,file=$DISK_IMG,if=virtio -m 16G \
-cdrom ${WINIMG} \
-drive file=${VIRTIMG},index=3,media=cdrom \
-rtc base=localtime,clock=host -smp 6 \
-usb -device usb-tablet \
-cpu host  \
-monitor stdio \
-vnc 127.0.0.1:2 \
-netdev user,id=net0,hostfwd=tcp::2222-:22 \
-device virtio-net-pci,netdev=net0 \
-netdev tap,id=net1,vhost=on,helper=/srv/vm/qemu/qemu-bridge-helper \
-device virtio-net-pci,netdev=net1 \
