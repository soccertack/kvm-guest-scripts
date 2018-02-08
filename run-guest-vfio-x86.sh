#!/bin/bash

source run-guest-common.sh

QEMU=/srv/vm/qemu/x86_64-softmmu/qemu-system-x86_64
FS=/vm/l2guest.img

SMP=4
MEMSIZE=$((12 * 1024))

MACHINE="q35,accel=kvm"

VFIO_DEV="-device vfio-pci,host=01:00.0,id=net2"

source qemu-command-x86.sh

