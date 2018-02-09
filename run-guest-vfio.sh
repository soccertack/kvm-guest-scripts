#!/bin/bash

source run-guest-common.sh

VFIO_DEV="-device vfio-pci,host=00:04.0,id=net2"

source qemu-command-arm.sh
