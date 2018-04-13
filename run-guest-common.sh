#!/bin/bash

source common.sh

ARCH=`uname -m`
CONSOLE=mon:stdio
KERNEL=Image
INCOMING=""
# This is not effective on x86
CMDLINE="earlycon=pl011,0x09000000"
DUMPDTB=""
DTB=""
NESTED=""
SMMU="v8"

#Check if we are on a bare-metal machine
uname -n | grep -q cloudlab
err=$?

if [[ $err == 0 ]]; then
#L0 specific settings
	FS=/vmdata/linaro-trusty.img
	NESTED=",nested=true"
else
#L1 specific settings
	FS=l2.img
fi

HOST_CPU=`nproc`
SMP=`expr $HOST_CPU - 2`

# 12 (default) + 12G per each virt level
# e.g. L2 got 12G, and L1 got 24G and L0 got 36G
# memsize = 12 + (smp - 4) / 2 * 12
MEMSIZE=`expr $SMP \* 6 - 12`

if [[ "$ARCH" == "x86_64" ]]; then
	QEMU=./qemu/x86_64-softmmu/qemu-system-x86_64
	FS=/vm/guest0.img
	MACHINE="q35,accel=kvm"
else
	QEMU="./qemu-system-aarch64"
	# FS is already set
	MACHINE="virt${DUMPDTB}"
fi

usage() {
	U=""
	if [[ -n "$1" ]]; then
		U="${U}$1\n\n"
	fi
	U="${U}Usage: $0 [options]\n\n"
	U="${U}Options:\n"
	U="$U    -c | --CPU <nr>:       Number of cores (default ${SMP})\n"
	U="$U    -m | --mem <GB>:       Memory size (default ${MEMSIZE})\n"
	U="$U    -k | --kernel <Image>: Use kernel image (default ${KERNEL})\n"
	U="$U    -s | --serial <file>:  Output console to <file>\n"
	U="$U    -i | --image <image>:  Use <image> as block device (default $FS)\n"
	U="$U    -a | --append <snip>:  Add <snip> to the kernel cmdline\n"
	U="$U    -v | --smmu <version>:  Specify SMMUv3 patch version\n"
	U="$U    --dumpdtb <file>       Dump the generated DTB to <file>\n"
	U="$U    --dtb <file>           Use the supplied DTB instead of the auto-generated one\n"
	U="$U    -h | --help:           Show this output\n"
	U="${U}\n"
	echo -e "$U" >&2
}

while :
do
	case "$1" in
	  -c | --cpu)
		SMP="$2"
		shift 2
		;;
	  -m | --mem)
		MEMSIZE="$2"
		shift 2
		;;
	  -k | --kernel)
		KERNEL="$2"
		shift 2
		;;
	  -s | --serial)
		CONSOLE="file:$2"
		shift 2
		;;
	  -i | --image)
		FS="$2"
		shift 2
		;;
	  -a | --append)
		CMDLINE="$2"
		shift 2
		;;
	  -v | --smmu)
		SMMU="$2"
		shift 2
		;;
	  --dumpdtb)
		DUMPDTB=",dumpdtb=$2"
		shift 2
		;;
	  --dtb)
		DTB="-dtb $2"
		shift 2
		;;
	  -h | --help)
		usage ""
		exit 1
		;;
	  --) # End of all options
		shift
		break
		;;
	  -*) # Unknown option
		echo "Error: Unknown option: $1" >&2
		exit 1
		;;
	  *)
		break
		;;
	esac
done

USER_NETDEV="-netdev user,id=net0,hostfwd=tcp::2222-:22"
USER_NETDEV="$USER_NETDEV -device virtio-net-pci,netdev=net0"

echo "Using bridged networking"
VIRTIO_NETDEV="-netdev tap,id=net1,helper=/srv/vm/qemu/qemu-bridge-helper,vhost=on"
VIRTIO_NETDEV="$VIRTIO_NETDEV -device virtio-net-pci,netdev=net1"

# Let's make mac addresses unique across all virtualization levels
# We should be fine for 5 levels of virt :)
# This trick may break if we assign random number of cpus, though.
MAC_POSTFIX=`expr $SMP \% 10`

VIRTIO_NETDEV="$VIRTIO_NETDEV,mac=de:ad:be:ef:f6:c"$MAC_POSTFIX
USER_NETDEV="$USER_NETDEV,mac=de:ad:be:ef:41:5"$MAC_POSTFIX
