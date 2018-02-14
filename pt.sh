#!/bin/bash

BDF="0000:08:00.0"

qemu-system-x86_64 -m 2048 -net none -cpu host -enable-kvm  -drive if=none,file=/vm/guest0.img,id=vda,cache=none,format=raw -device virtio-blk-pci,drive=vda  -device vfio-pci,host=$BDF,id=net0 --nographic
