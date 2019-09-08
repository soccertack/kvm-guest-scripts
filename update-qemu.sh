#!/bin/bash

rm -rf qemu

read -p 'qemu: ' QEMU
ln -s $QEMU qemu
