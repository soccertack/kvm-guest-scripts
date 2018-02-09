#!/bin/bash

source run-guest-common.sh

SMP=4
MEMSIZE=$((12 * 1024))
NESTED=""

if [[ "$ARCH" == "x86_64" ]]; then
	source qemu-command-x86.sh
else
	source qemu-command-arm.sh
fi
