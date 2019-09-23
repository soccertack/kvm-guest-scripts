#!/bin/bash

ls -al qemu
ls -d qemu*
read -p 'qemu: ' QEMU

rm -rf qemu
ln -s $QEMU qemu
