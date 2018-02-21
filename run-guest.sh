#!/bin/bash

source run-guest-common.sh

QEMU="./qemu-smmu-v8/aarch64-softmmu/qemu-system-aarch64"
if [[ "$ARCH" == "x86_64" ]]; then
	source qemu-command-x86.sh
else
	source qemu-command-arm.sh
fi
