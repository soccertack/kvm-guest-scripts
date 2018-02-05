#!/bin/bash

source run-guest-common.sh

SMP=4
MEMSIZE=$((12 * 1024))
NESTED=""

source qemu-command.sh
