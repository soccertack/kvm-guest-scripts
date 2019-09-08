#!/bin/bash

ls -al qemu
read -p 'qemu: ' QEMU

rm -rf qemu
ln -s $QEMU qemu
